# Discussion: Wine-based game server on Unraid + kernel upgrade questions

- **Date:** 2026-11-07
- **Repo:** `E:\Code\docker-debian-baseimage` (Debian slim base image)
- **Related host:** Unraid server at `<localip>` (SSH; Docker context name `unraid`)

## 1. Context / goal

- The **server is an Unraid host** running multiple Docker containers.
- The **gaming machine is a separate Windows PC** (the client/player).
- The goal is to run a **Wine instance / game host (dedicated game server)** inside a
  container on Unraid, and connect to it from the Windows machine.
- Initial assumption to validate: "kernel 7.0 is needed for much better Wine/Proton
  performance", and therefore Unraid might need to be replaced by a native Linux host.

## 2. TL;DR / conclusions

1. **A container always runs on the host kernel.** Nothing in a Dockerfile/base image
   can change the kernel. On Unraid, every container uses Unraid's kernel.
2. **"Unraid 7" is the OS version, not Linux 7.** Unraid tracks LTS kernels only.
   No Unraid release currently ships Linux 7.x.
3. **The main kernel-side Wine/Proton win is NTSYNC**, merged in Linux **6.14**.
   The server currently runs Unraid **7.2.9 / kernel 6.12.90**, which **predates**
   NTSYNC. Update to Unraid **7.3.x (6.18.x LTS)** to get it. Kernel 7.x is not
   required for the "much better Wine/Proton performance" effect.
4. **Docker is not a heavy abstraction; a VM is.** For a headless game server, running
   Wine in a container on Unraid is the lightest, most appropriate deployment.
5. **Decision: stay on Unraid.** Do not migrate to a native Linux host, and do not chase
   kernel 7.x for this workload. Enable NTSYNC and use modern Wine/Proton if desired.

## 3. Findings / background

### 3.1 Containers and the kernel

- Docker containers share the host kernel. `uname -r` inside a container reports the
  host's kernel.
- Changing `FROM debian:trixie-slim` to another Debian tag, or adding backports, does
  **not** change the kernel seen by the container.

### 3.2 Unraid kernel matrix (as of late 2026)

| Unraid OS | Linux kernel | Notes |
|---|---|---|
| 7.3.3 (current stable, 2026-10-08) | **6.18.54** (LTS) | Recommended baseline |
| 7.3.2 / 7.3.1 | 6.18.38 / 6.18.33 | 7.3 branch |
| 7.4.0-beta.1 | 6.18.44 | Beta |
| 7.2.8 / 7.2.9 | 6.12.98 / 6.12.90 | Older branch; **no NTSYNC** (predates 6.14) |

**Current server:** Unraid **7.3.4 / kernel 6.18.58-Unraid** (updated
2026-11-07, confirmed same day).

- Unraid has moved from 6.6 → 6.12 → 6.18, all **LTS** lines.
- 7.0 through 7.3 are **not** LTS, so Unraid is unlikely to adopt a 7.x kernel until a
  7.x line is designated LTS.

### 3.3 Linux 7.x status

- 7.0 released 2026-04; 7.3.x is current stable (7.3.1 at time of discussion).
- 7.0–7.3 are **not** LTS and 7.0 is already EOL.
- LTS lines today: 6.1, 6.6, 6.12, 6.18.

### 3.4 NTSYNC (the real Wine/Proton performance feature)

- `ntsync` is a kernel driver that implements Windows NT synchronization primitives
  (mutexes, semaphores, events) in the kernel instead of emulating them via the
  wineserver in user space. Large gains for CPU-heavy / multi-threaded titles.
- Merged into mainline in **Linux 6.14**.
- Wine **11.0** added native support; Proton 11 / GE-Proton use it when available.
- Verify on the host/container: `/dev/ntsync` exists and the module is loaded.
- Because Unraid 7.3.x = 6.18.x, NTSYNC is already present there; only enable/load it.
- **Done (2026-11-07):** the server was updated to Unraid **7.3.4 / kernel
  6.18.58**, which is ≥ 6.14, so `ntsync` is now available on the host; still
  needs `modprobe` + device passthrough (see Sections 5 and 6).

### 3.5 Container vs VM overhead

- Containers (namespaces/cgroups) add negligible overhead and share the host kernel.
- A KVM VM is the heavier abstraction (reserved CPU/RAM, separate kernel).
- For a headless dedicated game server, the container is preferred.

### 3.6 Unraid host is ephemeral

- Unraid roots from RAM/USB; the OS is effectively immutable and resets on reboot.
- Installing Wine/Proton "natively on the Unraid host" is not supported/persistent.
- Therefore the container (or a VM) is the correct way to run Wine on Unraid.

### 3.7 Image size / backports notes (from earlier in the discussion)

- Adding `trixie-backports` to `sources.list` costs ~nothing when apt lists are cleaned.
- `debian:trixie-backports` is the **full** image (no `-slim` variant), ~+18 MB compressed
  vs `trixie-slim`.
- Installing a backported `linux-image-*` into a container is pointless and large.
- Current Dockerfile uses `FROM debian:trixie-slim` (reverted from the backports base).

## 4. Decision

- **Keep Unraid** as the host for the game server container.
- **Do not migrate** to a native Linux host for this purpose.
- **Do not require kernel 7.x**; Unraid's 6.18 LTS already provides NTSYNC.
- Build a Wine container on a slim Debian base, optionally enable NTSYNC, and expose the
  game server port to the Windows client.

## 5. Checklist: confirm versions on the Unraid server

Run these on the Unraid host (or via SSH `root@<localip>`) and record results here:

```bash
# Kernel actually running
uname -r

# Unraid OS version
cat /etc/unraid-version 2>/dev/null

# Docker engine version
docker version --format '{{.Server.Version}}'

# NTSYNC availability (module + device)
modinfo ntsync 2>/dev/null | head -5
ls -l /dev/ntsync 2>/dev/null

# Kernel config (if /proc/config.gz exists)
zcat /proc/config.gz 2>/dev/null | grep -i ntsync

# Optional: GPU presence (only relevant if the server workload needs GPU/transcoding)
ls -l /dev/dri 2>/dev/null
nvidia-smi 2>/dev/null | head -5
```

Version results to fill in:

| Item | Value (record) |
|---|---|
| Unraid OS version | **7.3.4** (updated from 7.2.9 on 2026-11-07) |
| Kernel (`uname -r`) | **6.18.58-Unraid** |
| CPU | **AMD Ryzen 9 5950X (Zen 3, 16C/32T)** |
| Docker engine | **28.8.2** |
| `ntsync` module present | **Yes** — `modprobe ntsync` succeeds on 6.18.58 (confirmed 2026-11-07) |
| `/dev/ntsync` present | **Yes** — `crw-rw-rw- 10, 261` (confirmed 2026-11-07; disappears on reboot until persisted) |
| GPU (if any) | _(to confirm; not required for a headless server)_ |
| Wine version in container | **wine-10.0** (Debian 10.0~repack, confirmed 2026-11-07) — predates NTSYNC (10.4+); switched to WineHQ `winehq-stable` (Wine 11.0+) |
| Game/server binary | _(to confirm)_ |

Note: `/proc/config.gz` does not exist on Unraid (confirmed 2026-11-07), so the
kernel-config check is not available — verify NTSYNC via `modprobe` +
`ls -l /dev/ntsync` instead. Kernel 6.18.58 ≥ 6.14, so NTSYNC is expected to be
built into the kernel or shipped as a module.

**Implication:** The server was updated from Unraid 7.2.9 (6.12.90) to **7.3.4
(6.18.58)** on 2026-11-07, so the NTSYNC prerequisite is met. Next: `modprobe
ntsync`, confirm `/dev/ntsync`, persist it across reboots, and pass the device
to the container.

## 6. Recommended container approach

1. Base image: prefer `debian:trixie-slim` (small; userland on 6.18 host works fine).
2. Use a recent Wine with NTSYNC support: the image was switched to the WineHQ
   repo (`winehq-stable` = Wine 11.0+, released 2026-01-13 with NTSYNC as a
   headline feature). Decision: plain Wine via WineHQ, **not** Proton — Proton
   required Steam logins and caused issues in the early Docker builds.
3. **Done (2026-11-07):** Unraid was updated from 7.2.9 (6.12.90) to 7.3.4
   (6.18.58), which provides NTSYNC. Remaining on the Unraid host, load NTSYNC
   and persist it, then pass the device to the container:

   ```bash
   # on Unraid host
   modprobe ntsync
   # persist (Unraid boots from /boot/config/go or a User Script)
   echo "modprobe ntsync" >> /boot/config/go
   ```

   Container template / `docker run`:
   ```bash
   --device /dev/ntsync
   ```

   As of 2026-11-07 the `caaarrrlll/asa-wine` image has a built-in
   `NTSYNC` flag for this: set `NTSYNC=1` and the container validates
   `/dev/ntsync` on start, exports `WINENTSYNC=1`, and falls back to
   ESync/FSync with a log warning when the device is missing (see
   `images/games/asa-docker/`).

4. Publish only the game server port(s) the Windows client needs.
5. Confirm whether the specific game server binary actually benefits from NTSYNC; for
   many dedicated servers the gain is small, but it is harmless to enable.

## 7. Local build environment notes (for reproducibility)

- VS Code's **Containers extension** was injecting `DOCKER_HOST=ssh://root@<localip>`
  into every integrated terminal via the `containers.environment` setting. This made
  local builds try to build over SSH to Unraid.
- Fixed by removing that entry from `%APPDATA%\Code\User\settings.json`. The Docker
  context was switched to `desktop-linux`. Use named contexts instead of `DOCKER_HOST`:
  - `docker context use desktop-linux` (local Docker Desktop)
  - `docker context use unraid` (remote Unraid over SSH, when reachable)
- Local Docker Desktop runs on WSL2 (kernel 6.6.x) — irrelevant to the Unraid
  deployment's kernel.

## 8. Open questions / next steps

- [x] Record actual Unraid kernel / OS versions: 7.2.9 / 6.12.90-Unraid (Section 5).
- [x] Record Docker engine version on the server: **28.8.2**.
- [x] Update Unraid 7.2.9 → 7.3.4 (done 2026-11-07): kernel 6.18.58-Unraid, Docker 28.8.2.
- [x] After update, confirm `ntsync` is available: `modprobe ntsync` succeeds and
  `/dev/ntsync` exists (2026-11-07).
- [ ] Persist `modprobe ntsync` across reboots (`/boot/config/go` or User Scripts;
  check for duplicates first).
- [x] Decide Wine vs Proton/umu for the specific game server binary: plain Wine
  via the WineHQ repo (`winehq-stable`, Wine 11.0+); no Proton (requires Steam
  logins).
- [ ] Confirm which game/server binary this is.
- [ ] Validate whether NTSYNC measurably helps that server binary.
- [ ] Finalize the container image (Dockerfile) and Unraid template.
- [ ] Confirm required port mappings and whether the Windows client needs anything else.

## 9. References

- Linux kernel releases / LTS: https://www.kernel.org/category/releases.html
- WSL2 kernel (local dev only): https://github.com/microsoft/WSL2-Linux-Kernel
- Unraid release notes: https://docs.unraid.net/unraid-os/release-notes/
- NTSYNC (Phoronix): https://www.phoronix.com/news/Linux-6.14-NTSYNC-Driver-Ready
- Wine 11 / NTSYNC: https://www.winehq.org/
