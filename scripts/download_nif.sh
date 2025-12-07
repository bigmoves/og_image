#!/bin/bash
set -e

# Configuration
# TODO: Update this to your GitHub repository path
REPO="YOUR_GITHUB_USER/og_image"
VERSION="${OG_IMAGE_VERSION:-latest}"
PRIV_DIR="${1:-priv}"

# Detect platform
detect_platform() {
  local os arch

  case "$(uname -s)" in
    Darwin) os="macos" ;;
    Linux)  os="linux" ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
  esac

  case "$(uname -m)" in
    arm64|aarch64) arch="arm64" ;;
    x86_64|amd64)  arch="x86_64" ;;
    *)             echo "Unsupported arch: $(uname -m)"; exit 1 ;;
  esac

  echo "${os}-${arch}"
}

# Get download URL
get_download_url() {
  local platform="$1"
  local binary="og_image_nif-${platform}.so"

  if [ "$VERSION" = "latest" ]; then
    echo "https://github.com/${REPO}/releases/latest/download/${binary}"
  else
    echo "https://github.com/${REPO}/releases/download/${VERSION}/${binary}"
  fi
}

# Main
main() {
  local platform=$(detect_platform)
  local url=$(get_download_url "$platform")
  local checksum_url="${url}.sha256"
  local output="${PRIV_DIR}/og_image_nif.so"

  echo "Detected platform: ${platform}"
  echo "Downloading from: ${url}"

  mkdir -p "$PRIV_DIR"

  # Download binary
  if command -v curl &> /dev/null; then
    curl -fsSL "$url" -o "$output"
    curl -fsSL "$checksum_url" -o "${output}.sha256"
  elif command -v wget &> /dev/null; then
    wget -q "$url" -O "$output"
    wget -q "$checksum_url" -O "${output}.sha256"
  else
    echo "Error: curl or wget required"
    exit 1
  fi

  # Verify checksum
  echo "Verifying checksum..."
  cd "$PRIV_DIR"
  if command -v shasum &> /dev/null; then
    shasum -a 256 -c og_image_nif.so.sha256
  elif command -v sha256sum &> /dev/null; then
    sha256sum -c og_image_nif.so.sha256
  else
    echo "Warning: Cannot verify checksum (shasum/sha256sum not found)"
  fi

  echo "Successfully installed NIF to ${output}"
}

main "$@"
