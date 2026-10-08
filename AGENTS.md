# AGENTS.md — navigaite/.github

Guidance for coding agents working in this repository. `CLAUDE.md` points here.

## What this repo is

The `navigaite` organization's special `.github` repository. It holds the org profile and org-wide defaults, nothing
else:

- `profile/README.md` — the public organization profile shown on <https://github.com/navigaite>.
- `.github/dependabot.yml` — weekly grouped `github-actions` updates for this repository.
- `.github/CODEOWNERS` — code-owner rules for this repository.
- `.github/workflows/ci.yaml` and `.github/pipeline.yaml` — this repository's own pipeline caller and its configuration
  (see the Pipeline section below).

It no longer hosts a CI/CD pipeline. The former "Universal Pipeline v2" (reusable workflow, composite actions,
release-please) was removed. CI/CD for every repository lives in [`maxbec/pipeline`](https://github.com/maxbec/pipeline)
(the reusable workflow, SHA-pinned by each caller), and versioning, Release PRs, tags, GitHub releases and backmerges
are done by Flaiky (`maxbec/flaiky`). Pipeline documentation — configuration, the self-hosted runner, org maintenance —
lives in `maxbec/pipeline/docs`.

## Working here

- Do not hand-edit `.github/workflows/ci.yaml` or the Pipeline section below; Flaiky renders both.
- Every commit is signed and uses a conventional message; PR titles are conventional too.
- Markdown follows Prettier with `printWidth` 120 and `proseWrap: always`, ending in exactly one newline.

<!-- pipeline:start -->

## Pipeline

CI is `maxbec/pipeline`, called SHA-pinned from `.github/workflows/ci.yaml`. Flaiky renders that caller and this section
(`provisioning/migrate-repos.ts` in `maxbec/flaiky`); never edit either by hand. Behaviour is configured only in
`.github/pipeline.yaml`.

- Three jobs: `Guard` enforces the branch rules and a conventional PR title; `Check` runs secret scan, lint, test and
  build and is the single required status (`pipeline / Check`); `Deploy` runs only on a published GitHub release
  (prerelease to `preview`, stable to `production`). Pushes never deploy.
- Branch off `dev` and target `dev`; squash merge. Never open a pull request against `main`: only `dev`, `promote/*`,
  `hotfix/*` and `release/*` enter `main`, and the promotion is Flaiky's.
- Conventional PR titles (`type(scope): summary`): the version is derived from them. Never edit a version, tag or
  changelog by hand; Flaiky keeps one Release PR per branch and merging it is the release.
- A pull request merges only when `pipeline / Check` is green, the head is signed and every review thread is resolved.
  Fix a red pipeline at the root; never weaken or skip a check.

<!-- pipeline:end -->
