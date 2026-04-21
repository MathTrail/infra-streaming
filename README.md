# MathTrail Streaming Infrastructure

Streaming and event-driven infrastructure for the MathTrail platform. Provides the event bus, schema registry, stream processing, real-time messaging, and supporting observability tooling.

## Architecture

```mermaid
graph LR
    PG[("PostgreSQL<br/>mathtrail ns")]
    CanvasAPI(["Canvas API"])
    MentorAPI(["Mentor API"])
    Browser(["Browser"])

    subgraph StreamingStack ["Streaming Platform (ns: streaming)"]
        direction TB

        subgraph EventBus ["Event Bus"]
            direction LR
            AMQ{AutoMQ<br/>:9092}
            Apr["Apicurio Registry<br/>:8080"]
        end

        subgraph ObjectStorage ["Object Storage"]
            Minio[("MinIO<br/>API :9000 · Console :9001")]
        end

        subgraph StreamProc ["Stream Processing"]
            RW["RisingWave<br/>:4566"]
        end

        subgraph Realtime ["Real-time"]
            Centrifugo["Centrifugo<br/>:8000"]
        end

        subgraph ObsDocs ["Observability & Docs"]
            direction LR
            KUI["Kafka UI"]
            EC["EventCatalog"]
        end
    end

    subgraph SecretsMgmt ["Secrets & Bootstrap"]
        direction TB
        LSec["local-secrets<br/>Vault seed"]
        Vault["Vault"]
        VSO["Vault Secrets<br/>Operator"]
        LSec -- "seed" --> Vault
        Vault --> VSO
    end

    subgraph IdentityLayer ["Identity (ns: identity)"]
        direction LR
        Traefik["Traefik"] --> OK["Oathkeeper"]
        Hydra["Hydra<br/>:4444"]
    end

    Apr -- "KafkaSql storage" --> AMQ
    AMQ -- "S3 tiered storage" --> Minio
    RW -- "S3 state backend" --> Minio
    Minio -. "OIDC SSO" .-> Hydra
    VSO -- "credentials" --> Minio
    VSO -- "credentials" --> AMQ
    VSO -- "credentials" --> RW
    VSO -- "credentials" --> Centrifugo
    PG -- "CDC source" --> RW
    RW -- "CDC events" --> AMQ
    MentorAPI -- "produce / consume" --> AMQ
    MentorAPI -. "schema" .-> Apr
    CanvasAPI -- "publish hint" --> Centrifugo
    Centrifugo -- "WebSocket" --> Browser
    KUI -- "monitor" --> AMQ
    KUI -. "schema" .-> Apr
    Browser -- "observability UIs" --> Traefik
    OK -- "authz (Keto)" --> KUI
    OK -- "authz (Keto)" --> Apr
    OK -- "authz (Keto)" --> EC

    classDef svc fill:#5b21b6,stroke:#7c3aed,color:#fff
    classDef storageCls fill:#1e3a5f,stroke:#3b82f6,color:#fff
    classDef cdcCls fill:#166534,stroke:#22c55e,color:#fff
    classDef eventCls fill:#1c1917,stroke:#78716c,color:#fff
    classDef secretCls fill:#7f1d1d,stroke:#ef4444,color:#fff
    classDef obsCls fill:#134e4a,stroke:#2dd4bf,color:#fff
    classDef actorCls fill:#1e1b4b,stroke:#818cf8,color:#fff
    classDef authCls fill:#b45309,stroke:#f59e0b,color:#fff
    classDef bootstrapCls fill:#4a1d96,stroke:#8b5cf6,color:#fff

    class AMQ,Apr eventCls
    class Minio,PG storageCls
    class RW cdcCls
    class KUI,EC obsCls
    class Centrifugo svc
    class LSec bootstrapCls
    class Vault,VSO secretCls
    class Traefik,OK,Hydra authCls
    class CanvasAPI,MentorAPI,Browser actorCls
```

## Prerequisites

- A running K3d cluster (managed by [infra-local-k3s](https://github.com/MathTrail/infra-local-k3s))

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

## Streaming Services

Streaming infrastructure deployed to the `streaming` namespace via ArgoCD.

| Service | K8s Service | Namespace | Port |
|---------|-------------|-----------|------|
| AutoMQ (Kafka-compatible) | `streaming-automq-kafka` | `streaming` | 9092 |
| Apicurio Schema Registry | `streaming-apicurio-apicurio-registry` | `streaming` | 8080 |
| Kafka UI | `streaming-kafka-ui` | `streaming` | 8080 |
| EventCatalog | `streaming-eventcatalog-eventcatalog-local` | `streaming` | 8080 |
| MinIO API | `streaming-minio` | `streaming` | 9000 |
| MinIO Console | `streaming-minio-console` | `streaming` | 9001 |
| RisingWave | `risingwave-frontend` | `streaming` | 4566 |
| Centrifugo | `streaming-centrifugo` | `streaming` | 8000 |

> [!WARNING]
> **RisingWave nightly override active.** `infra/local/helm/risingwave/values.yaml` pins
> `image.tag: nightly-20260410` to enable PostgreSQL 18 CDC support
> (fix merged 2026-02-11, [risingwavelabs/risingwave#24765](https://github.com/risingwavelabs/risingwave/pull/24765),
> not yet in a stable release).
> **Remove the `image.tag` override once RisingWave v2.9.0+ with PG18 CDC is released.**

## Accessing UIs

All web UIs are exposed through the identity gateway at `https://mathtrail.localhost`.
Authentication (cookie session) and authorization (`Monitoring:ui#viewer` Keto relation) are enforced by Oathkeeper.

| UI | URL | Notes |
|----|-----|-------|
| Kafka UI | https://mathtrail.localhost/observability/kafka-ui/ | AutoMQ cluster + Apicurio schema registry |
| Apicurio Registry | https://mathtrail.localhost/observability/apicurio/ | Schema management (Avro, Protobuf, JSON Schema) |
| EventCatalog | https://mathtrail.localhost/observability/eventcatalog/ | EDA event/service documentation |
| MinIO Console | https://minio.mathtrail.localhost/ (redirects from /observability/minio) | S3 bucket management (automq-data, risingwave-data) |

> To grant access, add a Keto relation tuple: `Monitoring:ui#viewer@<user-id>`

### Default credentials (local dev only)

| Service | Username | Password | Secret |
|---------|----------|----------|--------|
| MinIO Console | `minioadmin` | `minioadmin` | `streaming/minio-root-creds` (Vault KV) |
