# Audit Log — Fedora Base Image

## Image

| Item | Value |
|---|---|
| Source repo | `Caaarrrlll/docker-fedora-baseimage` |
| Docker Hub image | `caaarrrlll/fedora-baseimage:latest` (assumed) |
| Base image | `fedora:44` |
| Build context | `docker-fedora-baseimage/` |
| Last audited | 2026-11-07 |

## Current snapshot

- Installs `wget`, `glibc-langpack-en`, `procps-ng`, `ca-certificates` with
  `install_weak_deps=False`.
- Reinstalls `ca-certificates`.
- Sets `LANG`, `LANGUAGE`, `LC_ALL` to `en_US.UTF-8`.
- Cleans DNF caches in the same layer.
- Standalone image; not used by the Wine/SteamCMD chain.

## Change log

| Date | Commit | Change | Notes |
|---|---|---|---|
| 2026-10-23 | `f9d130d` | fedora base | Initial usable image |
| 2026-10-23 | `d895a48` | first commit | |

## Known issues / follow-ups

- `org.opencontainers.image.source` points at the Debian repo; should be
  `https://github.com/Caaarrrlll/docker-fedora-baseimage`.
- README title still says "Debian Base Image".
- Docker Hub tag `fedora-baseimage:latest` is assumed by `docker-updater.bat`;
  confirm it matches the actual published tag.
- No `.gitignore` in the repo.

## Audit checklist

- [ ] Base image/tag still exists and is supported.
- [ ] Package list is still minimal and uses `install_weak_deps=False`.
- [ ] Package caches are cleaned in the same layer.
- [ ] Locale settings are intact.
- [ ] No secrets or credentials added.
- [ ] `org.opencontainers.image.*` labels point to the correct repo.
- [ ] README matches actual behavior.
- [ ] Image builds and pushes successfully.
- [ ] This log is updated with the date, commit, and change summary.
