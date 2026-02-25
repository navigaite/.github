# Getting Started with Universal Pipeline v2

This guide will walk you through setting up the Universal CI/CD Pipeline v2 for your project in less than 5 minutes.

## 📋 Prerequisites

- GitHub repository
- One of the following tech stacks:
  - Node.js (Next.js, React, Vue, etc.)
  - Python (FastAPI, Django, Flask, etc.)
  - Flutter
- (Optional) Deployment account on Vercel, DigitalOcean, or Docker registry

## 🚀 5-Minute Setup

### Step 1: Create Workflow File (1 min)

Create `.github/workflows/ci.yaml` in your project:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  pipeline:
    uses: navigaite/github-organization/.github/workflows/v2/universal-pipeline.yaml@main
    with:
      config-file: .github/pipeline.yaml
    secrets: inherit
```

### Step 2: Create Configuration File (2 min)

Create `.github/pipeline.yaml` in your project.

Choose your template:

<details>
<summary><strong>Next.js + Vercel (Most Common)</strong></summary>

```yaml
version: '2.0'

deployment:
  provider: vercel

  environments:
    - name: preview
      trigger:
        event: pull_request

    - name: staging
      trigger:
        event: push
        branch: dev

    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
  type: node
```

</details>

<details>
<summary><strong>Python + DigitalOcean</strong></summary>

```yaml
version: '2.0'

stack: python

deployment:
  provider: digitalocean

  digitalocean:
    app_name: my-api

  environments:
    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
  type: python
```

</details>

<details>
<summary><strong>Flutter + Docker</strong></summary>

```yaml
version: '2.0'

stack: flutter

deployment:
  provider: docker

  docker:
    image_name: my-flutter-app
    registry: ghcr

  environments:
    - name: production
      trigger:
        event: push
        branch: main
```

</details>

<details>
<summary><strong>No Deployment (CI Only)</strong></summary>

```yaml
version: '2.0'

# This will run security, lint, test, and build
# No deployment configured
```

</details>

### Step 3: Add Secrets (2 min)

Go to your repository → Settings → Secrets and variables → Actions

Add the required secrets based on your deployment provider:

**For Vercel:**

1. Go to [Vercel Dashboard](https://vercel.com/account/tokens) → Settings → Tokens
2. Create a new token
3. Add to GitHub:
   - `VERCEL_TOKEN`: Your Vercel token
   - `VERCEL_ORG_ID`: Found in Vercel project settings
   - `VERCEL_PROJECT_ID`: Found in Vercel project settings

**For DigitalOcean:**

1. Go to [DigitalOcean API Tokens](https://cloud.digitalocean.com/account/api/tokens)
2. Generate new token with write access
3. Add to GitHub:
   - `DIGITALOCEAN_TOKEN`: Your DO token

**For Docker (using GHCR):**

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate token with `write:packages` scope
3. Add to GitHub:
   - `DOCKER_REGISTRY_PASSWORD`: Your GitHub token (or use default `GITHUB_TOKEN`)

**For Docker (using Docker Hub):**

1. Go to [Docker Hub Access Tokens](https://hub.docker.com/settings/security)
2. Create new access token
3. Add to GitHub:
   - `DOCKER_REGISTRY_USERNAME`: Your Docker Hub username
   - `DOCKER_REGISTRY_PASSWORD`: Your Docker Hub token

### Step 4: Commit and Push

```bash
git add .github/workflows/ci.yaml .github/pipeline.yaml
git commit -m "feat: add Universal Pipeline v2"
git push origin main
```

### Step 5: Watch the Magic! ✨

1. Go to your repository on GitHub
2. Click "Actions" tab
3. You should see your pipeline running!

The pipeline will:

- ✅ Auto-detect your tech stack
- ✅ Run security scans
- ✅ Lint your code
- ✅ Run tests
- ✅ Build your project
- ✅ Deploy to production (if on main branch)
- ✅ Create release PR (if enabled)

## 🎯 Next Steps

### Enable Release Automation

Add to your `.github/pipeline.yaml`:

```yaml
release:
  enable: true
  type: node # or python, simple
```

Now when you push to `main`, a Release PR will be created with:

- Automatic version bumping
- Generated changelog
- Release notes

Just merge the Release PR when you're ready to publish!

### Add Staging Environment

Update your environments in `.github/pipeline.yaml`:

```yaml
deployment:
  environments:
    - name: preview
      trigger:
        event: pull_request

    - name: staging # Add this
      trigger:
        event: push
        branch: dev

    - name: production
      trigger:
        event: push
        branch: main
```

Now:

- PRs → Preview deployment
- Pushes to `dev` → Staging deployment
- Pushes to `main` → Production deployment

### Customize Build/Test Commands

If auto-detection doesn't work, specify custom commands:

```yaml
lint:
  command: npm run lint:fix

test:
  command: npm run test:ci -- --coverage

build:
  command: npm run build:prod
```

### Enable Code Coverage

```yaml
test:
  coverage: true
```

Add `CODECOV_TOKEN` secret for private repos.

## 📚 Learn More

- **[Full Configuration Reference](./CONFIGURATION.md)** - All available options
- **[Branching Strategy](./BRANCHING_STRATEGY.md)** - How to use main/dev workflow
- **[Example Configurations](../../.github/config/v2/examples/)** - Real-world examples

## 🆘 Troubleshooting

### Pipeline not running

**Check:**

- Workflow file is in `.github/workflows/` directory
- File has `.yaml` or `.yml` extension
- Branch is listed in `on.push.branches` or `on.pull_request.branches`

### Auto-detection failed

Add explicit configuration:

```yaml
stack: nodejs # or python, flutter

runtime:
  node_version: '20' # or python_version, flutter_version
```

### Deployment not working

**Check:**

- Secrets are correctly named and added
- Secret values don't have extra spaces
- For Vercel: ORG_ID and PROJECT_ID are correct
- For DO: App name matches exactly
- For Docker: Registry credentials are valid

### Release PR not created

**Check:**

- Pushing to `main` branch
- `release.enable: true` in config
- Using [conventional commits](https://www.conventionalcommits.org/):
  - `feat:` for new features
  - `fix:` for bug fixes
  - `BREAKING CHANGE:` for breaking changes
- `GH_TOKEN` secret exists with `contents: write` permission

### Build failing

**Common issues:**

1. **Missing dependencies**: Ensure `package.json`, `requirements.txt`, or `pubspec.yaml` is committed
2. **Node version mismatch**: Add `.nvmrc` file or specify in config
3. **Environment variables**: Some builds need env vars - add them to secrets

**Debug:**

1. Check the Actions tab for detailed logs
2. Look for the red X to see which step failed
3. Click on the failed step to see error messages

## 💡 Pro Tips

1. **Start minimal**: Begin with just CI (no deployment), then add deployment later
2. **Use conventional commits**: Enables automatic versioning
3. **Test locally first**: Run `npm test`, `npm run build` locally before pushing
4. **Check Actions tab**: Monitor your pipeline runs
5. **Read the logs**: Error messages are usually very helpful

## 🎓 Common Workflows

### Creating a Feature

```bash
git checkout dev
git pull origin dev
git checkout -b feature/awesome-feature

# Make changes
git add .
git commit -m "feat: add awesome feature"

# Push and create PR to dev
git push origin feature/awesome-feature
gh pr create --base dev
```

**What happens:**

- ✅ Pipeline runs on PR
- ✅ Preview deployment created
- ✅ URL posted in PR comment
- ✅ Can merge after checks pass

### Deploying to Staging

```bash
# Merge feature PR to dev
# Then push dev
git checkout dev
git pull origin dev
git push origin dev
```

**What happens:**

- ✅ Pipeline runs
- ✅ Deploys to staging environment
- ✅ Team can test before production

### Releasing to Production

```bash
# Merge dev to main
git checkout main
git pull origin main
git merge dev
git push origin main
```

**What happens:**

- ✅ Pipeline runs
- ✅ Deploys to production
- ✅ Release PR is created/updated
- ✅ Merge Release PR to publish version

## 🎉 You're All Set!

You now have a production-ready CI/CD pipeline that:

- Automatically detects your tech stack
- Runs comprehensive quality checks
- Deploys to multiple environments
- Manages releases automatically

**Need help?** Check out the [full documentation](./README.md) or [open an issue](https://github.com/navigaite/github-organization/issues).

---

**Next:** [Configuration Reference](./CONFIGURATION.md)
