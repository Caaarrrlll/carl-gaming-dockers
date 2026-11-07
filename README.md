# carl-gaming-dockers

Monorepo for the Docker images used to run an **ARK: Survival Ascended**
dedicated server under Wine on **Unraid**.

## Images

| Path | Docker Hub image | Base |
|---|---|---|
| `images/debian-base` | `caaarrrlll/debian-slim-baseimage:trixie-latest` | `debian:trixie-slim` |
| `images/fedora-base` | `caaarrrlll/fedora-baseimage:latest` | `fedora:44` |
| `images/wine-base` | `caaarrrlll/wine-baseimage:latest` | `caaarrrlll/debian-slim-baseimage:trixie-latest` |
| `images/asa-docker` | `caaarrrlll/asa-wine:latest` | `caaarrrlll/wine-baseimage:latest` |

## Dependency chain

```
debian:trixie-slim
  └─ debian-slim-baseimage
       └─ wine-baseimage
            └─ asa-wine (ARK: Survival Ascended)

fedora:44
  └─ fedora-baseimage
```

Build the Debian → Wine → ASA images in order. The Fedora image is independent.

## Build and push

```powershell
.\scripts\docker-updater.bat
```

Or in VS Code, run the **Docker: Build & Push All** task from
`dockers.code-workspace`.

## Layout

- `images/` — one directory per published image.
- `scripts/` — build/push helpers.
- `docs/` — design notes and migration plan.
- `AGENTS.md` — contributor/agent overview.

Each image directory has an `audit.md` tracking its snapshot and changes.
