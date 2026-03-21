# Stage 1: Build the SQL Runner fat JAR
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build
COPY pom.xml .
# Pre-fetch dependencies (Docker layer cache)
RUN mvn dependency:go-offline -q
COPY src/ src/
RUN mvn package -DskipTests -q

# Stage 2: Flink image with SQL connectors + SQL Runner JAR
FROM apache/flink:1.20-scala_2.12-java17

# Kafka SQL connector (includes Kafka client — not in base image)
RUN wget -q "https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.4.0-1.20/flink-sql-connector-kafka-3.4.0-1.20.jar" \
    -O /opt/flink/lib/flink-sql-connector-kafka-3.4.0-1.20.jar

# Avro Confluent Registry format connector (not in base image)
RUN wget -q "https://repo1.maven.org/maven2/org/apache/flink/flink-avro-confluent-registry/1.20.1/flink-avro-confluent-registry-1.20.1.jar" \
    -O /opt/flink/lib/flink-avro-confluent-registry-1.20.1.jar

# SQL Runner JAR — the only custom code
COPY --from=builder /build/target/flink-sql-runner-1.0.0.jar /opt/flink/usrlib/flink-sql-runner.jar
