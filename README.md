# tcwlab/semantic-release

Docker Image mit [semantic-release](https://semantic-release.gitbook.io/) und Forgejo-Support für das chameleon-ci Ökosystem.

## Enthaltene Plugins

| Plugin | Zweck |
|---|---|
| `@semantic-release/commit-analyzer` | Conventional Commits → SemVer-Typ |
| `@semantic-release/release-notes-generator` | Changelog aus Commit-History |
| `@semantic-release/github` | Forgejo Release + Tag (GitHub-kompatible API) |
| `@semantic-release/exec` | Version in Datei schreiben (`.NEXT_RELEASE_VERSION`) |

## Verwendung in CI

```yaml
- name: semantic-release
  env:
    GH_TOKEN: ${{ secrets.FORGEJO_TOKEN }}
    GITHUB_URL: https://git.mon.k8b.co
    GITHUB_API_URL: https://git.mon.k8b.co/api/v1/
  run: |
    docker run --rm \
      -e GH_TOKEN -e GITHUB_URL -e GITHUB_API_URL \
      -v "$(pwd):/repo" -w /repo \
      tcwlab/semantic-release:latest
```

## .releaserc Vorlage

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

## Docker-Tags

| Tag | Bedeutung |
|---|---|
| `tcwlab/semantic-release:1.2.3` | Immutable Release |
| `tcwlab/semantic-release:latest` | Neueste Version |
