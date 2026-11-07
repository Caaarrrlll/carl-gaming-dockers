# Monorepo Migration Plan

Goal: consolidate the four image repositories under this folder into a single
GitHub monorepo, `carl-gaming-dockers`, while keeping the existing Docker Hub
images and build flow working.

## Current state

| Path | Remote | Image |
|---|---|---|
| `docker-debian-baseimage/` | `Caaarrrlll/docker-debian-baseimage` | `caaarrrlll/debian-slim-baseimage:trixie-latest` |
| `docker-fedora-baseimage/` | `Caaarrrlll/docker-fedora-baseimage` | `caaarrrlll/fedora-baseimage:latest` (assumed) |
| `wine-baseimage/` | `Caaarrrlll/wine-baseimage` | `caaarrrlll/wine-baseimage:latest` |
| `docker-steamcmd/` | `Caaarrrlll/docker-steamcmd` | `caaarrrlll/asa-wine:latest` |

Each path is currently an independent git repository. The workspace root is not
a git repository.

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

Create a new GitHub repository (`carl-gaming-dockers`) and lay it out as:

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
│  └─ docker-updater.bat
├─ .gitignore
├─ AGENTS.md
├─ README.md
└─ dockers.code-workspace
```

Dockerfiles reference published image tags (`caaarrrlll/...`), not relative
paths, so moving folders does not change the build graph.

## Phase 3 — Create the monorepo and preserve history

`git subtree` keeps each repo's commit history under a subdirectory.

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

Replace the local `docker-updater.bat` for releases with CI. The chain must build
in dependency order (debian → wine → asa-docker); Fedora is independent.

`.github/workflows/build-images.yml` (skeleton):

```yaml
name: Build and push images

on:
  push:
    branches: [main]
    tags: ["v*"]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Debian base
        uses: docker/build-push-action@v6
        with:
          context: images/debian-base
          push: true
          tags: caaarrrlll/debian-slim-baseimage:trixie-latest

      - name: Fedora base
        uses: docker/build-push-action@v6
        with:
          context: images/fedora-base
          push: true
          tags: caaarrrlll/fedora-baseimage:latest

      - name: Wine base
        uses: docker/build-push-action@v6
        with:
          context: images/wine-base
          pull: true
          push: true
          tags: caaarrrlll/wine-baseimage:latest

      - name: ASA Docker / ARK ASA
        uses: docker/build-push-action@v6
        with:
          context: images/asa-docker
          pull: true
          push: true
          tags: caaarrrlll/asa-wine:latest
```

Add repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (Docker Hub
access token, not the account password). The `pull: true` on dependent images
ensures CI uses the just-pushed base images.

## Phase 6 — Push and verify

```powershell
cd E:\Code\carl-gaming-dockers
git add -A
git commit -m "chore: import image repositories into monorepo"
git push -u origin main
```

Verify:

- All four workflows' build steps pass.
- `docker pull` of each tag returns the expected image.
- The Unraid container still starts with the published `caaarrrlll/asa-wine:latest`.

## Phase 7 — Retire the old repositories

After the monorepo is confirmed working:

- Add a note to each old repo's README: "Moved to `Caaarrrlll/carl-gaming-dockers`".
- Optionally archive the old repos in GitHub settings.
- Keep the old tags/releases until dependent deployments have migrated.

## Alternatives

- **Keep separate repos:** use `git submodule` from a thin root repo. Lower
  migration effort, but builds and changes still span four repositories.
- **Fresh history:** copy the folders into a new repo without `git subtree`.
  Simplest, but loses per-image commit history.

## Rollback

The `E:\Code\dockers-backup` copy and the untouched original remotes are the
rollback path. Do not force-push or delete the original repositories until the
monorepo is confirmed.
