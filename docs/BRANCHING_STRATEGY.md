# Branching Strategy & Deployment Workflow

This document explains how the Universal Pipeline v2 works with your Git branching strategy and automates deployments.

## 🧭 Repo Profiles: Major vs Fast

Every navigaite repo declares a delivery **profile** in `.github/pipeline.yaml`
via the top-level `profile:` key (default `major`). Both profiles get
release-please versioning + release notes + GitHub Releases — they differ only
in branching and who ships production.

| | **Major** (`profile: major`) | **Fast** (`profile: fast`) |
| --- | --- | --- |
| Use for | Customer / production repos | Small, internal, non-customer (libs, templates, tooling) |
| Branches | `feature/*` → `dev` → `main` | `feature/*` → `main` |
| Feature merge | squash into `dev` | squash into `main` |
| Release channel | **beta** on `dev`, **stable** on `main` | **stable** on `main` only |
| `dev` → `main` promotion | **board only** (merge commit) | n/a (no `dev` branch) |
| Feature PR merge | CTO self-merge into `dev` | CTO self-merge into `main` (0 approvals) |
| Back-merge (`sync_to_dev`) | on (main → dev after release) | off (forced off by profile) |

**Always enforced on both profiles:** PR required into a protected branch,
signed commits, `Check Gate` + full pipeline green, squash-only feature merges.

**How Fast works with no `dev` branch:** the caller's `Branch Guard` allows a
PR into `main` when the repo has no `dev` branch, and the reusable pipeline
forces the main → dev back-merge off when `profile: fast`, so a stable release
never fails trying to push to a branch that doesn't exist. See
[`fast-library-pipeline.yaml`](../.github/config/examples/fast-library-pipeline.yaml)
for a complete Fast config; the sections below describe the **Major** flow.

## 📋 Recommended Branching Strategy (Major profile)

The pipeline is optimized for a **main/dev branching strategy** with optional feature branches:

```
main (production)
  ↑
  └─ dev (staging)
      ↑
      ├─ feature/auth
      ├─ feature/dashboard
      └─ fix/bug-123
```

### Branch Purposes

| Branch      | Environment  | Purpose                                | Auto-Deploy |
| ----------- | ------------ | -------------------------------------- | ----------- |
| `main`      | Production   | Stable, production-ready code          | ✅ Yes      |
| `dev`       | Staging      | Integration and pre-production testing | ✅ Yes      |
| `feature/*` | Preview (PR) | Feature development                    | ✅ On PR    |
| `fix/*`     | Preview (PR) | Bug fixes                              | ✅ On PR    |

## 🔄 Deployment Workflow

### 1. Feature Development

```bash
# Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push and create PR to dev
git push origin feature/new-feature
```

**What happens:**

- ✅ Security scan runs
- ✅ Lint and tests run
- ✅ Build executes
- ✅ **Preview deployment** created (accessible via PR comment)
- ✅ PR checks must pass before merge

### 2. Integration Testing (Dev/Staging)

```bash
# After PR approval, merge to dev
# (via GitHub UI or command line)
git checkout dev
git merge feature/new-feature
git push origin dev
```

**What happens:**

- ✅ Full CI pipeline runs
- ✅ **Staging deployment** to dev environment
- ✅ Integration tests run against staging
- ✅ Team can test before production

### 3. Production Release

```bash
# When ready for production, merge dev to main
git checkout main
git merge dev
git push origin main
```

**What happens:**

- ✅ Full CI pipeline runs
- ✅ **Production deployment** to main environment
- ✅ **Release PR created** (via release-please)
- ✅ **GitHub Release** created when release PR is merged
- ✅ Changelog automatically generated

## ⚙️ Configuration Examples

### Standard Main/Dev Strategy

```yaml
version: '2.0'

deployment:
  provider: vercel

  environments:
    # Preview for all PRs
    - name: preview
      trigger:
        event: pull_request
      auto_deploy: true

    # Staging for dev branch
    - name: staging
      trigger:
        event: push
        branch: dev
      auto_deploy: true

    # Production for main branch
    - name: production
      trigger:
        event: push
        branch: main
      auto_deploy: true

release:
  enable: true
  type: node
```

### Main-Only Strategy (Simple Projects)

```yaml
version: '2.0'

deployment:
  provider: vercel

  environments:
    # Preview for PRs
    - name: preview
      trigger:
        event: pull_request

    # Production for main
    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
```

### Multi-Branch Strategy (Complex Projects)

```yaml
version: '2.0'

deployment:
  provider: vercel

  environments:
    # Preview for all PRs
    - name: preview
      trigger:
        event: pull_request

    # Dev environment for develop branch
    - name: development
      trigger:
        event: push
        branch: develop

    # QA environment for release branches
    - name: qa
      trigger:
        event: push
        branches: [release/*, hotfix/*]

    # Staging for main
    - name: staging
      trigger:
        event: push
        branch: main

    # Production (manual only)
    - name: production
      trigger:
        event: workflow_dispatch
      auto_deploy: false
```

## 🔀 Git Workflow Best Practices

### 1. Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) for automatic changelog generation:

```
feat: add user authentication
fix: resolve login bug
docs: update API documentation
chore: update dependencies
refactor: simplify database queries
test: add unit tests for auth
perf: optimize image loading
```

**Impact on releases:**

- `feat:` → Minor version bump (1.0.0 → 1.1.0)
- `fix:` → Patch version bump (1.0.0 → 1.0.1)
- `feat!:` or `BREAKING CHANGE:` → Major version bump (1.0.0 → 2.0.0)

### 2. Pull Request Workflow

**Create PR:**

```bash
# Push feature branch
git push origin feature/my-feature

# Create PR via GitHub CLI
gh pr create --base dev --title "feat: my feature" --body "Description"
```

**What you get:**

- ✅ Automated checks (lint, test, build)
- ✅ Preview deployment with URL in PR comment
- ✅ Security scans
- ✅ Code coverage report

**Merge PR:**

- ✅ Only after all checks pass
- ✅ Prefer squash merge for clean history
- ✅ Use merge commit for feature branches with multiple logical commits

### 3. Release Workflow

The pipeline uses **release-please** for automated releases:

**How it works:**

1. Push to `main` branch
2. Release-please creates/updates a "Release PR"
3. Review the auto-generated changelog
4. Merge the Release PR when ready
5. GitHub Release is created automatically
6. Version numbers are bumped based on conventional commits

**Example Release PR:**

```markdown
## [1.2.0](https://github.com/org/repo/compare/v1.1.0...v1.2.0) (2025-12-07)

### Features

- add user authentication ([a1b2c3d](https://github.com/org/repo/commit/a1b2c3d))
- implement dashboard ([e4f5g6h](https://github.com/org/repo/commit/e4f5g6h))

### Bug Fixes

- resolve login redirect issue ([i7j8k9l](https://github.com/org/repo/commit/i7j8k9l))
```

## 🚨 Hotfix Workflow

For urgent production fixes:

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug

# Make fix and commit
git add .
git commit -m "fix: resolve critical security issue"

# Push and create PR to main
git push origin hotfix/critical-bug
gh pr create --base main --title "fix: critical security issue"
```

**After PR merge:**

```bash
# Backport to dev
git checkout dev
git cherry-pick <commit-hash>
git push origin dev
```

## 🎯 Environment URLs

Track your deployment URLs:

| Environment | Branch      | URL Pattern                  | Purpose             |
| ----------- | ----------- | ---------------------------- | ------------------- |
| Preview     | PR branches | `project-pr-123.vercel.app`  | PR testing          |
| Staging     | `dev`       | `project-staging.vercel.app` | Integration testing |
| Production  | `main`      | `project.com`                | Live users          |

## 📊 Deployment Status

Check deployment status:

```bash
# View deployment history
gh api repos/{owner}/{repo}/deployments

# View deployment status
gh api repos/{owner}/{repo}/deployments/{deployment_id}/statuses
```

## 🔒 Branch Protection Rules

Recommended settings for `main` and `dev` branches:

```yaml
# In repository settings → Branches
Protection Rules:
  - Require pull request reviews: ✅
  - Require status checks to pass: ✅
    - lint
    - test
    - build
    - security
  - Require branches to be up to date: ✅
  - Include administrators: ✅
  - Restrict pushes: ✅ (only from dev branch for main)
```

## 🎓 Tips & Best Practices

1. **Never push directly to main**: Always use PRs
2. **Keep dev up to date**: Regularly sync main → dev
3. **Small, focused PRs**: Easier to review and test
4. **Test in staging first**: Use dev branch for integration testing
5. **Use conventional commits**: Enables automatic versioning
6. **Review release PRs**: Check changelog before merging
7. **Tag releases**: Automatically done via release-please
8. **Monitor deployments**: Use GitHub Deployments tab

## 🆘 Troubleshooting

### Deployment not triggered

**Check:**

- ✅ Branch name matches configuration
- ✅ `auto_deploy: true` in environment config
- ✅ Required secrets are configured
- ✅ Previous pipeline steps passed

### Release PR not created

**Check:**

- ✅ Pushing to `main` branch
- ✅ `release.enable: true` in config
- ✅ Using conventional commit messages
- ✅ `GH_TOKEN` secret has write permissions

### Preview deployment URL not in PR comment

**Check:**

- ✅ `GH_TOKEN` or `GITHUB_TOKEN` is provided
- ✅ Token has `pull-requests: write` permission
- ✅ Deployment succeeded (check Actions tab)

---

**Next:** [Deployment Guide](./DEPLOYMENT.md)
