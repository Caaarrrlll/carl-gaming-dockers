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
- Installs Debian-packaged `wine`, `wine64`, `libwine`, `fonts-wine`.
- The WineHQ repository block is present but commented out.

## Change log

| Date | Commit | Change | Notes |
|---|---|---|---|
| 2026-05-06 | `cf66d87` | newer wine | |
| 2026-04-25 | `cf119f7` | wine wrapper | |

## Known issues / follow-ups

- Uses Debian's packaged Wine, not WineHQ; Wine version is tied to the Debian
  `trixie` archive.
- The active install does not clean `/var/lib/apt/lists/*` (the cleanup line is
  inside the commented-out block), so the image carries extra apt metadata.
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
