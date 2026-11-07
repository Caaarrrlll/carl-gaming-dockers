# AGENTS.md

Overview of this repository for automated/agent contributors.

## What this is

`carl-gaming-dockers` is a monorepo for the Docker images used to run an
**ARK: Survival Ascended** dedicated server under Wine on an **Unraid** host.
It was created by importing the original per-image repositories with
`git subtree`, so their history lives under `images/`.

## Layout

| Path | Image | Purpose |
|---|---|---|
| `images/debian-base/` | `caaarrrlll/debian-slim-baseimage:trixie-latest` | Slim Debian base image |
| `images/fedora-base/` | `caaarrrlll/fedora-baseimage:latest` | Slim Fedora base image (independent) |
| `images/wine-base/` | `caaarrrlll/wine-baseimage:latest` | Wine layered on the Debian base |
| `images/asa-docker/` | `caaarrrlll/asa-wine:latest` | SteamCMD + ARK: Survival Ascended, layered on Wine |

Supporting files:

- `dockers.code-workspace` — VS Code multi-root workspace definition.
- `scripts/docker-updater.bat` — builds and pushes all images.
- `docs/discussion.md` — Wine/Proton on Unraid, kernel/NTSYNC notes.
- `docs/monorepo-plan.md` — how this repo was assembled / migration plan.
- `images/*/audit.md` — per-image snapshot, change log, and review checklist.

## Image dependency chain

```
debian:trixie-slim
  └─ caaarrrlll/debian-slim-baseimage:trixie-latest   (images/debian-base)
       └─ caaarrrlll/wine-baseimage:latest            (images/wine-base)
            └─ caaarrrlll/asa-wine:latest             (images/asa-docker, ARK ASA)

fedora:44
  └─ caaarrrlll/fedora-baseimage:latest               (images/fedora-base)
```

Build order matters for the Debian → Wine → ASA chain: rebuild and push the base
before its dependents. The Fedora image is standalone.

## Building / releasing

Use `scripts/docker-updater.bat` (also exposed as the VS Code task
**Docker: Build & Push All**). It builds and pushes each image in dependency
order (debian → fedora → wine → asa-docker), aborting on the first failure.

Tags are defined in the `:updateandpush` section of the batch file. To rebuild a
single image manually:

```powershell
docker image build -t caaarrrlll/wine-baseimage:latest .\images\wine-base
docker image push caaarrrlll/wine-baseimage:latest
```

## Conventions

- Each Dockerfile keeps `org.opencontainers.image.*` labels (`authors`,
  `source`, `licenses`).
- Base images install only a minimal set of packages with
  `--no-install-recommends` (Debian) / `--setopt=install_weak_deps=False`
  (Fedora) and clean package caches in the same layer.
- Locale is set to `en_US.UTF-8` in the base images.
- `images/asa-docker` targets Unraid: it runs as `steam` with configurable
  `UID`/`GID`, uses `screen`/`xvfb`/Wine, and installs ARK ASA (app id
  `2430930`) into `/serverdata`.
- `images/asa-docker` is designed around the Unraid Docker template format
  (env vars such as `GAME_ID`, `GAME_PARAMS`, `UID`, `GID`, `VALIDATE`).
- Each image has an `audit.md`. Update it in the same change that modifies a
  Dockerfile, script, or image tag.

## Notes / gotchas

- Containers share the Unraid host kernel; no Dockerfile change can upgrade it.
  See `docs/discussion.md` for the NTSYNC / kernel 6.18 context.
- `images/fedora-base` labels/README still reference the Debian base
  (copy-paste leftovers) — verify before relying on image metadata.
- `images/asa-docker` still ships default game passwords and logs secrets when
  `DEBUG=1`; see its `audit.md`.
- Builds should run against the local Docker context (`docker context use
  desktop-linux`); do not set `DOCKER_HOST` to the Unraid SSH host for local
  builds.
