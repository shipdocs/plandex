#!/bin/bash

# Build script for Plandex CLI release
# Creates cross-platform binaries and packages them for release

set -e

VERSION="2.2.9"
BUILD_DIR="build"
RELEASE_DIR="release"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BUILD] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Clean up previous builds
log "Cleaning up previous builds..."
rm -rf "$BUILD_DIR" "$RELEASE_DIR"
mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

# Platforms and architectures to build for
declare -a platforms=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
)

log "Building Plandex CLI v${VERSION} for multiple platforms..."

cd app/cli

for platform in "${platforms[@]}"; do
    IFS='/' read -r os arch <<< "$platform"
    
    info "Building for ${os}/${arch}..."
    
    # Set output filename
    output_name="plandex"
    
    # Build binary
    GOOS="$os" GOARCH="$arch" go build -ldflags="-s -w" -o "../../${BUILD_DIR}/${output_name}" .
    
    # Create tarball name
    tarball_name="plandex_${VERSION}_${os}_${arch}.tar.gz"
    
    # Create tarball
    cd "../../${BUILD_DIR}"
    tar -czf "../${RELEASE_DIR}/${tarball_name}" "$output_name"
    rm "$output_name"
    cd "../app/cli"
    
    log "Created ${tarball_name}"
done

cd ../..

log "Build complete! Release assets created in ${RELEASE_DIR}/"
ls -la "$RELEASE_DIR"

log "Release assets ready for upload to GitHub release cli/v${VERSION}"
