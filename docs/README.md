# Universal CI/CD Pipeline v2

**A modern, configuration-driven GitHub Actions pipeline that works with any tech stack and deployment target.**

## 🎯 Overview

The Universal CI/CD Pipeline v2 is a complete rewrite of our pipeline system, designed to be:

- **🔄 Technology Agnostic**: Auto-detects and supports Node.js, Python, Flutter, and more
- **🚀 Deployment Flexible**: Deploy to Vercel, DigitalOcean, Docker registries, or anywhere
- **⚙️ Configuration-Driven**: Simple YAML configuration file controls everything
- **🔒 Secure by Default**: Built-in secret scanning, dependency checks, and security best practices
- **📦 Release Automation**: Automatic versioning and changelog generation
- **⚡ Fast & Efficient**: Smart caching, parallel execution, and optimized workflows

## 🚀 Quick Start

### 1. Create a Workflow File

Create [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml) in your project:

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

### 2. Create a Configuration File

Create [`.github/pipeline.yaml`](.github/pipeline.yaml) in your project:

```yaml
version: '2.0'

deployment:
  provider: vercel

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
  type: node
```

### 3. Configure Secrets

Add required secrets to your repository:

**For Vercel:**

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

**For DigitalOcean:**

- `DIGITALOCEAN_TOKEN`

**For Docker:**

- `DOCKER_REGISTRY_PASSWORD` (or use `GITHUB_TOKEN` for GHCR)

### 4. Push and Deploy! 🎉

That's it! The pipeline will:

- ✅ Auto-detect your tech stack
- ✅ Run security scans
- ✅ Lint your code
- ✅ Run tests with coverage
- ✅ Build your project
- ✅ Deploy to your environments
- ✅ Create releases automatically

## 📚 Documentation

- **[Getting Started](./GETTING_STARTED.md)** - Detailed setup instructions
- **[Configuration Reference](./CONFIGURATION.md)** - Complete configuration options
- **[Branching Strategy](./BRANCHING_STRATEGY.md)** - How to use main/dev branches
- **[Deployment Guide](./DEPLOYMENT.md)** - Deployment configuration for different providers
- **[Examples](../../.github/config/v2/examples/)** - Example configurations for different project types
- **[Migration from V1](./MIGRATION_FROM_V1.md)** - How to migrate from the old pipeline
- **[Troubleshooting](./TROUBLESHOOTING.md)** - Common issues and solutions

## 🎨 Features

### Auto-Detection

The pipeline automatically detects:

- **Tech Stack**: Node.js, Python, or Flutter
- **Package Manager**: npm, pnpm, yarn, pip, poetry, pipenv
- **Runtime Version**: From `.nvmrc`, `.python-version`, or config files
- **Build Output**: `.next`, `dist`, `build`, etc.

### Security Scanning

- **TruffleHog**: Scans for leaked secrets and credentials
- **Dependency Review**: Checks for vulnerable dependencies in PRs
- **Configurable**: Choose fail-on-secrets vs. warning-only mode

### Smart Caching

- Dependency caching (npm, pip, Flutter)
- Build output caching
- Docker layer caching
- Automatically configured per tech stack

### Flexible Deployment

**Supported Providers:**

- **Vercel**: Preview, staging, and production deployments
- **DigitalOcean App Platform**: With PR preview support
- **Docker**: Multi-platform builds to any registry (GHCR, Docker Hub, GCR, ECR)
- **Custom**: Easy to extend with custom deployment actions

**Environment Strategy:**

- `preview`: Deploys on pull requests
- `staging`: Deploys from `dev` branch
- `production`: Deploys from `main` branch

### Automated Releases

- **release-please**: Automatic semantic versioning
- **Changelog Generation**: Based on conventional commits
- **GitHub Releases**: Automatically created with release notes
- **PR-based Workflow**: Review and merge release PRs when ready

## 🌟 Examples

### Next.js + Vercel

```yaml
version: '2.0'
deployment:
  provider: vercel
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
  type: node
```

[Full example →](../../.github/config/v2/examples/nextjs-vercel-pipeline.yaml)

### Python + DigitalOcean

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
```

[Full example →](../../.github/config/v2/examples/python-digitalocean-pipeline.yaml)

### Flutter + Docker

```yaml
version: '2.0'
stack: flutter
deployment:
  provider: docker
  docker:
    image_name: my-flutter-app
    registry: ghcr
    platforms: linux/amd64,linux/arm64
```

[Full example →](../../.github/config/v2/examples/flutter-pipeline.yaml)

## 🔧 Advanced Configuration

### Custom Commands

Override auto-detection with custom commands:

```yaml
lint:
  command: npm run lint:fix && npm run format

test:
  command: npm run test:ci -- --coverage

build:
  command: npm run build:prod
```

### Selective Pipeline Steps

Disable steps you don't need:

```yaml
security:
  enable: false

lint:
  enable: true

test:
  enable: true
  coverage: false

build:
  enable: true
```

### Multiple Environments

Define complex deployment strategies:

```yaml
deployment:
  provider: vercel
  environments:
    - name: preview
      trigger:
        event: pull_request
      auto_deploy: true

    - name: staging
      trigger:
        event: push
        branch: dev
      auto_deploy: true

    - name: production
      trigger:
        event: push
        branch: main
      auto_deploy: true
```

## 🆚 V1 vs V2 Comparison

| Feature             | V1 (sub-workflows)      | V2 (Universal Pipeline)                |
| ------------------- | ----------------------- | -------------------------------------- |
| **Tech Stacks**     | Next.js only            | Node.js, Python, Flutter, Auto-detect  |
| **Configuration**   | Hard-coded in workflows | Single YAML file                       |
| **Deployment**      | Vercel only             | Vercel, DigitalOcean, Docker, Custom   |
| **Auto-detection**  | No                      | Yes (stack, package manager, versions) |
| **Security**        | TruffleHog only         | TruffleHog + Dependency Review         |
| **Releases**        | Manual                  | Automated with release-please          |
| **Caching**         | Manual setup            | Automatic per tech stack               |
| **Maintainability** | Separate workflows      | Single universal workflow              |

## 🤝 Contributing

Want to add support for a new tech stack or deployment provider?

1. Create a new composite action in [`.github/actions/v2/`](../../.github/actions/v2/)
2. Add configuration schema properties
3. Update the universal pipeline workflow
4. Add example configuration
5. Update documentation

## 📝 License

MIT License - see LICENSE file for details

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/navigaite/github-organization/issues)
- **Discussions**: [GitHub Discussions](https://github.com/navigaite/github-organization/discussions)

---

**Made with ❤️ by Navigaite**
