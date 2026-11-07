#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -z "${DOCKERHUB_USER:-}" ]; then
    echo "Error: DOCKERHUB_USER is not set." >&2
    echo "Set it to your Docker Hub username, e.g. DOCKERHUB_USER=myuser $0" >&2
    exit 1
fi

buildpush() {
    local context="$1"
    local tag="$2"

    echo
    echo "=== Building $context ==="
    docker image build -t "$tag" "$context"
    docker image push "$tag"
}

error() {
    echo
    echo "Build/push failed." >&2
    exit 1
}

trap error ERR

buildpush "images/systems/debian-base" "${DOCKERHUB_USER}/debian-slim-baseimage:trixie-latest"
buildpush "images/systems/fedora-base" "${DOCKERHUB_USER}/fedora-baseimage:latest"
buildpush "images/systems/wine-base" "${DOCKERHUB_USER}/wine-baseimage:latest"
buildpush "images/games/asa-docker" "${DOCKERHUB_USER}/asa-wine:latest"

echo
echo "All images built and pushed."
