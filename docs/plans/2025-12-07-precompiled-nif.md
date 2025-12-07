# Precompiled NIF Distribution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable users to use og_image without requiring Rust toolchain by providing precompiled NIFs for all major platforms.

**Architecture:** GitHub Actions builds NIFs for 4 platform/arch combinations on release tags, uploads as release assets with checksums. A download script detects the user's platform and fetches the correct binary. Fallback to source compilation if binary unavailable.

**Tech Stack:** GitHub Actions, Rust cross-compilation, shell scripting, Make

---

## Task 1: Create Release Workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Create the release workflow file**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  build-nif:
    name: Build NIF (${{ matrix.os }}-${{ matrix.arch }})
    runs-on: ${{ matrix.runner }}
    strategy:
      matrix:
        include:
          - os: macos
            arch: arm64
            runner: macos-14
            target: aarch64-apple-darwin
            lib_name: libog_image_nif.dylib
          - os: macos
            arch: x86_64
            runner: macos-13
            target: x86_64-apple-darwin
            lib_name: libog_image_nif.dylib
          - os: linux
            arch: x86_64
            runner: ubuntu-latest
            target: x86_64-unknown-linux-gnu
            lib_name: libog_image_nif.so
          - os: linux
            arch: arm64
            runner: ubuntu-24.04-arm
            target: aarch64-unknown-linux-gnu
            lib_name: libog_image_nif.so

    steps:
      - uses: actions/checkout@v4

      - name: Install Rust
        uses: dtolnay/rust-action@stable
        with:
          targets: ${{ matrix.target }}

      - name: Install Erlang (for NIF headers)
        uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          gleam-version: "1.6"

      - name: Build NIF
        working-directory: native/og_image_nif
        run: cargo build --release --target ${{ matrix.target }}

      - name: Rename binary
        run: |
          cp native/og_image_nif/target/${{ matrix.target }}/release/${{ matrix.lib_name }} \
             og_image_nif-${{ matrix.os }}-${{ matrix.arch }}.so

      - name: Generate checksum
        run: shasum -a 256 og_image_nif-${{ matrix.os }}-${{ matrix.arch }}.so > og_image_nif-${{ matrix.os }}-${{ matrix.arch }}.so.sha256

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: nif-${{ matrix.os }}-${{ matrix.arch }}
          path: |
            og_image_nif-${{ matrix.os }}-${{ matrix.arch }}.so
            og_image_nif-${{ matrix.os }}-${{ matrix.arch }}.so.sha256

  release:
    name: Create Release
    needs: build-nif
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: artifacts
          merge-multiple: true

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: artifacts/*
          generate_release_notes: true
```

**Step 2: Verify workflow syntax**

Run: `cd /Users/chadmiller/code/og_image && cat .github/workflows/release.yml | head -20`
Expected: YAML content displays correctly

**Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add release workflow for precompiled NIFs"
```

---

## Task 2: Create Download Script

**Files:**
- Create: `scripts/download_nif.sh`

**Step 1: Create the download script**

```bash
#!/bin/bash
set -e

# Configuration
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
```

**Step 2: Make script executable**

Run: `chmod +x scripts/download_nif.sh`
Expected: No output, script is now executable

**Step 3: Commit**

```bash
git add scripts/download_nif.sh
git commit -m "feat: add NIF download script"
```

---

## Task 3: Create Makefile

**Files:**
- Create: `Makefile`

**Step 1: Create the Makefile**

```makefile
.PHONY: all build download clean test

# Default target
all: priv/og_image_nif.so

# Download precompiled NIF
download:
	@./scripts/download_nif.sh priv

# Build from source (requires Rust)
build:
	@echo "Building NIF from source..."
	@cd native/og_image_nif && cargo build --release
	@mkdir -p priv
	@cp native/og_image_nif/target/release/libog_image_nif.dylib priv/og_image_nif.so 2>/dev/null || \
	 cp native/og_image_nif/target/release/libog_image_nif.so priv/og_image_nif.so 2>/dev/null || \
	 echo "Error: Could not find compiled NIF"
	@echo "NIF built successfully"

# Try download first, fall back to build
priv/og_image_nif.so:
	@if ./scripts/download_nif.sh priv 2>/dev/null; then \
		echo "Downloaded precompiled NIF"; \
	else \
		echo "Download failed, building from source..."; \
		$(MAKE) build; \
	fi

# Run tests
test: priv/og_image_nif.so
	gleam test

# Clean build artifacts
clean:
	rm -rf priv/og_image_nif.so
	rm -rf native/og_image_nif/target
	rm -rf build
```

**Step 2: Verify Makefile works**

Run: `cd /Users/chadmiller/code/og_image && make build`
Expected: NIF builds successfully

**Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile for NIF build/download"
```

---

## Task 4: Update .gitignore

**Files:**
- Modify: `.gitignore`

**Step 1: Add checksum files to gitignore**

Add the following lines to `.gitignore`:

```
# NIF binaries (downloaded or built)
priv/og_image_nif.so
priv/*.sha256

# Rust build artifacts
native/og_image_nif/target/
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: update gitignore for NIF artifacts"
```

---

## Task 5: Update README with Installation Instructions

**Files:**
- Modify: `README.md`

**Step 1: Add installation section after "## Installation"**

Add after the `gleam add og_image` line:

```markdown
Then download the precompiled NIF for your platform:

```sh
make download
```

Or build from source (requires Rust):

```sh
make build
```

### Supported Platforms

| OS | Architecture | Status |
|----|--------------|--------|
| macOS | arm64 (Apple Silicon) | ✅ |
| macOS | x86_64 (Intel) | ✅ |
| Linux | x86_64 | ✅ |
| Linux | arm64 | ✅ |
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add precompiled NIF installation instructions"
```

---

## Task 6: Test the Build Process Locally

**Files:**
- None (verification only)

**Step 1: Clean and rebuild**

Run: `cd /Users/chadmiller/code/og_image && make clean && make build`
Expected: NIF builds successfully

**Step 2: Run tests**

Run: `cd /Users/chadmiller/code/og_image && make test`
Expected: All 27 tests pass

**Step 3: Verify download script syntax**

Run: `bash -n scripts/download_nif.sh`
Expected: No output (script is valid)

---

## Task 7: Create First Release (Manual)

**Step 1: Create and push a version tag**

```bash
git tag v0.1.0
git push origin v0.1.0
```

**Step 2: Verify GitHub Actions triggered**

Go to: `https://github.com/YOUR_USER/og_image/actions`
Expected: Release workflow running

**Step 3: Verify release assets**

Go to: `https://github.com/YOUR_USER/og_image/releases`
Expected: Release v0.1.0 with 8 assets (4 binaries + 4 checksums)

---

## Summary

**Total tasks:** 7

**Key files created:**
- `.github/workflows/release.yml` - CI workflow for building NIFs
- `scripts/download_nif.sh` - Platform-aware download script
- `Makefile` - Build automation

**User experience after implementation:**
```sh
gleam add og_image
make download  # or make build
gleam test
```
