# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A bash-based tool for downloading Dify 1.0 plugins from multiple sources and repackaging them into offline-capable `.difypkg` files. Plugins are made offline by downloading all Python dependency wheels and injecting `[tool.uv]` configuration so the Dify plugin daemon can install them without internet access.

## Core Script: `plugin_repackaging.sh`

The entire tool is a single ~465-line bash script with four commands:

| Command | Args | Description |
|---------|------|-------------|
| `market` | author, name, version | Download from Dify Marketplace and repackage |
| `github` | repo, release_tag, asset_name | Download from GitHub releases and repackage |
| `local` | path/to/file.difypkg | Repackage an existing local plugin |

**Options:** `-p platform` (cross-platform pip download, e.g. `manylinux2014_x86_64`), `-s suffix` (output filename suffix), `-R` (allow prereleases in uv resolution).

### Repackaging Pipeline (the `repackage()` function)

Steps must run in order due to dependencies:

1. **Extract** `.difypkg` (it's a zip)
2. **Strip `[dependency-groups]`** from `pyproject.toml` — removes dev dependencies before resolution
3. **Generate `uv.lock`** using `uv lock` — MUST run before `[tool.uv]` injection, because `no-index = true` would block resolution
4. **Export `requirements.txt`** from `uv.lock` via `uv export` (only if no existing `requirements.txt`)
5. **Inject `[tool.uv]`** into `pyproject.toml` — adds `no-index = true`, `find-links = ["./wheels"]`, `prerelease = "allow"` for offline daemon usage
6. **Download wheels** via `pip download` into `./wheels/`, plus workaround packages (`cffi`, `pycparser`, `colorama`) for daemon compatibility
7. **Update `requirements.txt`** — prepend `--no-index --find-links=./wheels/`
8. **Package** using `dify-plugin-<os>-<arch>` binary from the repo root

## Platform Binaries

Pre-compiled `dify-plugin` CLI binaries in the repo root, selected at runtime based on `uname`:
- `dify-plugin-linux-amd64` / `dify-plugin-linux-arm64`
- `dify-plugin-darwin-amd64` / `dify-plugin-darwin-arm64`

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `GITHUB_API_URL` | `https://github.com` | Custom GitHub endpoint |
| `MARKETPLACE_API_URL` | `https://marketplace.dify.ai` | Custom marketplace endpoint |
| `PIP_MIRROR_URL` | `https://mirrors.aliyun.com/pypi/simple` | pip index mirror |

## Docker

```bash
docker build -t dify-plugin-repackaging .
docker run -v $(pwd):/app dify-plugin-repackaging
```

Override CMD for different plugins. The Dockerfile uses Chinese mirrors (Huawei cloud for base image, USTC for apt).

## GitHub Actions

`.github/workflows/build.yml` — manually triggered workflow (`workflow_dispatch`) that downloads a marketplace plugin, repackages it, and uploads the artifact. Inputs: `plugin_author`, `plugin_name`, `plugin_version`, `platform_arm` (boolean).

## Key Constraints

- Python 3.12 is required (matching `dify-plugin-daemon`). If system Python is 3.14+, the script falls back to `python3.12` or `python3.13`.
- The ordering of dependency processing steps is critical: strip dependency-groups → uv lock → export requirements → inject tool.uv → pip download. Changing this order will break offline resolution.
- The workaround packages (`cffi`, `pycparser`, `colorama`) handle PEP 508 conditional dependency issues in older daemon/uv versions.
- macOS vs Linux differences are handled with conditional `sed -i` syntax (macOS requires a backup suffix).
