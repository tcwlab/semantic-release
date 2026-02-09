#####
# STEP 1: build base image
#####
FROM node:current-alpine@sha256:c8d96e95e88f08f814af06415db9cfd5ab4ebcdf40721327ff2172ff25cfb997 AS base
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
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# This is a workaround for the currently outdated git-lfs in AlpineLinux repos, which is vulnerable to CVE-2025-26625
RUN apk add -U --no-cache coreutils curl && \
    export GIT_LFS_VERSION=$(curl -s 'https://api.github.com/repos/git-lfs/git-lfs/releases' | grep 'tag_name' | cut -d '"' -f 4 | sort -V | grep -v 'rc.' | tail -n 1) && \
    curl -Ls "https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/git-lfs-linux-amd64-${GIT_LFS_VERSION}.tar.gz" -o git-lfs.tgz && \
    tar xzf git-lfs.tgz && \
    mv git-lfs-${GIT_LFS_VERSION}/git-lfs /usr/bin/git-lfs && \
    chmod +rx /usr/bin/git-lfs
RUN npm set progress=false && npm config set depth 0 && \
    npm install -g semantic-release @semantic-release/gitlab @semantic-release/exec

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /usr/bin/git-lfs /usr/bin/git-lfs
COPY --from=dependencies /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/semantic-release/bin/semantic-release.js /usr/local/bin/semantic-release
CMD ["bash"]
