# Audit Log — Wine Base Image

## Image

| Item | Value |
|---|---|
| Source repo | `Caaarrrlll/wine-baseimage` |
| Docker Hub image | `caaarrrlll/wine-baseimage:latest` |
| Base image | `caaarrrlll/debian-slim-baseimage:trixie-latest` |
| Build context | `images/systems/wine-base/` |
| Last audited | 2026-11-07 |

## Current snapshot

- Enables the `i386` architecture.
- Installs WineHQ `winehq-stable` (Wine 11.x) from the WineHQ Debian repo via
  keyring/signed-by (no `gnupg2`, no `apt-key`; base image provides `wget` and
  `ca-certificates`).
- `PATH` includes `/opt/wine-stable/bin`.
- Package caches are cleaned in the same layer.

## Change log

| Date | Commit | Change | Notes |
|---|---|---|---|
| 2026-11-07 | _(this change)_ | switch to WineHQ `winehq-stable` | Debian's packaged Wine is `10.0` (confirmed in the running container), which predates NTSYNC support (Wine 10.4+/11). WineHQ stable is Wine 11.0 with NTSYNC highlights. Also fixes the missing apt cache cleanup. |
| 2026-05-06 | `cf66d87` | newer wine | |
| 2026-04-25 | `cf119f7` | wine wrapper | |

## Known issues / follow-ups

- Wine `wine --version` should verify as `wine-11.x` after the next build; if
  WineHQ stable ever lags NTSYNC fixes, `winehq-devel` is the fallback.
- The ASA image's `WINEPREFIX` (`/serverdata/serverfiles/WINE64`) was created
  under Wine 10.0; Wine 11 upgrades the prefix on first run. Watch the first
  container start after the update.
- No `.gitignore` in the repo.

## Audit checklist

- [ ] Base image tag still exists and builds.
- [ ] `i386` architecture still required and enabled.
- [ ] Wine package source/version is intentional (Debian vs WineHQ).
- [ ] Package caches are cleaned in the same layer.
- [ ] No secrets or credentials added.
- [ ] `org.opencontainers.image.*` labels are correct.
- [ ] README matches actual behavior.
- [ ] Image builds and pushes successfully.
- [ ] This log is updated with the date, commit, and change summary.
