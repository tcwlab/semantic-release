# ─────────────────────────────────────────────────────────────────────────────
# tcwlab / semantic-release
#
# semantic-release with Forgejo support via @semantic-release/github.
# Forgejo has a GitHub-compatible API — release creation and tag push
# work directly with these env vars:
#
#   GH_TOKEN        → Forgejo API token (secrets.FORGEJO_TOKEN)
#   GITHUB_URL      → https://git.mon.k8b.co
#   GITHUB_API_URL  → https://git.mon.k8b.co/api/v1/
#
# Included plugins:
#   @semantic-release/commit-analyzer         → Conventional Commits → SemVer
#   @semantic-release/release-notes-generator → Changelog from commits
#   @semantic-release/github                  → Forgejo release + tag
#   @semantic-release/exec                    → Write version to file
#
# Docker tags: tcwlab/semantic-release:<semrel-version>-<wrapper-semver>
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
