#####
# STEP 1: build base image
#####
FROM node:current-alpine@sha256:18e02657e2a2cc3a87210ee421e9769ff28a1ac824865d64f74d6d2d59f74b6b AS base
RUN apk add -U --no-cache \
    git \
    git-lfs \
    ca-certificates \
    bash && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

#####
# STEP 2: install dependencies
#####
FROM base AS dependencies
RUN npm set progress=false && npm config set depth 0 && \
    npm install -g semantic-release @semantic-release/gitlab @semantic-release/exec

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/semantic-release/bin/semantic-release.js /usr/local/bin/semantic-release
CMD ["bash"]
