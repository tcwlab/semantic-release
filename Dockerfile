# ─────────────────────────────────────────────────────────────────────────────
# tcwlab / semantic-release
#
# semantic-release mit Forgejo-Support via @semantic-release/github.
# Forgejo hat eine GitHub-kompatible API — Release-Erstellung und Tag-Push
# funktionieren direkt mit diesen Env-Vars:
#
#   GH_TOKEN        → Forgejo API-Token (secrets.FORGEJO_TOKEN)
#   GITHUB_URL      → https://git.mon.k8b.co
#   GITHUB_API_URL  → https://git.mon.k8b.co/api/v1/
#
# Enthaltene Plugins:
#   @semantic-release/commit-analyzer         → Conventional-Commits → SemVer
#   @semantic-release/release-notes-generator → Changelog aus Commits
#   @semantic-release/github                  → Forgejo Release + Tag
#   @semantic-release/exec                    → Version in Datei schreiben
#
# Docker-Tags: tcwlab/semantic-release:<semrel-version>-<wrapper-semver>
# ─────────────────────────────────────────────────────────────────────────────

ARG SEMANTIC_RELEASE_VERSION=25.0.3

FROM node:lts-alpine AS base
# hadolint ignore=DL3018
RUN apk add --no-cache \
    git \
    git-lfs \
    ca-certificates \
    curl \
    bash \
    && apk upgrade \
    && rm -rf /var/cache/apk/*

FROM base AS deps
ARG SEMANTIC_RELEASE_VERSION
RUN npm install -g \
    "semantic-release@${SEMANTIC_RELEASE_VERSION}" \
    "@semantic-release/commit-analyzer@13" \
    "@semantic-release/release-notes-generator@14" \
    "@semantic-release/github@11" \
    "@semantic-release/exec@6" \
    "picomatch@4.0.4" \
    && find /usr/local/lib/node_modules -mindepth 3 \
         -name "picomatch" -type d \
         -not -path "/usr/local/lib/node_modules/picomatch" \
         -exec rm -rf {} + \
    && npm cache clean --force

FROM base AS release
COPY --from=deps /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/semantic-release/bin/semantic-release.js \
          /usr/local/bin/semantic-release
RUN addgroup -S semrel && adduser -S semrel -G semrel
USER semrel
CMD ["semantic-release", "--help"]
