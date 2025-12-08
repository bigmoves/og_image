#!/bin/bash
set -e

# Configuration
REPO="bigmoves/og_image"
VERSION="${1:-latest}"

echo "Preparing og_image for hex publishing..."

# Get the release tag
if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/nif-bundle.tar.gz"
else
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/nif-bundle.tar.gz"
fi

echo "Downloading nif-bundle from: ${DOWNLOAD_URL}"

# Download the bundle
if command -v curl &> /dev/null; then
  curl -fsSL "$DOWNLOAD_URL" -o nif-bundle.tar.gz
elif command -v wget &> /dev/null; then
  wget -q "$DOWNLOAD_URL" -O nif-bundle.tar.gz
else
  echo "Error: curl or wget required"
  exit 1
fi

# Extract the bundle to a temp directory, then copy binaries to priv/
echo "Extracting nif-bundle.tar.gz..."
TEMP_DIR=$(mktemp -d)
tar -xzf nif-bundle.tar.gz -C "$TEMP_DIR"

# Copy binaries to priv/ (preserving existing files like fonts/)
mkdir -p priv
cp "$TEMP_DIR"/priv/og_image_nif-*.so priv/

# Cleanup temp directory
rm -rf "$TEMP_DIR"

# Cleanup
rm nif-bundle.tar.gz

# List what was extracted
echo ""
echo "Extracted binaries:"
ls -la priv/

echo ""
echo "Ready to publish! Run: gleam publish"
