# navigaite/.github

The special `.github` repository of the [Navigaite](https://github.com/navigaite) organization.

## Contents

| Path                     | Purpose                                                                  |
| ------------------------ | ------------------------------------------------------------------------ |
| `profile/README.md`      | The public organization profile shown on <https://github.com/navigaite>. |
| `.github/dependabot.yml` | Weekly grouped GitHub Actions updates for this repository.               |
| `.github/CODEOWNERS`     | Code-owner rules for this repository.                                    |
| `.github/workflows/`     | This repository's own pipeline caller (`ci.yaml`).                       |

## CI/CD

This repository used to host the "Universal Pipeline v2" — a reusable workflow, composite actions and release-please
automation. That pipeline is gone. CI/CD for every Navigaite repository now runs on
[`maxbec/pipeline`](https://github.com/maxbec/pipeline), called SHA-pinned from each repository's
`.github/workflows/ci.yaml` and configured in its `.github/pipeline.yaml`. Versions, Release PRs, tags and GitHub
releases are managed by Flaiky. See `maxbec/pipeline` for the pipeline's documentation.

## Contributing

Branch off `dev` and target `dev`, with a conventional PR title and signed commits. See [AGENTS.md](./AGENTS.md).
