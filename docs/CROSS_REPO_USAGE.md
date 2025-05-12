# Cross-Repository Usage Guide

This document explains how to properly use Navigaite GitHub workflows and actions from external repositories.

## Reusable Workflows vs. Actions

Our repository contains two types of reusable components:

1. **Reusable Workflows** (`sub-*.yaml`): Used at the job level in your workflow
2. **Actions** (in `.github/actions/`): Used at the step level in your workflow

## Using Our Components in Your Repository

### Direct Usage (Recommended Method)

For workflows that don't reference local actions, you can use them directly:

```yaml
name: PR Validation

on:
  pull_request:
    branches: [main, develop]

jobs:
  trufflehog:
    uses: navigaite/github-organization/.github/workflows/sub-trufflehog.yaml@main
    # Pass secrets if needed
    secrets: inherit
```

### Using Our Setup Action

To use our setup action in your workflow:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Environment
        uses: navigaite/github-organization/.github/actions/setup@main

      - name: Build
        run: npm run build
```

### Using Workflows with Local References

When using workflows like `sub-scan-pr.yaml` that reference local actions and other workflows, you need to create a wrapper workflow:

```yaml
# Your repo: .github/workflows/scan-pr.yaml
name: Scan PR

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  # Step 1: Setup the repository containing our actions
  setup-actions:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Navigaite Actions
        uses: actions/checkout@v4
        with:
          repository: navigaite/github-organization
          path: .github/navigaite-actions
          ref: main

  # Step 2: Run your own implementation of the workflow components
  lint:
    needs: setup-actions
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup
        uses: navigaite/github-organization/.github/actions/setup@main

      - name: Trunk Check
        uses: trunk-io/trunk-action@main
        with:
          post-annotations: true
          cache: false
```

## Common Issues and Solutions

### "Can't find action.yml" Error

If you see an error like:

```
Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/repo/repo/.github/workflows/sub-setup.yaml'
```

This means you're trying to use a reusable workflow as an action. Use the setup action instead:

```yaml
- name: Setup
  uses: navigaite/github-organization/.github/actions/setup@main
```

### File Not Found Errors with Local References

If a workflow fails with file not found errors for local path references, you need to use cross-repository references instead.

## Version Pinning

For stability, always pin to a specific tag or commit hash:

```yaml
# Good: Pinned to a tag
uses: navigaite/github-organization/.github/actions/setup@v1.0.0

# Good: Pinned to a commit hash
uses: navigaite/github-organization/.github/actions/setup@5f8c9b0

# Avoid: Using floating references
uses: navigaite/github-organization/.github/actions/setup@main
```

## Need Help?

If you encounter any issues, please open an issue in the repository.
