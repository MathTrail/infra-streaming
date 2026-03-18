# MathTrail Streaming Infrastructure
# Deployment is managed exclusively by ArgoCD via `just deploy`.

set shell := ["bash", "-c"]

# Add required Helm repositories (needed for local `helm dep update`)
setup:
    helm repo add mathtrail https://MathTrail.github.io/charts/charts
    helm repo update

# Update Chart.lock for all Helm charts (run after adding/changing charts)
dep-update:
    helm dependency update infra/local/helm/kafka
    helm dependency update infra/local/helm/apicurio
    helm dependency update infra/local/helm/seaweedfs
    helm dependency update infra/local/helm/debezium
    helm dependency update infra/local/helm/flink
    helm dependency update infra/local/helm/redpanda-console

# Deploy all streaming components via ArgoCD in wave order
deploy: setup
    #!/usr/bin/env bash
    set -euo pipefail
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    for app in kafka apicurio seaweedfs debezium flink redpanda-console; do
        helm upgrade --install mathtrail-$app infra/apps/$app \
            --namespace argocd --create-namespace \
            --set gitBranch="$BRANCH"
    done

# Remove all streaming ArgoCD Applications (cascade-deletes K8s resources)
delete:
    #!/usr/bin/env bash
    set -euo pipefail
    for app in kafka apicurio seaweedfs debezium flink redpanda-console; do
        helm uninstall mathtrail-$app --namespace argocd --ignore-not-found 2>/dev/null || true
    done

# Show status of all streaming apps
status:
    kubectl -n argocd get applications \
      -l 'app.kubernetes.io/managed-by=Helm' \
      -o custom-columns='NAME:.metadata.name,WAVE:.metadata.annotations.argocd\.argoproj\.io/sync-wave,SYNC:.status.sync.status,HEALTH:.status.health.status' \
      --sort-by='.metadata.annotations.argocd\.argoproj\.io/sync-wave' 2>/dev/null \
      | grep mathtrail- || echo "No streaming apps found."
