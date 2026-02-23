#!/bin/bash
# Build .deb packages for all 5 schemes on Ubuntu 22.04 and 24.04
#
# Usage: ./build-all.sh [APP_VERSION]
#   APP_VERSION defaults to 1.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/build/deb"
APP_VERSION="${1:-1.0.0}"
SCHEMES_CONF="${SCRIPT_DIR}/schemes.conf"

mkdir -p "$OUTPUT_DIR"

echo "=== Building .deb packages for all schemes ==="
echo "Project: $PROJECT_DIR"
echo "Version: $APP_VERSION"
echo "Output:  $OUTPUT_DIR"
echo ""

# Read schemes.conf, skip comments and empty lines
while IFS=$'\t ' read -r SUBMODULE ID NAME LABEL LANG_CODE ICON_TOO rest; do
    # Skip comments and empty lines
    [[ -z "$SUBMODULE" || "$SUBMODULE" == \#* ]] && continue

    # Convert underscores to spaces in SCHEME_NAME
    NAME="${NAME//_/ }"

    echo "--- Building: $NAME ($ID) ---"

    for UBUNTU_VER in 22.04 24.04; do
        echo "  Ubuntu $UBUNTU_VER..."

        DOCKERFILE="${SCRIPT_DIR}/Dockerfile-${UBUNTU_VER}"
        TAG="fcitx5-${ID}-ubuntu${UBUNTU_VER}"
        DEB_FILE="fcitx5-${ID}_${APP_VERSION}_ubuntu${UBUNTU_VER}.deb"

        docker build \
            -f "$DOCKERFILE" \
            --build-arg "SCHEME_SUBMODULE=$SUBMODULE" \
            --build-arg "SCHEME_ID=$ID" \
            --build-arg "SCHEME_NAME=$NAME" \
            --build-arg "SCHEME_LABEL=$LABEL" \
            --build-arg "SCHEME_LANG_CODE=$LANG_CODE" \
            --build-arg "SCHEME_ICON_TOO=$ICON_TOO" \
            --build-arg "APP_VERSION=$APP_VERSION" \
            -t "$TAG" \
            "$PROJECT_DIR"

        # Extract .deb from container
        CONTAINER_ID=$(docker create "$TAG")
        docker cp "$CONTAINER_ID:/output/." "$OUTPUT_DIR/"
        docker rm "$CONTAINER_ID" > /dev/null

        echo "  Done: $OUTPUT_DIR/$DEB_FILE"
    done
    echo ""
done < "$SCHEMES_CONF"

echo "=== All packages built ==="
echo "Output directory: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR/"*.deb 2>/dev/null || echo "No .deb files found"
