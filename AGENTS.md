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
- `.github/workflows/build-images.yml` — CI build/push workflow.
- `scripts/docker-updater.bat` — builds and pushes all images (Windows).
- `scripts/docker-updater.sh` — builds and pushes all images (Linux/macOS).
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

Use `scripts/docker-updater.sh` (Linux/macOS) or
`scripts/docker-updater.bat` (Windows); the latter is also exposed as the VS Code
task **Docker: Build & Push All**. They build and push each image in dependency
order (debian → fedora → wine → asa-docker), aborting on the first failure.

Both scripts require the `DOCKERHUB_USER` environment variable and exit with an
error if it is not set:

```bash
DOCKERHUB_USER=myuser ./scripts/docker-updater.sh
```

```powershell
$env:DOCKERHUB_USER = "myuser"
.\scripts\docker-updater.bat
```

`DOCKERHUB_USER` replaces the namespace in the tags that are built and pushed;
it deliberately does **not** default to `caaarrrlll`, so contributors cannot
accidentally push to the maintainer's Docker Hub account. The Dockerfiles'
`FROM` lines intentionally keep referencing the maintainer's published images,
so the dependency chain builds on those public bases regardless of which
namespace is being pushed to.

To rebuild a single image manually:

```powershell
docker image build -t caaarrrlll/wine-baseimage:latest .\images\wine-base
docker image push caaarrrlll/wine-baseimage:latest
```

CI (`Build and push images`) runs on pushes to `main`, `v*` tags, and manual
dispatch. On a normal push it only rebuilds affected images and their
dependents: Debian changes trigger debian → wine → asa; Wine changes trigger
wine → asa; Fedora is independent. Tag pushes and manual runs build everything.
It expects repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.

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

- If a user reports `DOCKERHUB_USER is not set` (or a build/push fails
  immediately), the build scripts are refusing to run without a Docker Hub
  username. This is intentional: do not "fix" it by defaulting back to
  `caaarrrlll`. Ask them to export `DOCKERHUB_USER` first (see above).
- The Dockerfiles' `FROM` lines intentionally reference `caaarrrlll/...`
  images. Only the tags built/pushed by the scripts use `DOCKERHUB_USER`, so a
  fork builds on the maintainer's public base images rather than its own.
- Containers share the Unraid host kernel; no Dockerfile change can upgrade it.
  See `docs/discussion.md` for the NTSYNC / kernel 6.18 context.
- `images/fedora-base` labels/README still reference the Debian base
  (copy-paste leftovers) — verify before relying on image metadata.
- `images/asa-docker` ships default game passwords and logs secrets when
  `DEBUG=1`. This is **accepted**: the Unraid template overrides the passwords
  and `DEBUG` defaults to `0`. See its `audit.md` before changing this behavior.
- Builds should run against the local Docker context (`docker context use
  desktop-linux`); do not set `DOCKER_HOST` to the Unraid SSH host for local
  builds.
