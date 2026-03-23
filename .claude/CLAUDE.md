# Identity & Context
You are working on mathtrail-infra-local — local development infrastructure for MathTrail.
This repo deploys PostgreSQL, Redis, and Kafka to the local k3d cluster for development.
All services with databases depend on this repo being deployed first.

Tech Stack: Helm, Just, AutoMQ (Kafka-compatible)
Namespace: streaming

# Communication Map
Provides data stores only.
Services that depend on this: mathtrail-profile (PostgreSQL, Redis), mathtrail-identity (PostgreSQL for Ory), mathtrail-task (PostgreSQL).
Default credentials: mathtrail/mathtrail (PostgreSQL), mathtrail (Redis).

# Vault Integration
Database credential management (dynamic roles, connections) is handled by the Bank-Vaults Vault CR
in mathtrail-infra (not in this repo). This repo only provides the data stores themselves.
The postgresql-values.yaml includes ALTER DEFAULT PRIVILEGES for Vault dynamic users
on the mentor, profile, and mathtrail databases.

# Development Standards
- Keep resource requests minimal (local dev — nano resources)
- All Helm values in values/ directory
- Document default credentials in README (acceptable for local dev only)
- AutoMQ provides Kafka-compatible API (SASL_PLAINTEXT, SCRAM-SHA-512)

# Commit Convention
Use Conventional Commits: feat(infra-local):, fix(infra-local):, chore(infra-local):
Example: feat(infra-streaming): add automq cluster

# Testing Strategy
Deploy: `just deploy`
Verify: `kubectl get pods -n streaming`
Test connectivity: `kubectl exec` into pods and verify connections
Priority: Manual deployment verification
