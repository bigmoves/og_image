.PHONY: all build clean test

# Detect platform
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
    OS := macos
    LIB_EXT := dylib
else
    OS := linux
    LIB_EXT := so
endif

ifeq ($(UNAME_M),arm64)
    ARCH := arm64
else ifeq ($(UNAME_M),aarch64)
    ARCH := arm64
else
    ARCH := x86_64
endif

PLATFORM := $(OS)-$(ARCH)
NIF_NAME := og_image_nif-$(PLATFORM).so

# Default target
all: priv/$(NIF_NAME)

# Build from source (requires Rust)
build:
	@echo "Building NIF from source for $(PLATFORM)..."
	@cd native/og_image_nif && cargo build --release
	@mkdir -p priv
	@cp native/og_image_nif/target/release/libog_image_nif.$(LIB_EXT) priv/$(NIF_NAME)
	@echo "NIF built successfully: priv/$(NIF_NAME)"

# Build target
priv/$(NIF_NAME):
	$(MAKE) build

# Run tests
test: priv/$(NIF_NAME)
	gleam test

# Clean build artifacts
clean:
	rm -rf priv/og_image_nif*.so
	rm -rf native/og_image_nif/target
	rm -rf build

# Build all platforms (for CI - requires cross-compilation setup)
build-all:
	@echo "This target is meant for CI. Use GitHub Actions to build all platforms."
