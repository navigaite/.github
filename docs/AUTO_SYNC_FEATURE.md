# Automatic Main → Dev Sync (Back-Merge After Release)

## 🎯 Problem This Solves

After creating a release on the `main` branch, version numbers are bumped in files like:

- `package.json` (Node.js)
- `pyproject.toml` (Python)
- `CHANGELOG.md` (all projects)
- Version tags

Without syncing these changes back to `dev`, you get **version drift**:

- `main` is on version `1.2.0`
- `dev` is still on version `1.1.0`
- Next merge from `dev` → `main` causes conflicts
- Changelogs become confusing
- Release-please gets confused about what version to release next

## ✅ Solution: Automatic Back-Merge

The Universal Pipeline v2 automatically syncs `main` back to your development branch after every release.

### How It Works

```
1. Developer merges PR to main
   └─> main: v1.1.0

2. Release-please creates Release PR
   └─> Changelog + version bump to v1.2.0

3. You merge Release PR
   └─> main: v1.2.0 (release created)

4. 🔄 AUTO-SYNC HAPPENS HERE
   └─> dev: v1.2.0 (synced from main)

5. Continue development on dev
   └─> Both branches in sync!
```

### What Gets Synced

- Version number changes (`package.json`, `pyproject.toml`, etc.)
- `CHANGELOG.md` updates
- Git tags
- Any other changes from the release

### Special Commit Format

The sync commit uses a special format that **release-please ignores**:

```
chore: sync main to dev [skip ci]

Auto-sync from main after release
This commit contains version updates and should not trigger a new release.
```

**Why this format?**

- `chore:` - Indicates maintenance, not a feature
- `[skip ci]` - Prevents triggering another CI run
- Special body text - Release-please skips this in future changelogs

This ensures the sync commit **won't appear in your next release notes**.

## ⚙️ Configuration

### Enable/Disable Sync

In your `.github/pipeline.yaml`:

```yaml
release:
  enable: true
  type: node
  sync_to_dev: true # Enable automatic sync (default: true)
  sync_target_branch: dev # Target branch (default: dev)
```

### Disable Sync

```yaml
release:
  enable: true
  type: node
  sync_to_dev: false # Disable automatic sync
```

### Custom Target Branch

If you use a different development branch name:

```yaml
release:
  enable: true
  type: node
  sync_to_dev: true
  sync_target_branch: develop # Or staging, integration, etc.
```

## 🔄 Sync Methods

The pipeline supports two sync methods:

### Method 1: Direct Push (Default, Recommended)

```yaml
release:
  sync_to_dev: true
```

**What happens:**

- Automatically merges `main` → `dev`
- Uses merge commit (not fast-forward)
- Pushes directly to `dev`
- Fastest method
- **Requires:** `GH_TOKEN` with push access to `dev`

**Branch Protection:**

- If `dev` has branch protection requiring PRs, this will fail
- Use Method 2 instead

### Method 2: Pull Request (For Protected Branches)

If your `dev` branch requires pull requests, you can create a PR instead:

**Not configurable via pipeline.yaml yet** - coming in future update. Currently uses Method 1 (direct push) only.

## 🚨 Troubleshooting

### Sync Fails: "Protected branch"

**Problem:** `dev` branch has protection rules requiring PR reviews.

**Solution:** Either:

1. **Recommended:** Allow the GitHub Actions bot to bypass protection:
   - Go to Settings → Branches → Branch protection for `dev`
   - Check "Allow specified actors to bypass required pull requests"
   - Add `github-actions[bot]`

2. **Alternative:** Disable auto-sync and manually merge:
   ```yaml
   release:
     sync_to_dev: false
   ```

### Sync Creates Merge Conflicts

**Problem:** Changes in `dev` conflict with `main`.

**What happens:**

- Sync job fails
- You see error in Actions tab
- `dev` remains unsynced

**Solution:**

1. Manually merge `main` into `dev`:

   ```bash
   git checkout dev
   git pull origin dev
   git merge origin/main
   # Resolve conflicts
   git commit
   git push origin dev
   ```

2. The conflict was likely caused by:
   - Direct commits to `main` (bypassing the PR process)
   - Divergent changes in `dev` that should have been merged first

**Prevention:**

- Always merge `dev` → `main` before creating releases
- Never commit directly to `main`
- Use the proper Git workflow (feature → dev → main)

### Sync Doesn't Run

**Check:**

1. **Release was created:**
   - Sync only runs after successful release
   - Check if Release PR was merged

2. **On main branch:**
   - Sync only runs for pushes to `main`
   - Not triggered by PRs or other branches

3. **Sync is enabled:**

   ```yaml
   release:
     enable: true
     sync_to_dev: true
   ```

4. **Token has permissions:**
   - `GH_TOKEN` secret exists
   - Token has `contents: write` permission
   - Token can push to target branch

### Sync Commit Appears in Next Release

**This shouldn't happen** if the commit message format is correct.

**Check:**

- Commit message includes `[skip ci]`
- Commit message starts with `chore:`
- Commit body mentions "Auto-sync from main after release"

**If it still appears**, please open an issue - this is a bug.

## 📊 Monitoring Sync Status

### Check if Sync Ran

1. Go to Actions tab in your repository
2. Click on the latest workflow run for your main branch push
3. Look for job: "🔄 Sync main → dev"
4. Check if it ran and succeeded

### View Sync Commits

```bash
# On dev branch, look for sync commits
git log --oneline | grep "chore: sync main to dev"
```

### Compare Branches

```bash
# Check if dev is behind main
git fetch origin
git log origin/dev..origin/main

# If output is empty, branches are in sync
```

## 🎓 Best Practices

### 1. Always Sync After Release

**Recommended configuration:**

```yaml
release:
  enable: true
  sync_to_dev: true # Keep this true
```

**Why:**

- Prevents version drift
- Keeps branches in sync
- Avoids merge conflicts later
- Makes Git history cleaner

### 2. Use Conventional Commits

The sync feature works best with conventional commits:

```bash
# Good commits that will be in changelog
git commit -m "feat: add user authentication"
git commit -m "fix: resolve login bug"

# Sync commit (automatic, won't be in changelog)
# chore: sync main to dev [skip ci]
```

### 3. Regular Dev → Main Merges

Before releasing:

```bash
# Ensure dev is current
git checkout dev
git pull origin dev

# Merge dev to main
git checkout main
git merge dev
git push origin main
```

This minimizes the chance of conflicts during back-merge.

### 4. Monitor Sync Failures

Set up notifications for failed workflows:

- GitHub notifications
- Slack/Discord webhook
- Email alerts

If sync fails, manually merge within 24 hours to prevent drift.

## 🔐 Security Considerations

### Token Permissions

The `GH_TOKEN` used for sync needs:

- `contents: write` - To push to dev branch
- `pull-requests: write` - For PR method (future)

**Recommendation:**

- Use a GitHub App token (more secure than PAT)
- Scope permissions to specific repositories
- Rotate tokens regularly

### Branch Protection

If using direct push method:

- GitHub Actions bot needs bypass permission
- This is safe because sync only happens after successful release
- All changes were already reviewed in the Release PR

## 📝 Examples

### Minimal Configuration (Uses Defaults)

```yaml
version: '2.0'

release:
  enable: true
  type: node
  # sync_to_dev: true is the default
  # sync_target_branch: dev is the default
```

### Explicit Configuration

```yaml
version: '2.0'

release:
  enable: true
  type: node
  sync_to_dev: true
  sync_target_branch: dev
```

### Custom Development Branch

```yaml
version: '2.0'

release:
  enable: true
  type: python
  sync_to_dev: true
  sync_target_branch: develop # Your custom branch name
```

### Disabled Sync (Manual Merging)

```yaml
version: '2.0'

release:
  enable: true
  type: simple
  sync_to_dev: false # You'll merge manually
```

## 🎯 Summary

The automatic back-merge feature:

- ✅ Prevents version drift between main and dev
- ✅ Syncs version changes automatically after release
- ✅ Uses special commit format excluded from release notes
- ✅ Configurable per project
- ✅ Enabled by default (but can be disabled)
- ✅ Supports custom target branch names
- ✅ Fails safely (doesn't break your release)

**This is a best practice** that saves time and prevents merge conflicts!

---

**Next:** [Configuration Reference](./CONFIGURATION.md)
