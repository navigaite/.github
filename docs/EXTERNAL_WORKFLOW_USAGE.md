# Using Workflows from Other Repositories

This document provides guidance for calling workflows from the `navigaite/github-organization` repository. Many users encounter the
following error:

```
Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/repo/repo/.github/workflows/sub-setup.yaml'
```

This happens because GitHub Actions resolves relative paths (like `./.github/actions/setup`) in the context of the calling repository, not
the repository where the workflow is defined.

## Solution: Use our External-Ready Workflows

We've created specialized workflows for cross-repository usage:

| Purpose               | Workflow to Use                                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------- |
| PR Scanning           | `navigaite/github-organization/.github/workflows/action-scan-pr-external.yaml@main`               |
| Vercel Release Deploy | `navigaite/github-organization/.github/workflows/action-vercel-deploy-release-external.yaml@main` |

These workflows have all local references expanded to absolute paths.

## Example: PR Scanning

```yaml
# In your repository: .github/workflows/scan-pr.yaml
name: Scan PR

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  scan-pr:
    uses: navigaite/github-organization/.github/workflows/action-scan-pr-external.yaml@main
    secrets: inherit
```

## Example: Vercel Release Deploy

```yaml
# In your repository: .github/workflows/deploy-release.yaml
name: Deploy Release

on:
  pull_request:
    branches:
      - main
    types:
      - ready_for_review

jobs:
  deploy-release:
    uses: navigaite/github-organization/.github/workflows/action-vercel-deploy-release-external.yaml@main
    with:
      vercel_scope: your-vercel-scope
    secrets: inherit
```

## If You Need Customization

If you need to customize the workflow behavior, you have two options:

### Option 1: Create a Local Copy (Recommended)

Copy the content of our external workflow into your repository and modify as needed.

### Option 2: Use Checkout + Local Actions

```yaml
jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Your Repository
        uses: actions/checkout@v4

      # Then directly implement the needed steps from our workflows
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
```

## Common Issues

### Problem: Action Not Found

```
Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/...'
```

**Solution**: Use the external workflow versions which don't use local actions.

### Problem: Package.json Not Found

```
Error accessing package.json
```

**Solution**: The external versions have fallback mechanisms for when package.json isn't available.

### Problem: File Not Found

```
Error: ENOENT: no such file or directory, open '.nvmrc'
```

**Solution**: You may be missing files expected by the workflow. Make sure your repository has all necessary files or use custom workflows.
