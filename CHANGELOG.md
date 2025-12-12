# Changelog

## v1.1.0

### Added

- JavaScript target support using takumi-wasm for image generation
- Unified synchronous API that works on both Erlang and JavaScript targets
- Bundled takumi-wasm in `priv/vendor/` (no npm dependencies required for consumers)
- Bundled Twemoji font for emoji rendering on JavaScript target
- Automatic NIF binary download from GitHub releases on first use (Erlang target)

### Changed

- Moved `simplifile` to dev-dependencies
- NIF binaries no longer bundled in Hex package (downloaded on demand)

## v1.0.0

- Initial release with Erlang target support
