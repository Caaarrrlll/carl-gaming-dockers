# Monorepo Migration Plan

Goal: consolidate the four image repositories under this folder into a single
GitHub monorepo, `carl-gaming-dockers`, while keeping the existing Docker Hub
images and build flow working.

## Original state (pre-migration)

| Path | Remote | Image |
|---|---|---|
| `docker-debian-baseimage/` | `Caaarrrlll/docker-debian-baseimage` | `caaarrrlll/debian-slim-baseimage:trixie-latest` |
| `docker-fedora-baseimage/` | `Caaarrrlll/docker-fedora-baseimage` | `caaarrrlll/fedora-baseimage:latest` (assumed) |
| `wine-baseimage/` | `Caaarrrlll/wine-baseimage` | `caaarrrlll/wine-baseimage:latest` |
| `docker-steamcmd/` | `Caaarrrlll/docker-steamcmd` | `caaarrrlll/asa-wine:latest` |

Before migration each path was an independent git repository and the workspace
root was not a git repository.

## Current state

The monorepo exists at `Caaarrrlll/carl-gaming-dockers` and `main` is pushed to
`origin`. Images were imported with `git subtree` and the current layout is:

```
carl-gaming-dockers/
├─ .github/
│  └─ workflows/
│     └─ build-images.yml
├─ docs/
│  ├─ discussion.md
│  └─ monorepo-plan.md
├─ images/
│  ├─ debian-base/
│  ├─ fedora-base/
│  ├─ wine-base/
│  └─ asa-docker/
├─ scripts/
│  ├─ docker-updater.bat
│  └─ docker-updater.sh
├─ .gitignore
├─ AGENTS.md
├─ README.md
└─ dockers.code-workspace
```

Each image still has an `audit.md`. The local build scripts require
`DOCKERHUB_USER`; CI uses the `DOCKERHUB_USERNAME` secret instead.

## Migration status

- [x] Phase 0.1 — secret/hygiene scan (no credentials found)
- [x] Phase 0.2 — redact private LAN details in `docs/discussion.md`
- [x] Phase 0.3 — accepted: game password defaults are overridden by the Unraid template and `DEBUG=0` by default
- [x] Phase 1 — back up and verify remotes (recheck the backup still exists)
- [x] Phase 2 — create the monorepo layout
- [x] Phase 3 — import image histories with `git subtree`
- [x] Phase 4 — add the root `.gitignore`
- [x] Phase 5.1 — add the CI workflow file
- [x] Phase 5.2 — configure repository secrets
- [ ] Phase 5.3 — get a successful CI run
- [x] Phase 6 — push the monorepo to `origin/main`
- [ ] Phase 6.1 — verify CI builds and `docker pull` of every tag
- [ ] Phase 7 — retire the original repositories

## Phase 0 — Secret / hygiene audit (do this first)

Scan result: **no committed keys, tokens, `.env` files, certificates, or SSH
keys were found** in working trees or git history. Items worth fixing before
consolidation:

1. `docker-steamcmd/Dockerfile` ships default game passwords:
   `SRV_PWD="Docker"` and `SRV_ADMIN_PWD="adminDocker"`. These are insecure
   defaults, not real credentials. Remove the defaults (or set them empty) and
   require them via the Unraid template / `--env`.
2. `docker-steamcmd/scripts/start-server.sh` prints secrets to the container log
   when `DEBUG=1`: `SRV_PWD`, `SRV_ADMIN_PWD`, `LOGIN_CREDENTIALS` (Steam
   username/password) and `ARK_RUN_STRING` (contains both game passwords). Mask
   or drop these lines.
3. `discussion.md` contains the private LAN address `<localip>` and the
   hostname `<hostname>`. Not a credential, but move it to `docs/` and consider
   redacting before publishing publicly.
4. No repo has a `.gitignore`. Add one at the monorepo root.

Decision (2026-11-07): items 1 and 2 are **accepted as-is**. The image targets
Unraid, where the template supplies `SRV_PWD` and `SRV_ADMIN_PWD` at container
creation time regardless of the Dockerfile defaults. `DEBUG` defaults to `0`, so
secret logging only happens if an operator explicitly enables it, and the output
is only visible to someone already logged in to their own Unraid host. Revisit
if this image is ever offered as a standalone/non-Unraid container.

Recommended verification before publishing:

```powershell
# install once: https://github.com/gitleaks/gitleaks
gitleaks detect --source . --verbose
gitleaks protect --staged --verbose   # pre-commit check
```

## Phase 1 — Back up and verify remotes

```powershell
Copy-Item -Recurse -Force E:\Code\dockers E:\Code\dockers-backup
foreach ($d in 'docker-debian-baseimage','docker-fedora-baseimage','wine-baseimage','docker-steamcmd') {
    git -C "E:\Code\dockers\$d" status --short
    git -C "E:\Code\dockers\$d" push
}
```

Do not delete the existing repositories or the backup until the monorepo is
verified.

## Phase 2 — Proposed monorepo layout

**Status:** done (see "Current state" above). The original target layout was:

```
carl-gaming-dockers/
├─ .github/
│  └─ workflows/
│     └─ build-images.yml
├─ docs/
│  ├─ discussion.md
│  └─ unraid-template.md
├─ images/
│  ├─ debian-base/            # from docker-debian-baseimage
│  │  ├─ Dockerfile
│  │  ├─ LICENSE
│  │  └─ README.md
│  ├─ fedora-base/            # from docker-fedora-baseimage
│  ├─ wine-base/              # from wine-baseimage
│  └─ asa-docker/             # from docker-steamcmd (ARK: Survival Ascended)
│     ├─ Dockerfile
│     ├─ scripts/
│     └─ asa.png
├─ scripts/
│  ├─ docker-updater.bat
│  └─ docker-updater.sh
├─ .gitignore
├─ AGENTS.md
├─ README.md
└─ dockers.code-workspace
```

`docs/unraid-template.md` was not imported; add it if the Unraid template is
still kept elsewhere. Per-image `audit.md` files were added on top of the
imported contents.

Dockerfiles reference published image tags (`caaarrrlll/...`), not relative
paths, so moving folders does not change the build graph.

## Phase 3 — Create the monorepo and preserve history

**Status:** done. `git subtree` keeps each repo's commit history under a
subdirectory.

```powershell
cd E:\Code
git init carl-gaming-dockers
cd carl-gaming-dockers
git commit --allow-empty -m "chore: initialize monorepo"
git branch -M main
git remote add origin https://github.com/Caaarrrlll/carl-gaming-dockers.git

git subtree add --prefix=images/debian-base https://github.com/Caaarrrlll/docker-debian-baseimage.git master
git subtree add --prefix=images/fedora-base https://github.com/Caaarrrlll/docker-fedora-baseimage.git master
git subtree add --prefix=images/wine-base   https://github.com/Caaarrrlll/wine-baseimage.git master
git subtree add --prefix=images/asa-docker  https://github.com/Caaarrrlll/docker-steamcmd.git master
```

If the full history is not wanted, add `--squash` to each command to keep a
single import commit per image.

Then copy the root-level files into place:

```powershell
New-Item -ItemType Directory docs, scripts -Force
Copy-Item E:\Code\dockers\discussion.md docs\discussion.md
Copy-Item E:\Code\dockers\docker-updater.bat scripts\docker-updater.bat
Copy-Item E:\Code\dockers\AGENTS.md .
Copy-Item E:\Code\dockers\dockers.code-workspace .
```

Update paths for the new layout:

- `scripts/docker-updater.bat`: change `REPOS` to the new folder names and
  change `:buildpush` targets to `images\debian-base`, etc.
- `dockers.code-workspace`: change folder `path` values to `images/...`.
- `AGENTS.md`: update the layout table and build commands.

## Phase 4 — Root `.gitignore`

**Status:** done. Current contents:

```gitignore
# Secrets / local config
.env
.env.*
*.key
*.pem
*.p12
*.pfx
*.kdbx
id_rsa
id_dsa
id_ecdsa
id_ed25519
.docker/config.json

# OS / editor
.DS_Store
Thumbs.db
desktop.ini
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json
!.vscode/tasks.json

# Build / runtime data
*.log
serverdata/
```

## Phase 5 — GitHub Actions build pipeline

**Status:** workflow added at `.github/workflows/build-images.yml`; repository
secrets and the first CI run are still pending.

CI replaces the local `docker-updater` scripts for releases. The workflow runs
all builds as sequential steps in one job, so the Debian → Wine → ASA order is
guaranteed and a failed step stops the chain. It uses `dorny/paths-filter` to
rebuild only the affected images:

| Changed path | Images rebuilt, in order |
|---|---|
| `images/debian-base/**` | debian → wine → asa |
| `images/fedora-base/**` | fedora (independent) |
| `images/wine-base/**` | wine → asa |
| `images/asa-docker/**` | asa |
| workflow file, tag push, or manual dispatch | debian → wine → asa |
| manual dispatch with `build_fedora` enabled | adds fedora |

Fedora is deliberately excluded from the normal chain to save GitHub Actions
minutes because the image is not currently used. It still builds when its own
files change, or when the `build_fedora` checkbox is selected on a manual run.

The dependent builds use `pull: true`, so Wine pulls the Debian image that was
just pushed, and ASA pulls the just-pushed Wine image.

Required repository configuration:

- Secret `DOCKERHUB_USERNAME` — Docker Hub username (`caaarrrlll`).
- Secret `DOCKERHUB_TOKEN` — Docker Hub access token with Read & Write scope,
  not the account password.

Keep `DOCKERHUB_USERNAME` scoped to this repository. It replaces the namespace
in the CI tags, while the Dockerfiles still use `FROM caaarrrlll/...` on
purpose so the chain builds on the published base images.

## Phase 6 — Push and verify

**Status:** the monorepo has been pushed to `origin/main`. CI and published
image verification are still pending.

```powershell
cd E:\Code\carl-gaming-dockers
git add -A
git commit -m "chore: import image repositories into monorepo"
git push -u origin main
```

Verify:

- The `Build and push images` workflow passes.
- `docker pull` of each tag returns the expected image.
- The Unraid container still starts with the published `caaarrrlll/asa-wine:latest`.

## Phase 7 — Retire the old repositories

**Status:** pending, blocked on a successful CI run and image verification.

After the monorepo is confirmed working:

- Add a note to each old repo's README: "Moved to `Caaarrrlll/carl-gaming-dockers`".
- Optionally archive the old repos in GitHub settings.
- Keep the old tags/releases until dependent deployments have migrated.

## Phase 8 — Future: group images into `systems/` and `games/`

**Status:** proposal, not scheduled. Do this after CI is green.

As more game images are added, split runtime bases from game workloads:

```
images/
├─ systems/
│  ├─ debian-base/
│  ├─ fedora-base/
│  └─ wine-base/
└─ games/
   └─ asa-docker/
```

This makes the dependency chain clearer (`systems` builds the runtime that
`games` layers on) and makes the repo easier to grow without scanning a flat
`images/` directory. The Dockerfiles reference published image tags, not
relative paths, so the build graph itself does not change.

Perform the move as one atomic commit and update every path reference:

- `scripts/docker-updater.sh` and `.bat` build contexts.
- `dockers.code-workspace` folder paths.
- `.github/workflows/build-images.yml` contexts and `paths-filter` patterns.
- `README.md`, `AGENTS.md`, and per-image `audit.md` paths.

Do not mix the move with content changes; that makes the history harder to
follow.

## Next steps

1. Run `Build and push images` manually once and confirm the full chain passes
   (repository secrets are now configured).
2. Push a small change under `images/debian-base/` and confirm CI rebuilds
   debian → wine → asa only.
3. Verify the Unraid container still starts from `caaarrrlll/asa-wine:latest`.
4. Retire the old repositories (Phase 7).
5. Consider the `systems/` + `games/` reorganisation (Phase 8).
6. Re-enable automatic Fedora CI when the image is actively used again
   (`build_fedora` currently defaults to `false` to save Actions job time).

## Alternatives

- **Keep separate repos:** use `git submodule` from a thin root repo. Lower
  migration effort, but builds and changes still span four repositories.
- **Fresh history:** copy the folders into a new repo without `git subtree`.
  Simplest, but loses per-image commit history.

## Rollback

The `E:\Code\dockers-backup` copy and the untouched original remotes are the
rollback path. Do not force-push or delete the original repositories until the
monorepo is confirmed.
