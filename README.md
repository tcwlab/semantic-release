# `semantic-release`

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

Of course, you need a project to release ;-)

In the following steps we only focus at the _usage_ of
[`tcwlab/semantic-release`](https://hub.docker.com/r/tcwlab/semantic-release).

### Step 1: `.gitlab-ci.yml`

For a full working example, please have a look at
[TBD](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/).

This is a snippet for your `.gitlab-ci.yml`:

```yaml
semantic-release:
  stage: release
  image: tcwlab/semantic-release:1.0
  script:
    - semantic-release
  only:
    refs:
      - main #because we only want to release something, that is finished
  except:
    - tags # because we don't want to build again, once the tag is written
```

If you are unsure how to embed, have a look at [this working example]().

### Step 2: `.releaserc`

As this Getting Started Guide is not taking care of any extra config, we start
as lean as we can:

```yaml
plugins:
- "@semantic-release/commit-analyzer"
- "@semantic-release/release-notes-generator"
- "@semantic-release/gitlab"
branches:
- "main"
```

As you perhaps can imagine, it will do four things on the `main` branch:

 1. Analyse your commit messages to detect changes (if & kind of)
 2. Generate release notes using the commit analyse result
 3. Publish the release to the [Release Notes](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/releases) page in GitLab
 4. Create a Git tag with the semantic version you've created

If you want to see a real world example, please [have a look here](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/blob/main/.releaserc).

### Step 3: Pipeline run

No, it's not just about triggering a pipeline. You also have to do some configuration stuff.

In order to let `semantic-release` know which credentials to use, you have to generate an Access Token:

 - by creating a [project access token](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html)
 - by creating a [group access token](https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html)
 - by creating a [personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)

> **_ℹ️ Info:_**  Depends on your GitLab tier. Maybe only the personal access token is available for you.

Make your token available as `GITLAB_TOKEN` environment variable ([see also `semantic-release` documentation](https://semantic-release.gitbook.io/semantic-release/usage/ci-configuration#authentication)).

When you now commit something with these messages, the `semantic-release` will do the rest for you:

 - `BREAKING CHANGE [...]` will create a new major release (e.g. 1.2.4 -> 2.0.0)
 - `feat(some-feature): [...]` is treated as feature release (e.g. 1.2.4 -> 1.3.0)
 - `fix(some-bug): [...]` is intended to create a patch release (e.g. 1.2.4 -> 1.2.5)

Of course a lot of things can be adjusted to your needs. For detailed information please have a look at the [official documentation of `semantic-release`](https://semantic-release.gitbook.io/).

## Roadmap
If you are interested in the upcoming/planned features, ideas and milestones,
please have a look at our [board](https://gitlab.com/tcwlab.com/saas/baseline/images/semantic-release/-/boards).

## License
This project is licensed under [Apache License v2](./LICENSE).

## Project status

This project is maintained "best effort", which means, we strive for automation as much as we can
A lot of updates will be done "automagically".

We do **not** have a specific dedicated set of people to work on this project.

It absolutely comes with **no warranty**.
