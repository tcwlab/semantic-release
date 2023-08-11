#####
# STEP 1: build base image
#####
FROM node:lts-alpine@sha256:3482a20c97e401b56ac50ba8920cc7b5b2022bfc6aa7d4e4c231755770cf892f AS base
RUN apk add -U --no-cache \
    git \
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
