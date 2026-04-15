# Configuration Reference

Complete reference for the Universal Pipeline v2 configuration file.

## 📄 Configuration File

Save this as `.github/pipeline.yaml` in your project root.

## 🔧 Complete Configuration Example

```yaml
version: '2.0'

# Optional: Explicitly set tech stack (auto-detected if omitted)
stack: nodejs # Options: auto, nodejs, python, flutter

# Optional: Runtime version configuration
runtime:
  node_version: '20' # For nodejs
  python_version: '3.11' # For python
  flutter_version: 'stable' # For flutter

# Pipeline behavior
pipeline:
  enable_caching: true # Enable dependency caching

# Security scanning
security:
  enable: true
  trufflehog: true
  dependency_review: true
  fail_on_secrets: true
  fail_on_vulnerabilities: false

# Linting
lint:
  enable: true
  command: '' # Custom command (optional)
  fail_on_error: true

# Testing
test:
  enable: true
  command: '' # Custom command (optional)
  coverage: true # Enable code coverage

# Build
build:
  enable: true
  command: '' # Custom command (optional)
  upload_artifacts: false
  artifact_name: 'build-output'
  artifact_path: '' # Auto-detected if empty
  attest_artifacts: false
  artifact_retention_days: '7'

# Deployment
deployment:
  provider: vercel # Options: vercel, digitalocean, docker, none

  # Vercel configuration
  vercel:
    scope: '' # Team slug (optional)
    build_command: '' # Custom build command (optional)

  # DigitalOcean configuration
  digitalocean:
    app_name: '' # App name (required)
    app_spec: '.do/app.yaml'
    print_logs: true

  # Docker configuration
  docker:
    images:
      - name: app
        dockerfile: Dockerfile
        context: .
        registry: ghcr
        platforms: 'linux/amd64,linux/arm64'
        build_args: |
          NODE_ENV=production

  # Deployment environments
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

# Release management
release:
  enable: true
  type: simple # Options: node, python, simple
  strategy: release-please
  force_patch_on_no_release: false
  prerelease_branches:
    - branch: dev
      label: beta
```

## 📚 Field Reference

### `version` (required)

**Type:** `string` **Pattern:** `^2\.\d+$` **Example:** `"2.0"`

Schema version for the configuration file. Must be `2.0` or higher.

---

### `stack` (optional)

**Type:** `string` **Options:** `auto`, `nodejs`, `python`, `flutter` **Default:** `auto`

Technology stack for your project.

- `auto`: Auto-detect from project files (recommended)
- `nodejs`: Node.js/JavaScript/TypeScript projects
- `python`: Python projects
- `flutter`: Flutter/Dart projects

**Auto-detection rules:**

- `nodejs`: Presence of `package.json`
- `python`: Presence of `requirements.txt`, `pyproject.toml`, `setup.py`, or `Pipfile`
- `flutter`: Presence of `pubspec.yaml`

---

### `runtime` (optional)

**Type:** `object`

Runtime version configuration for different tech stacks.

#### `runtime.node_version`

**Type:** `string` **Example:** `"20"`, `"18.17.0"`, `"lts/*"`

Node.js version for `nodejs` stack.

**Auto-detection sources:**

1. `.nvmrc` file
2. `.node-version` file
3. `package.json` → `engines.node`
4. Default: `"20"`

#### `runtime.python_version`

**Type:** `string` **Example:** `"3.11"`, `"3.10.5"`

Python version for `python` stack.

**Auto-detection sources:**

1. `.python-version` file
2. `pyproject.toml` → `tool.poetry.dependencies.python`
3. Default: `"3.11"`

#### `runtime.flutter_version`

**Type:** `string` **Example:** `"stable"`, `"3.16.0"`, `"beta"`

Flutter version or channel for `flutter` stack.

**Auto-detection sources:**

1. `.fvm/fvm_config.json` → `flutterSdkVersion`
2. Default: `"stable"`

---

### `pipeline` (optional)

**Type:** `object`

Pipeline behavior configuration.

#### `pipeline.enable_caching`

**Type:** `boolean` **Default:** `true`

Enable dependency and build output caching.

- Caches npm/pnpm/yarn for Node.js
- Caches pip/poetry for Python
- Caches pub for Flutter
- Uses GitHub Actions cache

---

### `security` (optional)

**Type:** `object`

Security scanning configuration.

#### `security.enable`

**Type:** `boolean` **Default:** `true`

Enable all security scanning.

#### `security.trufflehog`

**Type:** `boolean` **Default:** `true`

Enable TruffleHog secret scanning.

Scans for:

- API keys
- Passwords
- Private keys
- Tokens
- Database credentials

#### `security.dependency_review`

**Type:** `boolean` **Default:** `true`

Enable dependency vulnerability scanning (PRs only).

Uses GitHub's Dependency Review action to check for:

- Known vulnerabilities
- License issues
- Deprecated packages

#### `security.fail_on_secrets`

**Type:** `boolean` **Default:** `true`

Fail pipeline if secrets are detected by TruffleHog.

- `true`: Block merge if secrets found
- `false`: Warning only

#### `security.fail_on_vulnerabilities`

**Type:** `boolean` **Default:** `false`

Fail pipeline if vulnerabilities are found.

- `true`: Block on any moderate+ vulnerability
- `false`: Report but don't block (recommended for initial setup)

---

### `lint` (optional)

**Type:** `object`

Linting configuration.

#### `lint.enable`

**Type:** `boolean` **Default:** `true`

Enable linting step.

#### `lint.command`

**Type:** `string` **Default:** `""` (auto-detect)

Custom lint command. Overrides auto-detection.

**Auto-detection:**

- **nodejs**: `npm run lint` (from `package.json` scripts)
- **python**: `ruff check .` (or `flake8`, `pylint` if available)
- **flutter**: `flutter analyze`

**Examples:**

```yaml
# Node.js with multiple linters
command: npm run lint && npm run type-check

# Python with custom config
command: ruff check . --config pyproject.toml

# Skip linting for specific files
command: npm run lint -- --ignore-pattern "*.test.js"
```

#### `lint.fail_on_error`

**Type:** `boolean` **Default:** `true`

Fail pipeline if linting errors are found.

---

### `test` (optional)

**Type:** `object`

Testing configuration.

#### `test.enable`

**Type:** `boolean` **Default:** `true`

Enable testing step.

#### `test.command`

**Type:** `string` **Default:** `""` (auto-detect)

Custom test command. Overrides auto-detection.

**Auto-detection:**

- **nodejs**: `npm test` or `npm run test:ci` (from `package.json`)
- **python**: `pytest` (or `unittest` if pytest not found)
- **flutter**: `flutter test`

**Examples:**

```yaml
# Node.js with coverage
command: npm run test:ci -- --coverage

# Python with specific markers
command: pytest -m "not slow" --cov

# Flutter with integration tests
command: flutter test && flutter test integration_test
```

#### `test.coverage`

**Type:** `boolean` **Default:** `false`

Enable code coverage reporting and upload to Codecov.

**Requirements:**

- `CODECOV_TOKEN` secret (for private repos)
- Coverage tool installed (jest, pytest-cov, etc.)

---

### `build` (optional)

**Type:** `object`

Build configuration.

#### `build.enable`

**Type:** `boolean` **Default:** `true`

Enable build step.

#### `build.command`

**Type:** `string` **Default:** `""` (auto-detect)

Custom build command. Overrides auto-detection.

**Auto-detection:**

- **nodejs**: `npm run build` (from `package.json`)
- **python**: `poetry build` or `python setup.py build` (if applicable)
- **flutter**: `flutter build web`

**Examples:**

```yaml
# Next.js production build
command: npm run build -- --no-lint

# Python package with custom config
command: poetry build -f wheel

# Flutter multi-platform
command: flutter build apk --release && flutter build web
```

#### `build.upload_artifacts`

**Type:** `boolean` **Default:** `false`

Upload build output as GitHub Actions artifacts.

Useful for:

- Downloading build output locally
- Using in subsequent jobs
- Debugging build issues

#### `build.artifact_name`

**Type:** `string` **Default:** `"build-output"`

Name for the uploaded artifact.

#### `build.artifact_path`

**Type:** `string` **Default:** `""` (auto-detect)

Path to build output directory.

**Auto-detection:**

- **nodejs**: `.next`, `dist`, `build`, or `out`
- **python**: `dist` or `build`
- **flutter**: `build/web` or `build`

#### `build.attest_artifacts`

**Type:** `boolean` **Default:** `false`

Generate SLSA build provenance attestations for uploaded artifacts.

#### `build.artifact_retention_days`

**Type:** `string` **Default:** `"7"`

Retention period for uploaded artifacts in days.

---

### `deployment` (optional)

**Type:** `object`

Deployment configuration.

#### `deployment.provider`

**Type:** `string` **Options:** `vercel`, `digitalocean`, `docker`, `none` **Default:** `none`

Deployment provider.

---

### `deployment.vercel` (for Vercel deployments)

**Type:** `object`

Vercel-specific configuration.

#### `deployment.vercel.scope`

**Type:** `string` **Example:** `"my-team-slug"`

Vercel team scope/slug. Required for team accounts.

#### `deployment.vercel.build_command`

**Type:** `string` **Example:** `"npm run build:prod"`

Custom build command for Vercel. Overrides project settings.

---

### `deployment.digitalocean` (for DigitalOcean deployments)

**Type:** `object`

DigitalOcean App Platform configuration.

#### `deployment.digitalocean.app_name`

**Type:** `string` **Required:** Yes (for DigitalOcean)

DigitalOcean app name.

#### `deployment.digitalocean.app_spec`

**Type:** `string` **Default:** `".do/app.yaml"`

Path to App Platform spec file.

#### `deployment.digitalocean.print_logs`

**Type:** `boolean` **Default:** `true`

Print build and deploy logs in GitHub Actions.

---

### `deployment.docker` (for Docker deployments)

**Type:** `object`

Docker deployment configuration.

#### `deployment.docker.images`

**Type:** `array`

Optional multi-image Docker configuration. If omitted, the workflow falls back to a single default image using `Dockerfile`.

#### Docker Image Object

```yaml
- name: api
  image_name: ghcr.io/acme/api
  dockerfile: Dockerfile.api
  context: .
  registry: ghcr
  platforms: linux/amd64,linux/arm64
  build_args: |
    APP_ENV=production
```

Supported keys:

- `name`: logical image name or repo suffix
- `image_name`: explicit image name override
- `dockerfile`: Dockerfile path
- `context`: build context
- `registry`: `dockerhub`, `ghcr`, `gcr`, `ecr`, or `custom`
- `platforms`: target platforms
- `build_args`: multiline Docker build args

---

### `deployment.environments`

**Type:** `array`

List of deployment environments.

#### Environment Object

```yaml
- name: preview
  trigger:
    event: pull_request
    # OR
    branch: dev
    # OR
    branches: [dev, staging]
  auto_deploy: true
```

##### `name` (required)

**Type:** `string` **Options:** `preview`, `staging`, `production`

Environment name.

##### `trigger.event`

**Type:** `string` **Options:** `pull_request`, `push`, `workflow_dispatch`

GitHub event that triggers deployment.

##### `trigger.branch`

**Type:** `string` **Example:** `"main"`, `"dev"`

Single branch name that triggers deployment (for `push` events).

##### `trigger.branches`

**Type:** `array` **Example:** `["main", "dev"]`

Multiple branch names that trigger deployment (for `push` events).

##### `auto_deploy`

**Type:** `boolean` **Default:** `true`

Automatically deploy when trigger conditions are met.

---

### `release` (optional)

**Type:** `object`

Automated release management configuration.

#### `release.enable`

**Type:** `boolean` **Default:** `false`

Enable automated release management with release-please.

#### `release.type`

**Type:** `string` **Options:** `node`, `python`, `simple` **Default:** `simple`

Release type based on project type.

- `node`: Node.js projects (updates `package.json`)
- `python`: Python projects (updates `pyproject.toml` or `setup.py`)
- `simple`: Language-agnostic (updates `version.txt`)

#### `release.strategy`

**Type:** `string` **Options:** `release-please`, `semantic-release` **Default:** `release-please`

Release automation engine.

#### `release.force_patch_on_no_release`

**Type:** `boolean` **Default:** `false`

When using `semantic-release`, publish a patch release if no releasable commits are found.

#### `release.extra_plugins`

**Type:** `array[string]`

Extra semantic-release plugins to install.

#### `release.config_file`

**Type:** `string`

Optional `release-please` config file path.

#### `release.config_file_stable`

**Type:** `string`

Optional stable-branch `release-please` config file path for Profile B repos.

#### `release.manifest_file`

**Type:** `string`

Optional `release-please` manifest file path.

#### `release.prerelease_branches`

**Type:** `array`

Branch-to-label mapping for prerelease publishing.

```yaml
prerelease_branches:
  - branch: dev
    label: beta
```

---

## 📋 Minimal Configuration Examples

### Next.js (Auto-detect everything)

```yaml
version: '2.0'

deployment:
  provider: vercel
  environments:
    - name: production
      trigger:
        event: push
        branch: main
```

### Python API

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

### Docker-only

```yaml
version: '2.0'

deployment:
  provider: docker
  docker:
    images:
      - name: app
        registry: ghcr
  environments:
    - name: production
      trigger:
        event: push
        branch: main
```

---

## ✅ Validation

Validate your configuration against the schema:

```bash
# Install check-jsonschema
pip install check-jsonschema

# Validate
check-jsonschema \
  --schemafile .github/config/v2/schemas/pipeline-config.schema.json \
  .github/pipeline.yaml
```

---

**Next:** [Branching Strategy](./BRANCHING_STRATEGY.md)
