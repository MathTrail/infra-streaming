# MathTrail Streaming Infrastructure
# Deployment is managed exclusively by ArgoCD (mathtrail-kafka Application).

set shell := ["bash", "-c"]

# Add required Helm repositories (needed for local `helm dep update`)
setup:
    helm repo add mathtrail https://MathTrail.github.io/charts/charts
    helm repo update

# Trigger ArgoCD sync
sync:
    argocd app sync mathtrail-kafka

# Show ArgoCD application status
status:
    argocd app get mathtrail-kafka

# Update Helm chart dependencies (for local development / chart authoring)
dep-update:
    helm dependency update infra/local/helm/kafka
