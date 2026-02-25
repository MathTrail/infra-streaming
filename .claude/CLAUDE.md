# Identity & Context
You are working on mathtrail-infra-local — local development infrastructure for MathTrail.
This repo deploys PostgreSQL, Redis, and Kafka to the local k3d cluster for development.
All services with databases depend on this repo being deployed first.

Tech Stack: Helm, Just, Strimzi Operator (Kafka)
Namespace: mathtrail

# Communication Map
No Dapr communication — provides data stores.
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
- Kafka uses Strimzi operator with KRaft mode (no ZooKeeper)

# Commit Convention
Use Conventional Commits: feat(infra-local):, fix(infra-local):, chore(infra-local):
Example: feat(infra-local): add kafka cluster via strimzi

# Testing Strategy
Deploy: `just deploy`
Verify: `kubectl get pods -n mathtrail`
Test connectivity: `kubectl exec` into pods and verify connections
Priority: Manual deployment verification
