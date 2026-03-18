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
    argocd app sync mathtrail-kafka --wait
    argocd app sync mathtrail-apicurio mathtrail-seaweedfs --wait
    argocd app sync mathtrail-debezium --wait
    argocd app sync mathtrail-flink --wait
    argocd app sync mathtrail-redpanda-console --wait

# Remove all streaming ArgoCD Applications (cascade-deletes K8s resources)
delete:
    #!/usr/bin/env bash
    set -euo pipefail
    for app in kafka apicurio seaweedfs debezium flink redpanda-console; do
        helm uninstall mathtrail-$app --namespace argocd --ignore-not-found 2>/dev/null || true
    done

# Sync a single app (usage: just sync mathtrail-kafka)
sync app="mathtrail-kafka":
    argocd app sync {{ app }}

# Show status of all streaming apps
status:
    @for app in mathtrail-kafka mathtrail-apicurio mathtrail-seaweedfs \
                mathtrail-debezium mathtrail-flink mathtrail-redpanda-console; do \
        echo "=== $$app ==="; \
        argocd app get $$app 2>/dev/null || echo "not found"; \
    done
