# History

Consolidated, dated record of significant decisions and upgrades for these
Docker images. Detailed working notes live in the referenced files; when a
long-running upgrade finishes, its tracking document is moved under
`docs/history/` with a date-first name (for example
`docs/history/2026-11-07-ntsync-wine11.md`) so entries sort chronologically,
and referenced from this file.

## 2026-11-07 — Unraid 7.3.4 upgrade + NTSYNC end-to-end

- Unraid upgraded **7.2.9 (kernel 6.12.90) → 7.3.4 (kernel 6.18.58)**, Docker
  engine 28.8.2. Kernel 6.18 ≥ 6.14, so the **NTSYNC** sync driver is available
  on the host for the first time.
- Host: `modprobe ntsync` verified, `/dev/ntsync` created, persistence added to
  `/boot/config/go`.
- `images/systems/wine-base` switched from Debian's packaged Wine (`wine-10.0`,
  no NTSYNC) to the WineHQ repo (`winehq-stable` = **Wine 11.0**, NTSYNC as a
  headline feature). Plain Wine kept on purpose — Proton required Steam logins
  and was painful in early Docker builds.
- `images/games/asa-docker` gained the `NTSYNC` env flag (`0`/`1`, mirrors
  `DEBUG`): validates `/dev/ntsync` at container start, exports
  `WINENTSYNC=1`, and falls back to ESync/FSync with a log warning when the
  device is missing.
- Unraid template: `NTSYNC=1` + Extra Parameters `--device=/dev/ntsync`.
- Result: end-to-end chain verified live (`lsmod` → device → flag → `wine-11.0`
  → `ArkAscendedServer.exe`). Idle CPU ~2.7–2.9% of one core vs ~high-3%
  before. Working notes: `docs/history/2026-11-07-ntsync-wine11.md`; open
  follow-ups: `docs/housekeeping.md`.

## 2026-11-07 — Monorepo migration

- The four image repositories (`docker-debian-baseimage`,
  `docker-fedora-baseimage`, `wine-baseimage`, `docker-steamcmd`) were
  consolidated into this repo via `git subtree` (history preserved under
  `images/`).
- Root CI (`.github/workflows/build-images.yml`) replaces the local
  `docker-updater` scripts for releases; builds/pushes run in dependency order
  (debian → wine → asa) with path-based selective rebuilds; validated with a
  full build and Docker Hub deploy on 2026-11-07.
- Old repositories retired via GitHub archive on 2026-11-07 (tags/releases
  remain on Docker Hub).
- Layout reorganised into `images/systems/` + `images/games/` (commit
  `04d4421`); per-image `audit.md` snapshots live alongside each Dockerfile.

## 2026-04/05 — Initial images (pre-monorepo)

- `caaarrrlll/debian-slim-baseimage:trixie-latest` — slim Debian base en_US
  locale, minimal packages.
- `caaarrrlll/wine-baseimage:latest` — Wine layered on the Debian base
  (`i386` enabled, winbind-friendly).
- `caaarrrlll/asa-wine:latest` — SteamCMD + ARK: Survival Ascended (app id
  `2430930`) for Unraid (`UID`/`GID` remap, `/serverdata` volumes).
- `caaarrrlll/fedora-baseimage:latest` — independent Fedora base, currently
  unused and excluded from CI (parked, see `docs/housekeeping.md`).
