# semantic-release — Repo context

> **Onboarding handshake:** Read in this order:
> 1. [`Projects/CLAUDE.md`](https://git.mon.k8b.co/) (global standards)
> 2. [`tcwlab/CLAUDE.md`](https://git.mon.k8b.co/tcwlab/) (toolchain context)
> 3. This file (semantic-release-specific details)

---

## What is `semantic-release`?

`semantic-release` is the container image wrapper repo that ships [semantic-release](https://semantic-release.gitbook.io/) CLI plus TCW's own Forgejo-compatible plugin configuration. Consumers use it as a release job in their `ci.yml`/`release.yml` workflows: after successful CI on `main`, the tool analyzes Conventional Commits since the last tag, derives the next SemVer, generates release notes, and creates a tag plus Forgejo release plus optionally a container tag.

Image wrapping is necessary because semantic-release is a Node CLI with many plugins — we don't want each consumer repo to run `npm install` with erratic lockfiles, nor for plugin versions to drift across the organization. Instead: pinned semantic-release version plus pinned plugin versions in a single image, done.

### Consumers

All TCW repos that need SemVer tags and Forgejo releases — effectively, almost all of them. Pattern: a `release` job in `.forgejo/workflows/ci.yml` (or a separate `release.yml` workflow) that uses `tcwlab/semantic-release:<version>` as the `container:` image.

---

## What's in it?

[Dockerfile](https://git.mon.k8b.co/tcwlab/semantic-release/src/branch/main/Dockerfile):

- **Stage 1 — `base`**: `node:lts-alpine` with `apk add git git-lfs ca-certificates curl bash`. `apk upgrade`.
- **Stage 2 — `deps`**: `npm install -g` of the pinned plugin set:
  - `semantic-release@25.0.3`
  - `@semantic-release/commit-analyzer@13`
  - `@semantic-release/release-notes-generator@14`
  - `@semantic-release/github@11` (Forgejo has a GitHub-compatible API)
  - `@semantic-release/exec@6`
  - `picomatch@4.0.4` (pin against a known plugin conflict)
- **Stage 3 — `release`**: copies `node_modules` from Stage 2, symlink to `/usr/local/bin/semantic-release`, non-root user `semrel`.

Important discipline in the `deps` stage: after `npm install`, nested `picomatch` copies are deleted from plugin subtrees. Background: two different picomatch versions in the tree previously caused the `commit-analyzer` plugin to parse `releaseRules` patterns inconsistently.

CMD: `semantic-release --help` (smoke-test default — consumers override with bare `semantic-release`, which starts the standard run).

---

## Tool versions and pinning strategy

The image has its **own SemVer as a wrapper version**, independent of the semantic-release CLI version. Background: if we bump only a plugin patch, that has nothing to do with semantic-release 25.0.3 itself, but the image is still new. A separate wrapper SemVer keeps this clean.

Image tag schema: `tcwlab/semantic-release:<wrapper-semver>`. Examples: `tcwlab/semantic-release:1.0.0`, `tcwlab/semantic-release:1.1.0`.

### Update discipline

- **Plugin patch bump**: wrapper patch bump.
- **Plugin minor bump**: wrapper minor bump.
- **semantic-release major bump**: wrapper major bump plus consumer outreach (major bumps previously introduced plugin incompatibilities with the GitHub plugin → Forgejo path).
- **Forgejo API incompatibility**: if Forgejo pushes an API change that breaks the `@semantic-release/github` plugin, the fallback is the `@saithodev/semantic-release-gitea` plugin (see consumer repos in tcwlab that use this plugin in their `.releaserc`).

---

## Release procedure

Self-hosting: the repo uses itself once it has been pushed with tag `1.0.0`. Before that: manual initial tag.

`.releaserc`: minimal — `commit-analyzer`, `release-notes-generator`, `@semantic-release/github`, `@semantic-release/exec`. Tag schema: `v<x.y.z>`.

Docker Hub push: `tcwlab/semantic-release:<x.y.z>` plus rolling `latest`. Multi-arch via Buildx.

---

## What to do when bumping versions

1. PR with `ARG SEMANTIC_RELEASE_VERSION` and/or the `npm install -g` plugin pins.
2. Run CI — smoke test (`semantic-release --help` should not crash).
3. **Ideally**: do a dry run against a test repo with fake commits (`semantic-release --dry-run` locally).
4. **Consumer outreach** for semantic-release major bumps: all consumer repos have `image: tcwlab/semantic-release:<version>` in their `release.yml`. Coordinate bumping these values across consumers.
5. Update `versions.yaml`.

---

## What explicitly does NOT belong in this image

- **Repo-specific `.releaserc` templates**. Consumer repos maintain their own `.releaserc` because plugin selection and branches vary per repo.
- **`@semantic-release/npm` plugin**. We don't publish npm packages as a release outcome — all outputs are container images or Forgejo tags. If a new TCW repo does want to publish npm packages, it can load the plugin temporarily via `npm install` in the job — but we'd prefer to build a separate `tcwlab/semantic-release-npm` variant.
- **Container push plugin**. Container tags are pushed in a separate build job after release-tag push (pattern from `templates/docker-image-ci.yml`), not in the semantic-release step itself. Clean separation of version logic and build logic.
- **Forgejo API token in the image**. Token comes at runtime from Forgejo repository secrets via the `GH_TOKEN` env var.
- **`gpg` for commit signing**. Currently we don't sign — `require_signed_commits: false` in branch protection. If that changes, `gpg` would be a candidate for the image, but preferably as a separate variant.

---

## Consumer snippets

### Standard release job

```yaml
release:
  name: Release
  runs-on: ubuntu-22.04
  needs: [lint, build-test]
  if: github.ref == 'refs/heads/main'
  container:
    image: tcwlab/semantic-release:1.0.0
  env:
    GH_TOKEN: ${{ secrets.FORGEJO_TOKEN }}
    GITHUB_URL: https://git.mon.k8b.co
    GITHUB_API_URL: https://git.mon.k8b.co/api/v1/
  steps:
    - uses: https://data.forgejo.org/actions/checkout@v4
      with: { fetch-depth: 0 }
    - run: semantic-release
```

### Example `.releaserc` (in consumer repo)

```yaml
branches:
  - main
plugins:
  - "@semantic-release/commit-analyzer"
  - "@semantic-release/release-notes-generator"
  - - "@semantic-release/github"
    - apiUrl: "https://git.mon.k8b.co/api/v1/"
      baseUrl: "https://git.mon.k8b.co"
  - - "@semantic-release/exec"
    - verifyReleaseCmd: "echo ${nextRelease.version} > .NEXT_RELEASE_VERSION"
```

`.NEXT_RELEASE_VERSION` is the TCW pattern for "semantic-release determines the version, a downstream build job reads it and tags the container image accordingly".

### Alternative plugin path (for API incompatibility)

```yaml
plugins:
  - "@semantic-release/commit-analyzer"
  - "@semantic-release/release-notes-generator"
  - - "@saithodev/semantic-release-gitea"
    - giteaUrl: "https://git.mon.k8b.co"
  - "@semantic-release/git"
```

(The `@saithodev/semantic-release-gitea` plugin is not pre-installed in the image — consumers would need to load it as `npm install` in the job or build their own image variant.)

---

## Known pain points / open issues

- **GitHub plugin against Forgejo**: works because Forgejo has a GitHub-compatible API. On Forgejo major updates with API breaks, this is fragile — fallback to `semantic-release-gitea` plugin.
- **picomatch pin**: currently `4.0.4` because a specific plugin set transitively pulled an inconsistent picomatch version. Always check whether the pin is still needed when updating plugins.
- **`@saithodev/semantic-release-gitea`** is not in the image; it's loaded at runtime in consumer `.releaserc`. Cleaner would be a separate `tcwlab/semantic-release-gitea` variant.
- **Detached HEAD mode** in `container:` jobs: semantic-release needs `fetch-depth: 0` in the checkout, else it sees only one commit. Consumer snippets should always emphasize this.
- **Initial tag bootstrap**: fresh repo with no tags — semantic-release does nothing on the first run. Solution: set an initial `v0.0.0` tag manually or start with a `feat: initial release` commit.
