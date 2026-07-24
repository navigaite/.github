# Self-Hosted Runner (homelab)

Navigaite runs a self-hosted GitHub Actions runner on the Mainz homelab (Unraid)
so that the org's **private-repo** CI does not consume the board-set **$20/month**
GitHub Actions spending cap. This guide is the hardened, safe way to operate it.

> **Public repos never use this runner.** `navigaite/.github` and
> `navigaite/nvgt-trunk-plugin` are public; fork PRs can run arbitrary code.
> Untrusted code must not execute on the homelab. Public repos stay on
> GitHub-hosted `ubuntu-latest` (which is free for public repos anyway).

A ready-to-deploy Compose stack lives next to this file:
[`self-hosted-runner/docker-compose.yml`](./self-hosted-runner/docker-compose.yml).

## Why hardening was required

The legacy `gh-actions-runner` stack ran `myoung34/github-runner:latest` with:

| Legacy setting | Risk | Fix |
| --- | --- | --- |
| `privileged: true` + in-container Docker-in-Docker | Container escape → host root on the homelab | Drop `privileged`; disable in-container Docker; use rootless BuildKit only where image builds are needed |
| `image: ...:latest` | Unpinned — a compromised/moved tag silently changes what runs | Pin by digest (`@sha256:…`) |
| Repo-scoped, one container per repo | Doesn't scale to the fleet; each needs its own PAT | One **org-level runner group** (`homelab`) for all private repos |
| `docker` label advertised | Misleads jobs into scheduling Docker work on a daemonless runner | Fleet labels: `self-hosted, mainz-homelab, linux, x64` |

`jq` is baked into the myoung34 image and is intentionally kept — the pipeline's
Node lint/test/build steps depend on it (a missing `jq` silently no-ops those
steps to a false success; see the NAV-22 audit).

## Topology

Two ways to register, selected by Docker Compose profile in the stack file:

- **Option A — org runner group (preferred).** One runner group named `homelab`
  at the org level, access **limited to private repos**, serving every private
  navigaite repo. Requires an `ACCESS_TOKEN` (PAT) with **`admin:org`**.
  → `docker compose --profile org up -d`
- **Option B — repo-scoped (interim).** One container per opted-in private repo,
  registered with a `repo`-scope PAT. Mirrors the legacy topology, hardened.
  Use only until `admin:org` is available. → `docker compose --profile repo up -d`

### Prerequisite: `admin:org` for Option A

Creating an org runner group and reading Actions billing needs `admin:org`, which
the CTO `gh` token does **not** currently carry (`gist, read:org, repo, workflow`).
Grant it interactively:

```bash
gh auth refresh -s admin:org
```

or provision a scoped PAT (`admin:org`) in the runner's secret store as
`RUNNER_ORG_TOKEN`. This is a board/human step (interactive OAuth).

## Wiring a repo to the runner

Runners are matched by label. In a repo's `.github/pipeline.yaml`:

```yaml
runner:
  labels: [self-hosted, mainz-homelab, linux, x64]
```

This routes the `static-checks`, `verify` and `deploy-docker` jobs to the
homelab runner; it defaults to `ubuntu-latest` when omitted.

> **Gotcha — do not set self-hosted labels on a repo with no matching runner.**
> Jobs pinned to `self-hosted` labels queue **forever** if no runner is
> registered/authorized for that repo. Only add `runner.labels` after the repo
> is served by the org group (or has its own repo-scoped runner). Public repos
> keep the default (`ubuntu-latest`).

## Repos that build container images

Most of the fleet (Node/Vercel apps, npm libraries, the WP theme) build **no**
container image in CI, so the default runner runs with Docker disabled. Only a
repo whose `pipeline.yaml` sets `deployment.provider: docker` (the `deploy-docker`
job) needs to build images. Give those a **rootless BuildKit** sidecar
(`--profile docker` in the stack) and point the build at it — never re-enable
privileged dind.

## Operating notes

- Runners are `EPHEMERAL` — a fresh runner per job, no state carried across jobs.
- Recreate containers only when idle; an ephemeral runner mid-job will finish and
  deregister on its own.
- Keep the digest current deliberately (Dependabot/renovate on this file or a
  scheduled bump), not via `:latest`.
