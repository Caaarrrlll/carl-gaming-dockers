# Housekeeping

Follow-up items carried over from the NTSYNC / Wine 11 migration recorded in
`docs/history/2026-11-07-ntsync-wine11.md` (closed 2026-11-07). Everything here
is **verification work on a running system** — nothing needs to change until
each item is confirmed or discarded.

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Reboot-persistence test for `modprobe ntsync` | **pending** | `/boot/config/go` contains the line (duplicate removed, static check passed 2026-11-07). After the next maintenance reboot, run `lsmod | grep ntsync` and `ls -l /dev/ntsync` **without manual intervention**. Until this passes, a reboot could silently drop the container back to plain wineserver sync. Blocked on server downtime (server actively used). |
| 2 | Re-check CPU at full player load | **optional** | Idle reference (2026-11-07): ~2.7–2.9% of one core vs ~high-3% pre-NTSYNC. Expect the gap to widen with concurrent player/entity load; compare `docker stats` CPU% and tick responsiveness under a full session. |
| 3 | Fedora base image re-activation | **parked** | `images/systems/fedora-base` is unused and excluded from CI tags/manual chains (`build_fedora` defaults to `false`). Re-enable when a workload actually needs it (see AGENTS.md note). |
| 4 | Verify the whole NTSYNC chain survived the first reboot | **same pass as item 1** | After reboot, also confirm the container start log shows `---NTSYNC enabled: /dev/ntsync is available, Wine will use it---`. |

## Record

When an item is confirmed, note the date and result below (and delete it from
the table):

- 2026-11-07 — NTSYNC chain verified end-to-end on live server: kernel 6.18.58
  module loaded, `--device=/dev/ntsync`, `NTSYNC=1`, `WINENTSYNC=1`,
  `wine-11.0`, `ArkAscendedServer.exe` idle CPU as above.
