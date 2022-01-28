#####
# STEP 1: build base image
#####
FROM alpine:3 AS base
RUN apk add -U --no-cache \
    nodejs-current=17.3.1-r0 \
    tini=0.19.0-r0 \
    git=2.34.1-r0	&& \
    ca-certificates=20211220-r0 && \
    bash=5.1.8-r0 && \
    rm -rf /var/cache/apk/*
# set working directory
WORKDIR /root/semantic-release
# Set tini as entrypoint
ENTRYPOINT ["/sbin/tini", "--"]

#####
# STEP 2: install dependencies
#####
FROM base AS dependencies
RUN npm set progress=false && npm config set depth 0
RUN npm install -g semantic-release@17.3.9 @semantic-release/gitlab@6.0.9 @semantic-release/exec@5.0.0

#####
# STEP 3: build production image
#####
FROM base AS release
COPY --from=dependencies /root/semantic-release/node_modules ./node_modules
CMD ["bash"]
