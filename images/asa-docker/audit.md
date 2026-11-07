# Audit Log — SteamCMD / ARK: Survival Ascended

## Image

| Item | Value |
|---|---|
| Source repo | `Caaarrrlll/docker-steamcmd` |
| Docker Hub image | `caaarrrlll/asa-wine:latest` |
| Base image | `caaarrrlll/wine-baseimage:latest` |
| Build context | `docker-steamcmd/` |
| Game | ARK: Survival Ascended, app id `2430930` |
| Last audited | 2026-11-07 |

## Current snapshot

- Installs `lib32gcc-s1`, `lib32stdc++6`, `lib32z1`, `screen`, `xvfb`, `winbind`.
- Runs as user `steam` with configurable `UID`/`GID` (defaults `99`/`100`).
- Stores data in `/serverdata` (`steamcmd/`, `serverfiles/`).
- Defaults: map `TheIsland_WP`, ports `7777`/`27015`, `VALIDATE=0`, `DEBUG=0`.
- Entrypoint `/opt/scripts/start.sh`; server logic in `start-server.sh`.
- Targets the Unraid Docker template format.

## Change log

| Date | Commit | Change | Notes |
|---|---|---|---|
| 2026-08-09 | `6c282ba` | change validation | |
| 2026-08-09 | `8e3499d` | add steam validate | |
| 2026-07-25 | `f104ee0` | add xdg folder | |
| 2026-05-06 | `17bf1a6` | fix naming issue | |
| 2026-05-06 | `d9bf5f8` | server name glitch | |
| 2026-05-06 | `db9667e` | Merge pull request #1 | from `testing-ich-code` |
| 2026-05-06 | `b9ee5f6` | add debug option and split out cluster and mods | |
| 2026-05-06 | `a8db4a4` | cleanup validate | |
| 2026-05-06 | `5c6ba65` | cleanup of scripts and add more env params | |
| 2026-05-06 | `cd0912e` | fix wine64 | |
| 2026-05-06 | `cd24ab8` | ich shells with my base image | |
| 2026-05-04 | `4eda0cc` | ich code with my base image | |
| 2026-05-04 | `00d4980` | latest push | |
| 2026-04-28 | `7b72eaf` | add watchdog and make slight changes | |
| 2026-04-25 | `e119865` | add CA certs to ark container | |
| 2026-04-25 | `b0ccf3f` | refactor to own images | |

## Known issues / follow-ups

- Default game passwords are baked into the Dockerfile (`SRV_PWD="Docker"`,
  `SRV_ADMIN_PWD="adminDocker"`); require them via Unraid/env instead.
- With `DEBUG=1`, `start-server.sh` prints `SRV_PWD`, `SRV_ADMIN_PWD`,
  `LOGIN_CREDENTIALS`, and `ARK_RUN_STRING` (contains passwords) to the log.
- `org.opencontainers.image.source` points at `docker-steamcmd-server`, not this
  repo.
- README run example references `caaarrrlll/ark-ascended-proton:latest`; actual
  image is `caaarrrlll/asa-wine:latest`.
- `VALIDATE` is declared twice in the Dockerfile (`""` then `0`).
- No `.gitignore` in the repo.

## Audit checklist

- [ ] Base image tag still exists and builds.
- [ ] SteamCMD downloads and ARK app `2430930` updates successfully.
- [ ] `UID`/`GID` remapping works; file ownership on `/serverdata` is correct.
- [ ] Ports `7777`/`27015` and cluster/mod options behave as documented.
- [ ] `VALIDATE` logic matches the README.
- [ ] No default credentials or secret logging.
- [ ] No secrets or credentials added.
- [ ] `org.opencontainers.image.*` labels are correct.
- [ ] README matches actual behavior.
- [ ] Image builds and pushes successfully.
- [ ] This log is updated with the date, commit, and change summary.
