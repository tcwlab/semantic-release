#####
# STEP 1: build base image
#####
FROM node:lts-alpine@sha256:c785e617c8d7015190c0d41af52cc69be8a16e3d9eb7cb21f0bb58bcfca14d6b AS base
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
    npm install -g semantic-release@19.0.2 @semantic-release/gitlab@7.0.4 @semantic-release/exec@6.0.3

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/semantic-release/bin/semantic-release.js /usr/local/bin/semantic-release
CMD ["bash"]
