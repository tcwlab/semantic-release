# `semantic-release`

> **_⚠️ PRE-ALPHA:_**
> This project has not reached any usability status yet.
>
> **Please do not use unless you know what you're doing!**


## tl;dr

This image is used to support the release process using semantic versioning.
As this project is just _wrapping_ the `semantic-release` tool (for GitLab usage),
you will not find many details about the usage of this tool, but only how to use this image.

## Quick reference

- **Maintained by:** [Sascha Willomitzer](https://thechameleonway.com) [(of the TCWlab project)](https://gitlab.com/sascha_willomitzer)
- **Where to get help:** [file an issue](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/issues)
- **Supported architectures:** linux/amd64
- **Published image artifact details:** [see source code repository](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/tree/main)
- **Documentation:** For `semantic-release` you can find the official documentation at [semantic-release.gitbook.io](https://semantic-release.gitbook.io/semantic-release/)

## Getting started

This docker image is intended to be used as a part of a CI/CD pipeline. It is based on the official
[Node library image](https://hub.docker.com/_/node) and the [semantic release project](https://github.com/semantic-release).

As we only use this image as part of our GitLab pipelines, this is the configuration you could use.

The folder structure is very lean:

```bash
.
├── .gitlab-ci.yml
├── .releaserc
├── YOUR_CODE_STUFF
```

First of all, you need a project to release.

In the following steps we only focus at the _usage_ of
[`tcwlab/semantic-release`](https://hub.docker.com/r/tcwlab/semantic-release).

### Step 1: `.gitlab-ci.yml`

For a full working example, please have a look at
[TBD](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/).

This is a snippet for your `.gitlab-ci.yml`:

```yaml
TBD
```

### Step 2: `.releaserc`

As this Getting Started Guide is not taking care of any extra config, we start
as lean as we can:

```yaml
plugins:
- "@semantic-release/commit-analyzer"
- "@semantic-release/release-notes-generator"
- - "@semantic-release/exec"
- verifyReleaseCmd: "echo ${nextRelease.version} > .VERSION"
- "@semantic-release/gitlab"
branches:
- "main"
```

If you want to see a real world example, please [have a look here](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/blob/main/.releaserc).

### Step 3: Pipeline run

TBD

## Roadmap
If you are interested in the upcoming/planned features, ideas and milestones,
please have a look at our [board](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/boards).

## License
This project is licensed under [Apache License v2](./LICENSE).

## Project status

> **_⚠️ PRE-ALPHA:_**  This project has not reached any usability status yet.
> Please only use if you know what you're doing!

This project is maintained "best effort", which means, we strive for automation as much as we can
A lot of updates will be done "automagically".

We do **not** have a specific dedicated set of people to work on this project.

It absolutely comes with **no warranty**.
