# ⚡ Quick Setup Guide

**5-minute guide to get your repository working with Universal Pipeline v2**

---

## 📋 Prerequisites

- GitHub repository with `main` and `dev` branches
- Admin access to the repository

---

## 🚀 Step-by-Step Setup

### 1️⃣ Configure Branch Protection (2 min)

**Main Branch:**

```
Settings → Branches → Add rule
Branch: main

✅ Require a pull request before merging
   ✅ Require 1 approval
✅ Require status checks to pass
   ✅ Require branches to be up to date
   Required checks: setup, lint, test, build
✅ Require conversation resolution
✅ Allow specified actors to bypass (add: github-actions[bot])
```

**Dev Branch:**

```
Settings → Branches → Add rule
Branch: dev

✅ Require a pull request before merging
   ✅ Require 1 approval
✅ Require status checks to pass
   Required checks: setup, lint, test, build
✅ Allow specified actors to bypass (add: github-actions[bot])
```

### 2️⃣ Set Workflow Permissions (1 min)

```
Settings → Actions → General → Workflow permissions

⚙️ Select: "Read and write permissions"
✅ Check: "Allow GitHub Actions to create and approve pull requests"
```

### 3️⃣ Add Secrets (1 min)

```
Settings → Secrets and variables → Actions → New repository secret
```

**For Vercel:**

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

**For DigitalOcean:**

- `DIGITALOCEAN_TOKEN`

**For Docker:**

- `DOCKER_REGISTRY_USERNAME`
- `DOCKER_REGISTRY_PASSWORD`

### 4️⃣ Create Environments (1 min)

```
Settings → Environments
```

Create three environments:

1. **preview** - No protection
2. **staging** - Deployment branches: `dev`
3. **production** - Deployment branches: `main`, Require 1 reviewer

### 5️⃣ Add Pipeline Configuration

Create `.github/workflows/ci.yaml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

permissions:
  contents: write
  pull-requests: write
  deployments: write

jobs:
  pipeline:
    uses: navigaite/github-organization/.github/workflows/universal-pipeline.yaml@main
    with:
      config-file: .github/pipeline.yaml
    secrets: inherit
```

Create `.github/pipeline.yaml`:

```yaml
version: '2.0'

deployment:
  provider: vercel # or digitalocean, docker
  environments:
    - name: preview
      trigger:
        event: pull_request
    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
  type: node # or python, simple
  sync_to_dev: true
```

### 6️⃣ Test It!

```bash
git checkout -b feat/test-pipeline
echo "test" >> README.md
git add README.md
git commit -m "feat: test universal pipeline"
git push origin feat/test-pipeline
gh pr create --base dev --title "feat: test pipeline"
```

Watch the Actions tab - all checks should run! ✅

---

## ✅ Verification Checklist

- [ ] Branch protection rules configured
- [ ] Workflow permissions set to "Read and write"
- [ ] Secrets added
- [ ] Environments created
- [ ] Pipeline config files committed
- [ ] Test PR created and checks passing

---

## 🆘 Common Issues

**"Protected branch update failed"** → Add `github-actions[bot]` to bypass list

**"Resource not accessible"** → Enable "Read and write permissions" in workflow settings

**"Secret not found"** → Check secret names match exactly (case-sensitive)

---

## 📚 Full Documentation

- [Complete GitHub Settings Guide](./GITHUB_SETTINGS_GUIDE.md)
- [Versioning Guide](./VERSIONING_GUIDE.md)
- [Configuration Reference](./CONFIGURATION.md)
- [Getting Started](./GETTING_STARTED.md)

---

**Need help?** Check the [GITHUB_SETTINGS_GUIDE.md](./GITHUB_SETTINGS_GUIDE.md) for detailed instructions.
