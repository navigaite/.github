# Migration Guide: Sub-Setup Workflow to Setup Action

This document guides you through migrating from using the deprecated `sub-setup.yaml` workflow to the new `setup` action.

## Background

The `sub-setup.yaml` workflow was previously used at the step level in multiple workflows, which caused errors when workflows were called
from other repositories. To fix this issue, we've created a new setup action that can be correctly referenced at the step level.

## Migration Steps

### 1. For Workflows in this Repository

Update any step using the old workflow reference:

```yaml
- name: Setup
  uses: ./.github/workflows/sub-setup.yaml
```

to use the new action reference:

```yaml
- name: Setup
  uses: ./.github/actions/setup
```

### 2. For External Repositories

When referencing workflows from this repository in another repository, make sure to use the full reference path:

```yaml
# For reusable workflows at the job level
jobs:
  my-job:
    uses: navigaite/github-organization/.github/workflows/sub-trufflehog.yaml@main

# For actions at the step level
steps:
  - name: Setup
    uses: navigaite/github-organization/.github/actions/setup@main
```

## Common Issues Fixed

This migration resolves the following error that occurred when running workflows from external repositories:

```
Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/[repo]/[repo]/.github/workflows/sub-setup.yaml'. Did you forget to run actions/checkout before running your local action?
```

## Action vs. Workflow Usage

Remember the difference in usage:

- **Reusable workflows** (like `sub-*.yaml`) are referenced at the job level using `uses:` and can contain multiple steps.
- **Actions** (like our setup action) are referenced at the step level and perform specific tasks within a job.

## Working with Mixed References

When using workflows from this repository that reference local actions, you need to ensure your workflow runs `actions/checkout` to fetch
this repository before using any action:

```yaml
jobs:
  my-job:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Navigaite Organization Repo
        uses: actions/checkout@v4
        with:
          repository: navigaite/github-organization
          ref: main
          path: .github/actions/navigaite

      - name: Setup
        uses: ./.github/actions/navigaite/setup
```

## Need Help?

If you encounter any issues during migration, please open an issue in the repository.
