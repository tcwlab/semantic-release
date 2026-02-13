#####
# STEP 1: build base image
#####
FROM node:current-alpine@sha256:b9b5737eabd423ba73b21fe2e82332c0656d571daf1ebf19b0f89d0dd0d3ca93 AS base
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
