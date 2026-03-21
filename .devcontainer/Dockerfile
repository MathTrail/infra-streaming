FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
COPY --from=ghcr.io/mathtrail/platform-env:1 /config/global.env /etc/mathtrail/platform.env

# Install buildah with fuse-overlayfs for container image builds
RUN apt-get update \
    && apt-get install -y --no-install-recommends buildah fuse-overlayfs \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/containers \
    && printf '[storage]\ndriver = "overlay"\n\n' \
       '[storage.options.overlay]\nmount_program = "/usr/bin/fuse-overlayfs"\n' \
       > /etc/containers/storage.conf

ARG K3D_REGISTRY=k3d-mathtrail-registry.localhost:5050
RUN mkdir -p /etc/containers/registries.conf.d && \
    printf '[[registry]]\nlocation = "%s"\ninsecure = true\n' "${K3D_REGISTRY}" \
    > /etc/containers/registries.conf.d/k3d.conf && \
    printf 'unqualified-search-registries = ["docker.io"]\n' \
    > /etc/containers/registries.conf
