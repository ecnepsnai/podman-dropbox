#!/bin/bash
set -e

REVISION=$(git rev-parse HEAD)
VERSION=$(git describe)
DATETIME=$(date --rfc-3339=seconds)
podman build -t ghcr.io/ecnepsnai/dropbox:latest -t ghcr.io/ecnepsnai/dropbox:${VERSION} --squash --label "org.opencontainers.image.created=${DATETIME}" --label "org.opencontainers.image.version=${VERSION}" --label "org.opencontainers.image.revision=${REVISION}" .
