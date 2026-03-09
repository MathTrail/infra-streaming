# MathTrail Local Infrastructure

set shell := ["bash", "-c"]

# Add required Helm repositories
setup:
    helm repo add mathtrail https://MathTrail.github.io/charts/charts
    helm repo update

# Deploy all infrastructure components to the cluster
deploy: setup
    helm dependency update charts/kafka
    skaffold deploy

# Delete all deployed infrastructure components and persistent volumes from the cluster
delete:
    skaffold delete
    kubectl delete pvc --all -n mathtrail --ignore-not-found
