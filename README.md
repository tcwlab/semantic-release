# tcwlab/semantic-release

> Semantic versioning and release automation for Forgejo-based CI/CD pipelines. Bundles [semantic-release](https://semantic-release.gitbook.io/) 25.0.3 with Forgejo-compatible plugins and pre-configured defaults. Drop this image into your release workflow, point it at a `.releaserc` config, and get fully automated SemVer tags and releases from Conventional Commits.

[![Docker Pulls](https://img.shields.io/docker/pulls/tcwlab/semantic-release?label=pulls)](https://hub.docker.com/r/tcwlab/semantic-release)
[![Image Size](https://img.shields.io/docker/image-size/tcwlab/semantic-release/latest?label=size)](https://hub.docker.com/r/tcwlab/semantic-release/tags)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

---

## Quick start

```bash
docker pull tcwlab/semantic-release:latest
```

Or as a Forgejo container job:

```yaml
release:
  runs-on: ubuntu-22.04
  needs: [lint, build]
  if: github.ref == 'refs/heads/main'
  container:
    image: tcwlab/semantic-release:latest
  env:
    GH_TOKEN: ${{ secrets.FORGEJO_TOKEN }}
    GITHUB_URL: https://forgejo.example.com
    GITHUB_API_URL: https://forgejo.example.com/api/v1/
  steps:
    - uses: https://data.forgejo.org/actions/checkout@v4
      with: { fetch-depth: 0 }
    - run: semantic-release
```

That's it. The image runs `semantic-release` with no additional configuration required, provided you have a `.releaserc` in the repo root.

> Quick-start examples use `:latest` so you can try the image immediately. For
> production CI pipelines, pin a concrete `<upstream>-<wrapper>` tag — see
> [Tag pattern](#tag-pattern) below.

---

## Tag pattern

This image follows a three-tier tag scheme that wraps an upstream version:

- `<upstream>` — e.g. `25.0.3`. Tracks the upstream
  [semantic-release](https://github.com/semantic-release/semantic-release)
  release this image is built on. Use when you want the freshest
  wrapper-of-this-upstream and don't care about the wrapper patch level.
- `<upstream>-<wrapper>` — e.g. `25.0.3-1.0.0`. Pins both the upstream
  and the tcwlab wrapper version. Use in CI configs where determinism
  matters more than freshness.
- `latest` — always points to the latest `<upstream>-<wrapper>`. Use only
  for ad-hoc local runs.

For the current set of tags, see
[Docker Hub tags](https://hub.docker.com/r/tcwlab/semantic-release/tags).

**Always pin a concrete `<upstream>-<wrapper>` tag in production.** A bare
`<upstream>` tag still moves when the wrapper gets a patch; only
`<upstream>-<wrapper>` is fully immutable.

---

## Supported architectures

- `linux/amd64`
- `linux/arm64`

Every tag is a multi-arch manifest list. Docker pulls the right architecture automatically.

---

## What's included

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | LTS (Alpine) | JavaScript runtime |
| [`semantic-release`](https://semantic-release.gitbook.io/) | `25.0.3` | Core release automation |
| [`@semantic-release/commit-analyzer`](https://github.com/semantic-release/commit-analyzer) | `13` | Parse Conventional Commits → SemVer bump type |
| [`@semantic-release/release-notes-generator`](https://github.com/semantic-release/release-notes-generator) | `14` | Generate changelog from commit history |
| [`@semantic-release/github`](https://github.com/semantic-release/github) | `11` | Create Forgejo releases and tags (GitHub-compatible API) |
| [`@semantic-release/exec`](https://github.com/semantic-release/exec) | `6` | Write version to file (`.NEXT_RELEASE_VERSION`) |
| `picomatch` | `4.0.4` | Pinned dependency (deduplication for plugin compatibility) |

Base image: `node:lts-alpine`. Default workdir: `/repo`. Default user: `semrel` (non-root).

---

## Usage

### Standard release workflow (Forgejo)

Production CI pipeline — pin a concrete `<upstream>-<wrapper>` tag for reproducibility:

```yaml
release:
  name: Release
  runs-on: ubuntu-22.04
  needs: [lint, build-test]
  if: github.ref == 'refs/heads/main'
  container:
    image: tcwlab/semantic-release:25.0.3-1.0.0
  env:
    GH_TOKEN: ${{ secrets.FORGEJO_TOKEN }}
    GITHUB_URL: https://forgejo.example.com
    GITHUB_API_URL: https://forgejo.example.com/api/v1/
  steps:
    - uses: https://data.forgejo.org/actions/checkout@v4
      with: { fetch-depth: 0 }
    - run: semantic-release
```

The key environment variables:

| Variable | Purpose |
|----------|---------|
| `GH_TOKEN` | API token from `secrets.FORGEJO_TOKEN` (used by `@semantic-release/github`) |
| `GITHUB_URL` | Forgejo instance URL; e.g., `https://forgejo.example.com` |
| `GITHUB_API_URL` | Forgejo API base URL; e.g., `https://forgejo.example.com/api/v1/` |
| `GIT_AUTHOR_NAME` | Committer name for release commits (optional; defaults to `Semantic Release Bot`) |
| `GIT_AUTHOR_EMAIL` | Committer email for release commits (optional) |
| `GIT_COMMITTER_NAME` | Alternative to `GIT_AUTHOR_NAME` |
| `GIT_COMMITTER_EMAIL` | Alternative to `GIT_AUTHOR_EMAIL` |

---

## Configuration

### `.releaserc` template for consumer repos

```yaml
branches:
  - main

plugins:
  - "@semantic-release/commit-analyzer"
  - "@semantic-release/release-notes-generator"
  - - "@semantic-release/github"
    - apiUrl: "https://forgejo.example.com/api/v1/"
      baseUrl: "https://forgejo.example.com"
      # Forgejo does not have GraphQL — disable PR/issue comment features
      successComment: false
      failComment: false
      failTitle: false
      labels: false
      releasedLabels: false
  - - "@semantic-release/exec"
    - verifyReleaseCmd: "echo ${nextRelease.version} > .NEXT_RELEASE_VERSION"
```

Place this `.releaserc` (or `.releaserc.json`, `.releaserc.yaml`) at your repo root. The `@semantic-release/github` plugin drives tag creation and Forgejo release publishing. The `@semantic-release/exec` plugin writes the next version to a file that subsequent jobs can read.

### Output: `.NEXT_RELEASE_VERSION`

After semantic-release runs, the verifyReleaseCmd writes the version string (e.g., `1.2.3`) to `.NEXT_RELEASE_VERSION`. Downstream build jobs can read this to tag Docker images, binaries, or other artifacts:

```yaml
  tag-image:
    runs-on: ubuntu-22.04
    needs: release
    steps:
      - uses: https://data.forgejo.org/actions/checkout@v4
      - run: |
          VERSION=$(cat .NEXT_RELEASE_VERSION)
          docker tag myimage:latest myregistry/myimage:"${VERSION}"
```

---

## How it works

1. **Checkout** with full history (`fetch-depth: 0`) — semantic-release needs to analyze all commits since the last tag.
2. **Conventional Commits parsing** — the commit-analyzer plugin reads commit messages and determines if the next release is a patch, minor, or major bump.
3. **Tag creation** — the GitHub plugin (which speaks Forgejo's GitHub-compatible API) creates a tag and a release object in Forgejo.
4. **Version export** — the exec plugin writes the computed version to `.NEXT_RELEASE_VERSION`.

---

## Known issues / caveats

- **Forgejo API compatibility** — This image uses `@semantic-release/github` (GitHub-compatible API). If Forgejo introduces breaking changes to its API, the fallback is to use `@saithodev/semantic-release-gitea` (not included in this image; consumer repos would need to install it at runtime or build a custom variant).
- **Initial bootstrap** — Fresh repos with no tags: semantic-release does nothing on the first run. Solution: manually create a `v0.0.0` tag or start with a `feat: initial release` commit.
- **Detached HEAD** — Container jobs run in detached HEAD mode. Always use `fetch-depth: 0` in the checkout step so semantic-release can analyze the full history.
- **picomatch pinning** — The image pins `picomatch@4.0.4` to avoid conflicts between nested dependencies. If you upgrade semantic-release or its plugins, verify that this deduplication is still necessary.

---

## Source, issues, contributing

- **Source**: [`github.com/tcwlab/semantic-release`](https://github.com/tcwlab/semantic-release)
- **Issues / feature requests**: [`github.com/tcwlab/semantic-release/issues`](https://github.com/tcwlab/semantic-release/issues)
- **Docker Hub**: [`hub.docker.com/r/tcwlab/semantic-release`](https://hub.docker.com/r/tcwlab/semantic-release)

---

## Build, supply chain

Every release is built and published by the repo's own [`.forgejo/workflows/ci.yml`](https://github.com/tcwlab/semantic-release/blob/main/.forgejo/workflows/ci.yml) on a Forgejo runner:

- Multi-arch build (`linux/amd64`, `linux/arm64`) via `docker buildx` with `--sbom=true --provenance=mode=max`.
- Trivy vulnerability scan on `HIGH`/`CRITICAL` severity (failures show up as PR comments).
- Self-lint via `betterlint` running against the repo.

The semantic-release wrapper SemVer is cut by `semantic-release` itself from Conventional Commits on `main`.

---

## License

Apache License 2.0. See [`LICENSE`](LICENSE) for the full text.
