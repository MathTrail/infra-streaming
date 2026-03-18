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

# Remove all streaming ArgoCD Applications and workload resources
delete:
    #!/usr/bin/env bash
    set -euo pipefail
    for app in mathtrail-kafka mathtrail-apicurio mathtrail-seaweedfs \
               mathtrail-debezium mathtrail-flink mathtrail-redpanda-console; do
        kubectl patch application "$app" -n argocd \
            --type=merge -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
    done
    for app in kafka apicurio seaweedfs debezium flink redpanda-console; do
        helm uninstall mathtrail-$app --namespace argocd --ignore-not-found 2>/dev/null || true
    done
    just _nuke-namespace streaming

# Generic: force-delete a namespace by first triggering deletion (which terminates
# in-namespace operators), then stripping remaining resource finalizers once operators
# are gone and can no longer re-add them, then force-finalizing the namespace spec.
_nuke-namespace ns:
    #!/usr/bin/env bash
    set -euo pipefail
    # Start namespace deletion without waiting — this sends SIGTERM to all pods,
    # including operators that would otherwise re-add finalizers to their CRs
    kubectl delete namespace {{ ns }} --ignore-not-found --wait=false
    # Wait until all pods are terminated (operators are gone, can't re-add finalizers)
    kubectl wait pod --all -n {{ ns }} --for=delete --timeout=60s 2>/dev/null || true
    # Strip finalizers from all remaining resources — now safe, no operators running
    kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null \
        | xargs -I{} kubectl get {} -n {{ ns }} --no-headers -o name 2>/dev/null \
        | xargs -r -I{} kubectl patch {} -n {{ ns }} \
            --type=merge -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
    # Force-finalize the namespace spec to unblock kubernetes finalizer
    if kubectl get namespace {{ ns }} -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Terminating; then
        kubectl get namespace {{ ns }} -o json \
            | python3 -c "import sys,json; d=json.load(sys.stdin); d['spec']['finalizers']=[]; print(json.dumps(d))" \
            | kubectl replace --raw /api/v1/namespaces/{{ ns }}/finalize -f -
    fi
