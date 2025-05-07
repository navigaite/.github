# GitHub Release Process Guide

This guide explains how to use our GitHub Actions release workflows to manage releases using the gitflow branching model.

## Overview

Our release process follows the gitflow branching model where:

1. Development happens on the `develop` branch
2. When it's time for a release, a `release/x.y.z` branch is created
3. Final testing and bug fixes happen on the release branch
4. When ready, the release branch is merged to `main` to create a production release

Our workflows automate this process with:

- Manual triggering of releases with version selection
- Automatic changelog generation using conventional commits
- Streamlined creation of GitHub releases via softprops/action-gh-release
- Automated deployment and back-merging

## Gitflow Release Process

Here's how our automated release process works:

### Phase 1: Create a Release Branch

1. Go to the "Actions" tab in GitHub
2. Select "📦 Create Release Branch" workflow
3. Click "Run workflow"
4. Configure:
   - Version bump: Choose patch, minor, or major
   - Target branch: Usually "develop"
5. The workflow will:
   - Calculate the new version
   - Create a release branch (e.g., `release/1.2.0`)
   - Update package.json and generate changelog
   - Create a PR from the release branch to main

### Phase 2: Finalize the Release

1. QA and testing happen on the `release/x.y.z` branch
2. Bug fixes can be made directly to the release branch
3. When the release is ready:
   - Review and merge the PR from release branch to main
4. The "Finalize Release" workflow automatically triggers and:
   - Creates a GitHub release with proper tagging
   - Generates release notes using the changelog
   - Deploys to production
   - Creates a back-merge PR to develop

## Creating a Hotfix

For urgent fixes to production code:

1. Go to the "Actions" tab in GitHub
2. Select "🔥 Create Hotfix" workflow
3. Enter the base version to patch (the current production version)
4. The workflow will:
   - Create a hotfix branch with incremented patch version
   - Create a PR from the hotfix branch to main
5. Apply your fixes directly to the hotfix branch
6. When ready, merge the PR to main
7. The same finalization flow for releases applies:
   - Creates a GitHub release
   - Deploys to production
   - Back-merges to develop

## Commit Message Format

For best results with changelog generation, use these prefixes for your commits:

- `feat`: New features (suggests minor version bump)
- `fix`: Bug fixes (suggests patch version bump)
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `perf`: Performance improvements
- `refactor`: Code refactoring
- `chore`: Routine tasks, maintenance
- `ci`: CI/CD changes
- `style`: Code style changes
- `build`: Build system changes

Breaking changes (suggesting major version bump) can be indicated by adding a `!` or including `BREAKING CHANGE:` in the commit message:

```
feat!: completely redesign API
fix: resolve bug in component

BREAKING CHANGE: This changes the behavior of X
```

## Example Workflow

1. Developers merge features into `develop` branch

   ```
   feat: add dark mode support
   fix: resolve theme flickering issue
   ```

2. Release manager triggers the "Create Release Branch" workflow for a minor version bump

3. A release branch `release/1.2.0` is created and a PR to main is opened

4. QA team tests the release branch and developers fix any issues:

   ```
   fix: resolve issue discovered during release testing
   ```

5. Release manager merges the PR to main, which automatically:
   - Creates a GitHub release v1.2.0
   - Deploys to production
   - Creates a back-merge PR to develop

## Best Practices

1. Use conventional commits to ensure clear changelog generation
2. One logical change per commit
3. Be descriptive in commit messages
4. Treat `release/*` branches as stabilization branches - only bug fixes should be committed directly to them
5. Always merge releases to `main` through PRs, never commit directly
6. Keep both `develop` and `main` branches protected

## Troubleshooting

- If the changelog generation fails, ensure you have committed changes following the conventional commits format
- For hotfixes, make sure to use the correct base version
- If the release process fails during finalization, check the workflow logs for specific error messages
