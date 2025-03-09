#!/bin/sh

# Set up a cache directory for Trivy scans
TRIVY_CACHE=~/.trivy_cache

# Define a function to run Trivy in Docker, ensuring the cache exists.
trivy() {
    mkdir -p "$TRIVY_CACHE"
    docker run --rm -it \
        -v "$TRIVY_CACHE":/root/.cache \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD":"$PWD" \
        -w "$PWD" aquasec/trivy "$@"
}

# Define helper functions for common Trivy commands.
trivy_image() {
    trivy image "$@"
}

trivy_image_dependency() {
    trivy image -f table --dependency-tree "$@"
}

trivy_config() {
    trivy config "$@"
}
