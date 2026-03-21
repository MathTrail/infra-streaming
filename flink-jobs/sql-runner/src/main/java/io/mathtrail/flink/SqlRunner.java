package io.mathtrail.flink;

import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.StatementSet;
import org.apache.flink.table.api.TableEnvironment;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Generic Flink SQL Runner.
 *
 * Usage: SqlRunner <sql-file>
 *
 * Reads a SQL file, substitutes ${ENV_VAR} placeholders with environment
 * variable values, then executes DDL statements sequentially and groups
 * all INSERT INTO statements into a single StatementSet (one streaming job,
 * shared DAG and TaskSlots).
 */
public class SqlRunner {

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            throw new IllegalArgumentException("Usage: SqlRunner <sql-file>");
        }

        String sqlFile = args[0];
        String sql = new String(Files.readAllBytes(Paths.get(sqlFile)));

        // Substitute ${VAR} placeholders with environment variable values.
        // Env var names are case-sensitive (match the placeholder exactly).
        for (Map.Entry<String, String> entry : System.getenv().entrySet()) {
            sql = sql.replace("${" + entry.getKey() + "}", entry.getValue());
        }

        TableEnvironment tEnv = TableEnvironment.create(
                EnvironmentSettings.newInstance().inStreamingMode().build());

        List<String> insertStatements = new ArrayList<>();

        for (String stmt : splitStatements(sql)) {
            // Strip leading comment lines to get the "effective" start of the statement.
            String effective = Arrays.stream(stmt.split("\n"))
                    .filter(line -> !line.trim().startsWith("--"))
                    .collect(Collectors.joining("\n"))
                    .trim();

            if (effective.isEmpty()) {
                continue;
            }

            if (effective.toUpperCase().startsWith("INSERT")) {
                insertStatements.add(stmt.trim());
            } else {
                tEnv.executeSql(stmt.trim());
            }
        }

        // All INSERT INTO statements are combined into one StatementSet so Flink
        // compiles them into a single streaming job with a shared execution DAG.
        if (!insertStatements.isEmpty()) {
            StatementSet stmtSet = tEnv.createStatementSet();
            for (String insert : insertStatements) {
                stmtSet.addInsertSql(insert);
            }
            stmtSet.execute();
        }
    }

    private static List<String> splitStatements(String sql) {
        return Arrays.asList(sql.split(";"));
    }
}
