# semantic-release — Repo-Kontext

> **Onboarding-Handshake:** Lies in dieser Reihenfolge:
> 1. [`Projects/CLAUDE.md`](https://git.mon.k8b.co/) (globale Standards)
> 2. [`tcwlab/CLAUDE.md`](https://git.mon.k8b.co/tcwlab/) (Toolchain-Kontext)
> 3. Diese Datei (semantic-release-spezifisches)

---

## Was ist `semantic-release`?

`semantic-release` ist das Container-Image-Wrapper-Repo, das den [semantic-release](https://semantic-release.gitbook.io/)-CLI inkl. der TCW-eigenen Plugin-Konfiguration für Forgejo bereitstellt. Konsumenten verwenden es als Release-Job in ihren `ci.yml`/`release.yml`-Workflows: nach erfolgreichem CI auf `main` analysiert das Tool die Conventional-Commits seit dem letzten Tag, leitet die nächste SemVer ab, generiert Release Notes und erstellt Tag plus Forgejo-Release plus optional Container-Tag.

Das Image-Wrapping ist nötig, weil semantic-release ein Node-CLI mit zig Plugins ist — wir wollen weder dass jedes Konsumenten-Repo `npm install` mit erratischen Lockfiles fährt, noch dass die Plugin-Versionen über die Welt drift. Stattdessen: gepinnte semantic-release-Version + gepinnte Plugin-Versionen in einem Image, fertig.

### Konsumenten

Alle TCW-Repos, die SemVer-Tags und Forgejo-Releases brauchen — also faktisch fast alle. Pattern: `release`-Job in `.forgejo/workflows/ci.yml` (oder separater `release.yml`-Workflow), der `tcwlab/semantic-release:<version>` als `container:` nimmt.

---

## Was ist drin?

[Dockerfile](https://git.mon.k8b.co/tcwlab/semantic-release/src/branch/main/Dockerfile):

- **Stage 1 — `base`**: `node:lts-alpine` mit `apk add git git-lfs ca-certificates curl bash`. `apk upgrade`.
- **Stage 2 — `deps`**: `npm install -g` der gepinnten Plugin-Set:
  - `semantic-release@25.0.3`
  - `@semantic-release/commit-analyzer@13`
  - `@semantic-release/release-notes-generator@14`
  - `@semantic-release/github@11` (Forgejo hat eine GitHub-kompatible API)
  - `@semantic-release/exec@6`
  - `picomatch@4.0.4` (Pin gegen einen bekannten Plugin-Konflikt)
- **Stage 3 — `release`**: kopiert `node_modules` aus Stage 2, symlink auf `/usr/local/bin/semantic-release`, non-root user `semrel`.

Wichtige Disziplin im `deps`-Stage: nach `npm install` werden nested `picomatch`-Kopien aus den Plugin-Subtrees gelöscht. Hintergrund: zwei verschiedene picomatch-Versionen im Tree haben in der Vergangenheit dazu geführt, dass das `commit-analyzer`-Plugin die `releaseRules`-Patterns inkonsistent geparst hat.

CMD: `semantic-release --help` (Smoke-Default — Konsumenten überschreiben mit `semantic-release` ohne Args, was den Standard-Run startet).

---

## Tool-Versionen und Pinning-Strategie

Das Image hat eine **eigene SemVer als Wrapper-Version**, unabhängig von der semantic-release-CLI-Version. Hintergrund: Wenn wir nur einen Plugin-Patch bumpen, hat das nichts mit semantic-release-25.0.3 selbst zu tun, aber das Image ist trotzdem neu. Eigene Wrapper-SemVer trennt das sauber.

Image-Tag-Schema: `tcwlab/semantic-release:<wrapper-semver>`. Beispiele: `tcwlab/semantic-release:1.0.0`, `tcwlab/semantic-release:1.1.0`.

### Update-Disziplin

- **Plugin-Patch-Bump**: Wrapper-Patch-Bump.
- **Plugin-Minor-Bump**: Wrapper-Minor-Bump.
- **semantic-release-Major-Bump**: Wrapper-Major-Bump plus Konsumenten-Outreach (Major-Bumps brachten in der Vergangenheit Plugin-Inkompatibilitäten mit dem GitHub-Plugin → Forgejo-Pfad).
- **Forgejo-API-Inkompatibilität**: Falls Forgejo eine API-Änderung pusht, die `@semantic-release/github`-Plugin bricht, ist der Fallback der `@saithodev/semantic-release-gitea`-Plugin (siehe Konsumenten-Repos in tcwlab, die genau dieses Plugin im `.releaserc` haben).

---

## Release-Verfahren

Self-hostend: das Repo benutzt sich selbst, sobald es einmal mit Tag `1.0.0` gepusht ist. Vorher: manueller Initial-Tag.

`.releaserc`: minimal — `commit-analyzer`, `release-notes-generator`, `@saithodev/semantic-release-gitea` (Forgejo-spezifischer Plugin), `@semantic-release/git`. Tag-Schema: `v<x.y.z>`.

Docker-Hub-Push: `tcwlab/semantic-release:<x.y.z>` plus rolling `latest`. Multi-arch via Buildx.

---

## Was bei Versions-Bump zu tun ist

1. PR mit `ARG SEMANTIC_RELEASE_VERSION` und/oder den `npm install -g`-Plugin-Pins.
2. CI durchlaufen — Smoke-Test (`semantic-release --help` sollte nicht crashen).
3. **Idealerweise**: gegen einen Test-Repo mit fake-Commits einen Trockenlauf machen (`semantic-release --dry-run` lokal).
4. **Konsumenten-Outreach** bei semantic-release-Major-Bump: alle Konsumenten-Repos haben in ihrem `release.yml` ein `image: tcwlab/semantic-release:<version>`. Diese Werte koordiniert hochziehen.
5. `versions.yaml` aktualisieren.

---

## Was explizit NICHT in dieses Image gehört

- **Repo-spezifische `.releaserc`-Templates**. Konsumenten-Repos pflegen ihre eigene `.releaserc`, weil Plugin-Auswahl und Branches je nach Repo abweichen.
- **`@semantic-release/npm`-Plugin**. Wir publishen keine npm-Pakete als Outcome eines Releases — alle Outputs sind Container-Images oder Forgejo-Tags. Wenn ein neues TCW-Repo doch npm publishen will, kann es das Plugin temporär per `npm install` im Job nachladen — aber bevorzugt bauen wir dann einen eigenen `tcwlab/semantic-release-npm`-Variant.
- **Container-Push-Plugin**. Container-Tags werden im separaten Build-Job nach Release-Tag-Push gepusht (Pattern aus `templates/docker-image-ci.yml`), nicht im semantic-release-Step selbst. Saubere Trennung von Versions-Logik und Build-Logik.
- **Forgejo-API-Token im Image**. Token kommt zur Laufzeit aus Forgejo-Repository-Secrets via `GH_TOKEN`-Env.
- **`gpg` für Commit-Signing**. Aktuell signieren wir nicht — `require_signed_commits: false` in der Branch-Protection. Wenn das mal wechselt, wäre `gpg` ein Kandidat fürs Image, aber dann eher als separater Variant.

---

## Konsumenten-Snippets

### Standard-Release-Job

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

### Beispiel `.releaserc` (im Konsumenten-Repo)

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

`.NEXT_RELEASE_VERSION` ist das TCW-Pattern für „semantic-release ermittelt die Version, ein nachgelagerter Build-Job liest sie und tagged das Container-Image entsprechend".

### Alternativer Plugin-Pfad (bei API-Inkompatibilität)

```yaml
plugins:
  - "@semantic-release/commit-analyzer"
  - "@semantic-release/release-notes-generator"
  - - "@saithodev/semantic-release-gitea"
    - giteaUrl: "https://git.mon.k8b.co"
  - "@semantic-release/git"
```

(Der `@saithodev/semantic-release-gitea`-Plugin ist nicht im Image vorinstalliert — Konsumenten müssten ihn als `npm install` im Job nachladen oder einen eigenen Image-Variant bauen.)

---

## Bekannte Schmerzpunkte / offene Themen

- **GitHub-Plugin gegen Forgejo**: funktioniert, weil Forgejo eine GitHub-kompatible API hat. Bei Forgejo-Major-Updates mit API-Brüchen ist das fragil — Fallback auf `semantic-release-gitea`-Plugin.
- **picomatch-Pin**: aktuell `4.0.4`, weil ein bestimmtes Set Plugins eine inkonsistente picomatch-Version transitively zog. Bei Plugin-Updates immer prüfen, ob der Pin noch nötig ist.
- **`@saithodev/semantic-release-gitea`** ist nicht im Image, sondern wird in den Konsumenten-`.releaserc` zur Laufzeit geladen. Sauberer wäre ein eigener `tcwlab/semantic-release-gitea`-Variant.
- **`HEAD`-Detached-Mode** in `container:`-Jobs: semantic-release braucht `fetch-depth: 0` im Checkout, sonst sieht es nur einen Commit. Konsumenten-Snippets das immer betonen.
- **Initial-Tag-Bootstrap**: Frisches Repo ohne Tags — semantic-release tut nichts beim ersten Run. Lösung: manuelles `v0.0.0`-Tag setzen oder erste Commit mit `feat: initial release`.
