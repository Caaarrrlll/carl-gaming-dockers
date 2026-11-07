# Audit Log — Debian Slim Base Image

## Image

| Item | Value |
|---|---|
| Source repo | `Caaarrrlll/docker-debian-baseimage` |
| Docker Hub image | `caaarrrlll/debian-slim-baseimage:trixie-latest` |
| Base image | `debian:trixie-slim` |
| Build context | `images/systems/debian-base/` |
| Last audited | 2026-11-07 |

## Current snapshot

- Installs `wget`, `locales`, `procps` (no recommends) and reinstalls
  `ca-certificates`.
- Enables Debian components `contrib`, `non-free`, `non-free-firmware`.
- Generates `en_US.UTF-8` and exports `LANG`, `LANGUAGE`, `LC_ALL`.
- Cleans `/var/lib/apt/lists/*` in the same layer.

## Change log

| Date | Commit | Change | Notes |
|---|---|---|---|
| 2026-06-17 | `74c9190` | update docker | |
| 2026-04-25 | `bf9c21f` | updated readme and finish base image | |
| 2026-04-25 | `66a9c3b` | Add docker and blank readme | |
| 2026-04-25 | `56737d2` | Initial commit | |

## Known issues / follow-ups

- `apt-get -y upgrade` runs at build time, so image contents vary by build date.
- No `.gitignore` in the repo.
- Tag `trixie-latest` tracks Debian testing; rebuild and re-audit when trixie
  becomes stable or packages shift.

## Audit checklist

- [ ] Base image/tag still exists and is supported.
- [ ] Package list is still minimal and uses `--no-install-recommends`.
- [ ] Package caches are cleaned in the same layer.
- [ ] Locale settings are intact.
- [ ] No secrets or credentials added.
- [ ] `org.opencontainers.image.*` labels are correct.
- [ ] README matches actual behavior.
- [ ] Image builds and pushes successfully.
- [ ] This log is updated with the date, commit, and change summary.
