# Repository Guidelines

## Project Structure & Module Organization
- `build.sh` — main entrypoint to fetch ImageBuilder, assemble packages, produce `output/rootfs.tar.gz`, and optionally build a Docker image.
- `files/` — overlay copied into ImageBuilder `FILES` (e.g., `files/etc/uci-defaults/99-custom.sh`).
- `shell/` — helper scripts for package preparation and customization.
- `Dockerfile` — minimal image that `ADD`s `rootfs.tar.gz` into `FROM scratch`.
- `work/` (generated) — temporary working data; safe to delete.
- `output/` (generated) — build artifacts, notably `rootfs.tar.gz`.
- `build-amd64.yml` — reusable GitHub Actions workflow file.

## Build, Test, and Development Commands
- Local build (rootfs only):
  `PROFILE=1024 CUSTOM_PACKAGES="" bash ./build.sh`
- Local build + Docker image:
  `PROFILE=1024 INCLUDE_DOCKER=yes ENABLE_PPPOE=no bash ./build.sh -d`
- Verify artifacts: `ls output/` (expect `rootfs.tar.gz`) and `docker images | grep immortalwrt/x86-64` when `-d` is used.
- CI usage: copy `build-amd64.yml` into `.github/workflows/` of a parent repo and set `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` secrets.

## Coding Style & Naming Conventions
- Shell: POSIX `sh` for helpers, `bash` for `build.sh`. Keep `set -euo pipefail` where applicable.
- Indentation: 2 spaces; avoid tabs. Line length ≤ 120.
- Filenames: lowercase with hyphens (e.g., `prepare-packages.sh`). Vars in `UPPER_SNAKE_CASE`.
- Prefer small, composable scripts in `shell/`. Validate with `shellcheck` where possible.

## Testing Guidelines
- No unit tests; validate by building:
  - Confirm `output/rootfs.tar.gz` exists and extracts.
  - If `INCLUDE_DOCKER=yes` and `-d`, confirm image tags: `immortalwrt/x86-64:24.10` and `immortalwrt/x86-64:24.10.3`.
  - Boot test the image where practical and verify UCI defaults applied from `files/`.

## Commit & Pull Request Guidelines
- Commits: use Conventional Commits (`feat:`, `fix:`, `chore:`, `build:`). Scope examples: `shell`, `files`, `ci`, `docker`.
- PRs: include a clear summary, rationale, tested command(s), relevant logs/output, and any CI changes. Link related issues. Keep changes minimal and focused.

## Security & CI Tips
- CI pushing requires `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets.
- Network downloads occur during build; changes to `VERSION` or sources should be explicit and reviewed.
- Run on Linux/macOS or WSL/Git Bash on Windows; Docker must be available when using `-d`.
