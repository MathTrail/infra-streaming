# MathTrail Infrastructure Local

Local development infrastructure for the MathTrail platform.

## Prerequisites

- A running K3d cluster (managed by [mathtrail-infra-local-k3s](../mathtrail-infra-local-k3s))

## Quick Start

Open this repo in the devcontainer, then:

```bash
just deploy
```

This will:

1. Add the `mathtrail` Helm repo
2. Create the `mathtrail` namespace
3. Install services with local development values

To remove everything:

```bash
just delete
```

## Services

| Service          | Deployed via                  | Namespace          | Access                                       |
|------------------|-------------------------------|--------------------|----------------------------------------------|
| PostgreSQL       | Helm (`postgresql`)           | `mathtrail`        | `postgres-postgresql.mathtrail.svc:5432`     |
| PgBouncer        | Raw manifests (kubectl)       | `mathtrail`        | `pgbouncer.mathtrail.svc:5432`               |
| Redis            | Helm (`redis`)                | `mathtrail`        | `redis-master.mathtrail.svc:6379`            |
| Vault            | Helm (`vault`)                | `vault`            | `vault.vault.svc:8200`                       |
| External Secrets | Helm (`external-secrets`)     | `external-secrets` | Cluster-wide operator                        |
| Telepresence     | Helm (`telepresence-oss`)     | `ambassador`       | Traffic Manager for local dev                |

## Default Credentials

| Service    | Username    | Password    | Database    |
|------------|-------------|-------------|-------------|
| PostgreSQL | `mathtrail` | `mathtrail` | `mathtrail` |
| Redis      | —           | `mathtrail` | —           |

## Configuration

### Helm values — [`values/`](values/)

- [`postgresql-values.yaml`](values/postgresql-values.yaml) — standalone, 1Gi storage, nano resources
- [`redis-values.yaml`](values/redis-values.yaml) — standalone, 1Gi storage, nano resources
- [`vault-values.yaml`](values/vault-values.yaml) — Vault server config
- [`external-secrets-values.yaml`](values/external-secrets-values.yaml) — External Secrets operator config
- [`telepresence-values.yaml`](values/telepresence-values.yaml) — Telepresence traffic manager config

### Raw manifests — [`manifests/`](manifests/)

- [`pgbouncer.yaml`](manifests/pgbouncer.yaml) — PgBouncer connection pooler
- [`pgbouncer-dashboard.yaml`](manifests/pgbouncer-dashboard.yaml) — PgBouncer dashboard
- [`vault-init-job.yaml`](manifests/vault-init-job.yaml) — Job that configures Vault (Database Secrets Engine, K8s auth)
- [`cluster-secret-store.yaml`](manifests/cluster-secret-store.yaml) — ClusterSecretStore for External Secrets
