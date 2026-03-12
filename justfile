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
    helm dependency update infra/local/helm/minio
    helm dependency update infra/local/helm/debezium
    helm dependency update infra/local/helm/flink
    helm dependency update infra/local/helm/redpanda-console

# Deploy all streaming components via ArgoCD in wave order
deploy:
    kubectl apply -f argocd/
    argocd app sync mathtrail-kafka --wait
    argocd app sync mathtrail-apicurio mathtrail-minio --wait
    argocd app sync mathtrail-debezium --wait
    argocd app sync mathtrail-flink --wait
    argocd app sync mathtrail-redpanda-console --wait

# Remove all streaming ArgoCD Applications (cascade-deletes K8s resources)
delete:
    argocd app delete mathtrail-redpanda-console mathtrail-flink mathtrail-debezium \
        mathtrail-apicurio mathtrail-minio mathtrail-kafka --cascade --yes

# Sync a single app (usage: just sync mathtrail-kafka)
sync app="mathtrail-kafka":
    argocd app sync {{ app }}

# Show status of all streaming apps
status:
    @for app in mathtrail-kafka mathtrail-apicurio mathtrail-minio \
                mathtrail-debezium mathtrail-flink mathtrail-redpanda-console; do \
        echo "=== $$app ==="; \
        argocd app get $$app 2>/dev/null || echo "not found"; \
    done
