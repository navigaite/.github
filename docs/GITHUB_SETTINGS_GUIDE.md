# ⚙️ GitHub Settings Guide - Complete Configuration

Complete guide for configuring GitHub organization and repository settings for the Universal Pipeline v2.

## 📋 Table of Contents

1. [Organization Settings](#organization-settings)
2. [Repository Settings](#repository-settings)
3. [Branch Protection Rules](#branch-protection-rules)
4. [Repository Secrets](#repository-secrets)
5. [Environment Configuration](#environment-configuration)
6. [GitHub App Setup (Recommended)](#github-app-setup-recommended)
7. [Team & Permissions](#team--permissions)
8. [Workflow-Based Security (Free Alternative)](#workflow-based-security-free-alternative)

---

## 🏢 Organization Settings

Navigate to: `https://github.com/organizations/navigaite/settings`

---

### 🔹 General

**Location:** Sidebar → `General`

**Organization Profile:**

```
Organization display name: Navigaite
Organization email: (Set a public email for contact)
Organization URL: https://navigaite.com
Organization description: Brief description of your organization
```

**Renaming & Transfers:**

- ⚠️ Be cautious when renaming - it affects all repository URLs
- Organization transfer requires all members to confirm

---

### 🔹 Policies

**Location:** Sidebar → `Policies` (expandable section)

Configure repository policies, naming conventions, and default settings.

---

### 📂 Access Section

#### 1. Billing and Licensing

**Location:** Sidebar → `Access` → `Billing and licensing` (expandable)

- Manage subscription plans
- View usage and billing
- Manage payment methods
- **Note:** Organization owners and billing managers have access

#### 2. Organization Roles

**Location:** Sidebar → `Access` → `Organization roles` (expandable)

**Available Roles:**

- **Owner** - Full administrative access (limit to 2-3 trusted people)
- **Member** - Default role for organization members
- **Billing manager** - Manage billing only
- **Security manager** - View security alerts, manage security settings
- **Custom roles** - Create custom permission sets (Enterprise only)

#### 3. Repository Roles

**Location:** Sidebar → `Access` → `Repository roles` (expandable)

**Default Repository Roles:**

| Role         | Permissions                                   |
| ------------ | --------------------------------------------- |
| **Read**     | View and clone repositories                   |
| **Triage**   | Read + manage issues and pull requests        |
| **Write**    | Triage + push to repository                   |
| **Maintain** | Write + manage settings (no sensitive access) |
| **Admin**    | Full access including sensitive settings      |

**Recommendation:**

```
Base permissions: Read (secure default)
Grant higher permissions explicitly per repository or team
```

#### 4. Member Privileges

**Location:** Sidebar → `Access` → `Member privileges`

| Setting                              | Recommended Value                        | Reason                                  |
| ------------------------------------ | ---------------------------------------- | --------------------------------------- |
| **Base permissions**                 | `Read`                                   | Secure default, grant access explicitly |
| **Repository creation**              | ✅ Members can create repositories       | Enable team autonomy                    |
| **Repository visibility change**     | ❌ Disable                               | Prevent accidental public repos         |
| **Repository deletion and transfer** | ❌ Disable for members                   | Prevent accidents                       |
| **Repository forking**               | ✅ Allow forking of private repositories | Enable contribution workflow            |
| **Pages creation**                   | ✅ Members can create Pages sites        | Enable documentation                    |

#### 5. Import/Export

**Location:** Sidebar → `Access` → `Import/Export`

- Export organization data
- Import repositories from other platforms

#### 6. Moderation

**Location:** Sidebar → `Access` → `Moderation` (expandable)

**Organization Moderators:**

- Assign moderators to manage community interactions
- Moderators can block/unblock contributors, hide comments, limit interactions

**Interaction Limits:**

```
⚙️ Optional: Limit interactions to prior contributors during high activity
```

---

### 🔧 Code, Planning, and Automation Section

#### 1. Repository

**Location:** Sidebar → `Code, planning, and automation` → `Repository` (expandable)

**Repository Defaults:**

```
Default branch name: main
Repository visibility: Private (default for new repos)
```

#### 2. Codespaces

**Location:** Sidebar → `Code, planning, and automation` → `Codespaces` (expandable)

Configure GitHub Codespaces settings (if enabled).

#### 3. Planning

**Location:** Sidebar → `Code, planning, and automation` → `Planning` (expandable)

Configure GitHub Projects and planning features.

#### 4. Copilot

**Location:** Sidebar → `Code, planning, and automation` → `Copilot` (expandable)

Configure GitHub Copilot access and policies (if subscribed).

#### 5. Actions

**Location:** Sidebar → `Code, planning, and automation` → `Actions` (expanded in screenshot)

##### a. General

**Critical Settings:**

```
Actions permissions:
⚙️ Allow all actions and reusable workflows
   (Required for Universal Pipeline to work)

Fork pull request workflows:
✅ Require approval for first-time contributors
   (Security: Prevents secrets exposure from untrusted PRs)

✅ Require approval for all outside collaborators
   (Additional security layer)

Workflow permissions:
⚙️ Read and write permissions
   (Allows: release creation, PR comments, branch sync)

✅ Allow GitHub Actions to create and approve pull requests
   (Required for: Release Please PRs, Auto-sync PRs)
```

**Artifact & Log Retention:**

| Setting                        | Value     | Notes                          |
| ------------------------------ | --------- | ------------------------------ |
| **Default artifact retention** | `90 days` | Can be shorter to save storage |
| **Default log retention**      | `90 days` | Configurable based on needs    |

##### b. Runners

Manage self-hosted runners for the organization.

##### c. Runner Groups

Organize runners into groups for access control.

##### d. Custom Images (Preview)

Configure custom runner images.

##### e. Caches

View and manage Actions cache usage across repositories.

#### 6. Models (Preview)

**Location:** Sidebar → `Code, planning, and automation` → `Models` (Preview)

Configure AI model access.

#### 7. Webhooks

**Location:** Sidebar → `Code, planning, and automation` → `Webhooks`

**Setup Organization Webhooks:**

```
⚙️ Use webhooks for external integrations
✅ Authenticate webhooks with secret keys
```

#### 8. Discussions

**Location:** Sidebar → `Code, planning, and automation` → `Discussions`

Enable/configure GitHub Discussions at organization level.

#### 9. Packages

**Location:** Sidebar → `Code, planning, and automation` → `Packages`

**Container Registry Settings:**

```
Package creation: Members can create packages
Package deletion: Admins only
Visibility: Private by default
```

#### 10. Pages

**Location:** Sidebar → `Code, planning, and automation` → `Pages`

Configure GitHub Pages policies for organization repositories.

#### 11. Hosted Compute Networking

**Location:** Sidebar → `Code, planning, and automation` → `Hosted compute networking`

Configure networking for GitHub-hosted runners (Enterprise feature).

---

### 🔒 Security Section

#### 1. Authentication Security

**Location:** Sidebar → `Security` → `Authentication security`

**Two-Factor Authentication (2FA):**

```
✅ REQUIRED: Require two-factor authentication for all members
   (Critical security measure)

Compliance period: 30 days
```

**SAML/SSO (Enterprise only):**

- Configure single sign-on if available

#### 2. Advanced Security

**Location:** Sidebar → `Security` → `Advanced Security` (expandable)

**⚠️ PAID FEATURE - Use Free Alternatives**

**Free Features to Enable:**

```
✅ Dependency graph
   Free - Shows dependency tree for all repositories
```

**Paid Features (Disable for Free Alternative):**

```
❌ Dependabot alerts
   ⚠️ PAID for private repos
   💡 Alternative: Use Trivy in workflows

❌ Dependabot security updates
   ⚠️ PAID for private repos
   💡 Alternative: Manual PR reviews + Dependabot.yml

❌ Secret scanning
   ⚠️ PAID for private repos (FREE for public repos)
   💡 Alternative: TruffleHog in workflows

❌ Push protection
   ⚠️ PAID feature
   💡 Alternative: Pre-commit hooks (see section below)

❌ Code scanning (CodeQL)
   ⚠️ PAID for private repos (FREE for public repos)
   💡 Alternative: Already included in Universal Pipeline
```

**💡 Cost-Free Alternative:** We handle all security scanning in the workflows (see
[Workflow-Based Security](#workflow-based-security-free-alternative) section)

**Cost Comparison:**

| Feature            | GitHub Advanced Security | Our Free Alternative |
| ------------------ | ------------------------ | -------------------- |
| Secret Scanning    | $49/user/month           | TruffleHog (FREE)    |
| Vulnerability Scan | Included                 | Trivy (FREE)         |
| Dependency Updates | Included                 | Dependabot (FREE)    |
| Push Protection    | Included                 | Pre-commit (FREE)    |
| **Total Cost**     | **$49/user/month**       | **$0**               |

#### 3. Deploy Keys

**Location:** Sidebar → `Security` → `Deploy keys`

Manage deploy keys for repository access.

#### 4. Compliance

**Location:** Sidebar → `Security` → `Compliance`

Configure compliance settings (Enterprise feature).

#### 5. Verified and Approved Domains

**Location:** Sidebar → `Security` → `Verified and approved domains`

**Add Your Domains:**

```
✅ navigaite.com
✅ *.navigaite.com
   (Prevents phishing, enables email restrictions)
```

**Benefits:**

- Restrict email notifications to verified domains
- Prevent email spoofing
- Enhanced security for organization communications

#### 6. Secrets and Variables

**Location:** Sidebar → `Security` → `Secrets and variables` (expandable)

**Organization-Level Secrets:**

Configure secrets accessible across multiple repositories:

```
Actions secrets: For GitHub Actions workflows
Codespaces secrets: For Codespaces environments
Dependabot secrets: For Dependabot to access private registries
```

**Best Practices:**

- Use organization secrets for shared credentials
- Use repository secrets for repo-specific credentials
- Never commit secrets to code

---

### 🔌 Third-party Access Section

#### 1. GitHub Apps

**Location:** Sidebar → `Third-party Access` → `GitHub Apps`

**Manage GitHub Apps:**

- Review installed GitHub Apps
- Configure app permissions
- Remove unused apps

**Recommended Apps:**

- Dependabot
- Vercel (for deployments)
- Slack/Discord (for notifications)

#### 2. OAuth App Policy

**Location:** Sidebar → `Third-party Access` → `OAuth app policy`

**Recommended Setting:**

```
⚙️ Access restriction: Enabled
   Review and approve OAuth apps before use
   Prevents unauthorized third-party access
```

#### 3. Personal Access Tokens

**Location:** Sidebar → `Third-party Access` → `Personal access tokens` (expandable)

**Token Policies:**

```
⚙️ Require administrator approval for fine-grained personal access tokens
✅ Restrict personal access token access via organization policy
```

---

### 🔗 Integrations Section

#### 1. Scheduled Reminders

**Location:** Sidebar → `Integrations` → `Scheduled reminders`

Configure Slack/Teams reminders for pending PR reviews.

---

### 📦 Archive Section

#### 1. Logs

**Location:** Sidebar → `Archive` → `Logs` (expandable)

**Audit Log:**

- Review all organization activities
- Monitor security events
- Track administrative changes
- Export logs for compliance

**Recommendation:** Review audit logs quarterly

#### 2. Deleted Repositories

**Location:** Sidebar → `Archive` → `Deleted repositories`

Restore accidentally deleted repositories (90-day retention).

---

### 💻 Developer Settings

**Location:** Sidebar → `Developer settings` (expandable at bottom)

**GitHub Apps & OAuth Apps:**

- Register new GitHub Apps
- Manage OAuth applications
- Configure webhooks and integrations

---

## 📦 Repository Settings

Navigate to: `https://github.com/navigaite/your-repo/settings`

### General Settings

**Location:** `Settings → General`

#### Repository Name & Description

```
Repository name: [your-repo-name]
Description: Brief description of the project
Website: https://your-app-url.com (optional)
Topics: Add relevant tags (e.g., nodejs, ci-cd, vercel)
```

#### Features

**Enable:**

- ✅ **Issues** - Bug tracking & feature requests
- ✅ **Preserve this repository** - Safety net for deletion
- ⚙️ **Discussions** (Optional) - Community Q&A
- ⚙️ **Projects** (Optional) - Project management

**Disable:**

- ❌ **Wikis** - Use `docs/` folder instead for version control
- ❌ **Sponsorships** (Unless applicable)

#### Pull Requests

**Merge Button Settings:**

```
✅ Allow merge commits
   (Default merge strategy)

✅ Allow squash merging
   (Clean up commit history)

⚙️ Allow rebase merging (Optional)
   (Use cautiously - rewrites history)

Default merge message:
⚙️ Pull request title and description
   (Cleaner than all commits)
```

**Automation:**

```
✅ Always suggest updating pull request branches
   (Keeps PRs in sync with base)

✅ Automatically delete head branches
   (Cleanup after merge)

✅ Allow auto-merge
   (Enable automated workflows)
```

#### Archives

```
✅ Include Git LFS objects in archives
   (If using LFS)
```

---

## 🔒 Branch Protection Rules

### For `main` Branch (Production)

**Location:** Settings → Branches → Add branch protection rule

**Branch name pattern:** `main`

**Required Settings:**

✅ **Require a pull request before merging**

- ✅ Require approvals: `1` (or more for larger teams)
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners (if you have CODEOWNERS file)

✅ **Require status checks to pass before merging**

- ✅ Require branches to be up to date before merging
- **Required status checks:**
  - `setup`
  - `security` (if enabled)
  - `lint`
  - `test`
  - `build`

✅ **Require conversation resolution before merging**

✅ **Do not allow bypassing the above settings**

- ⚠️ **Exception:** If using auto-sync feature, add `github-actions[bot]` to allowed actors

❌ **Do NOT enable:**

- Require deployments to succeed (handled by pipeline)
- Require signed commits (unless you specifically need this)

**Optional but Recommended:**

✅ **Restrict pushes that create matching branches**

- Only allow specific people/teams to create `main` branch

✅ **Require linear history**

- Enforces squash or rebase merging
- Keeps Git history clean

### For `dev` Branch (Staging)

**Branch name pattern:** `dev`

**Recommended Settings:**

✅ **Require a pull request before merging**

- ✅ Require approvals: `1`
- Can be less strict than `main`

✅ **Require status checks to pass before merging**

- Same checks as `main`

⚠️ **Important for Auto-Sync:**

If you enable **"Require a pull request before merging"** on `dev`:

**Option 1 (Recommended):** Allow GitHub Actions bot to bypass:

- Go to: Settings → Branches → `dev` protection rule
- Under "Restrict who can push to matching branches"
- Add: `github-actions[bot]`
- This allows the auto-sync to push directly

**Option 2:** Disable auto-sync and merge manually:

```yaml
# In .github/pipeline.yaml
release:
  sync_to_dev: false
```

### For Feature Branches

**Branch name pattern:** `feature/*` or `feat/*` (optional)

Usually no protection needed, but you can add:

- Require pull request to `dev`
- Require status checks

---

## 🔑 Repository Secrets

**Location:** Settings → Secrets and variables → Actions → Secrets

### Required for All Projects

| Secret Name | Description                                      | How to Get                                            | Required? |
| ----------- | ------------------------------------------------ | ----------------------------------------------------- | --------- |
| `GH_TOKEN`  | GitHub Personal Access Token or GitHub App token | See [GitHub App Setup](#github-app-setup-recommended) | ✅ Yes    |

### Required for Vercel Deployment

| Secret Name         | Description                 | How to Get                                                                         |
| ------------------- | --------------------------- | ---------------------------------------------------------------------------------- |
| `VERCEL_TOKEN`      | Vercel API token            | [Vercel Dashboard](https://vercel.com/account/tokens) → Settings → Tokens → Create |
| `VERCEL_ORG_ID`     | Vercel organization/team ID | Vercel project settings → General → Project ID section                             |
| `VERCEL_PROJECT_ID` | Vercel project ID           | Vercel project settings → General → Project ID                                     |

**How to find VERCEL_ORG_ID and VERCEL_PROJECT_ID:**

1. Go to your Vercel project
2. Click Settings
3. Scroll to "Project ID" section
4. You'll see both IDs there:
   ```
   Project ID: prj_xxxxx (this is VERCEL_PROJECT_ID)
   Team ID: team_xxxxx (this is VERCEL_ORG_ID, for team accounts)
   ```

For personal accounts, VERCEL_ORG_ID is your user ID.

### Required for DigitalOcean Deployment

| Secret Name          | Description            | How to Get                                                                             |
| -------------------- | ---------------------- | -------------------------------------------------------------------------------------- |
| `DIGITALOCEAN_TOKEN` | DigitalOcean API token | [DO Dashboard](https://cloud.digitalocean.com/account/api/tokens) → Generate New Token |

**Token Scopes:** Select "Read and Write"

### Required for Docker Deployment

#### For GitHub Container Registry (GHCR) - Recommended

| Secret Name    | Description            | How to Get                                          |
| -------------- | ---------------------- | --------------------------------------------------- |
| `GITHUB_TOKEN` | Automatically provided | No setup needed! GitHub provides this automatically |

Or use a PAT with `write:packages` scope:

| Secret Name                | Description | How to Get                                                                                                      |
| -------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------- |
| `DOCKER_REGISTRY_PASSWORD` | GitHub PAT  | Settings → Developer settings → Personal access tokens → Generate new token (classic) → Select `write:packages` |

#### For Docker Hub

| Secret Name                | Description             | How to Get                                                                |
| -------------------------- | ----------------------- | ------------------------------------------------------------------------- |
| `DOCKER_REGISTRY_USERNAME` | Docker Hub username     | Your Docker Hub username                                                  |
| `DOCKER_REGISTRY_PASSWORD` | Docker Hub access token | [Docker Hub](https://hub.docker.com/settings/security) → New Access Token |

### Optional Secrets

| Secret Name     | Description                        | When Needed                             |
| --------------- | ---------------------------------- | --------------------------------------- |
| `CODECOV_TOKEN` | Codecov token for coverage reports | If using code coverage on private repos |

---

## 🌍 Environment Configuration

**Location:** Settings → Environments

### Create Three Environments

#### 1. **preview**

**Protection rules:**

- ❌ No reviewers needed (auto-deploy on PR)
- ✅ Deployment branches: "Selected branches" → Add rule: `*` (all branches)

**Environment secrets:**

- None needed (uses repository secrets)

#### 2. **staging** (or **dev**)

**Protection rules:**

- ❌ No reviewers needed (auto-deploy on push to dev)
- ✅ Deployment branches: "Selected branches" → Add rule: `dev`

**Environment secrets:**

- Can override repository secrets if staging uses different credentials

#### 3. **production**

**Protection rules:**

- ✅ **Required reviewers:** Add yourself or team leads (1-2 people)
  - This adds a manual approval step before production deployment
- ✅ **Wait timer:** 0 minutes (or add delay if desired)
- ✅ **Deployment branches:** "Selected branches" → Add rule: `main`

**Environment secrets:**

- Production-specific secrets (if different from repository secrets)

**Environment variables (optional):**

- `NODE_ENV=production`
- Any production-specific environment variables

### Environment URL Patterns

Optionally set environment URLs for tracking:

- **preview:** `https://${{ github.event.repository.name }}-pr-${{ github.event.number }}.vercel.app`
- **staging:** `https://${{ github.event.repository.name }}-staging.vercel.app`
- **production:** `https://your-domain.com`

---

## 🤖 GitHub App Setup (Recommended)

Using a GitHub App is more secure than Personal Access Tokens.

### Why GitHub App?

✅ **More secure:** Scoped permissions, no personal account dependency ✅ **Better audit trail:** Shows as `github-actions[bot]` ✅ **No
expiration:** Unlike PATs that expire ✅ **Organization-wide:** Can be installed across all repos

### Create GitHub App

1. **Go to:** GitHub → Settings → Developer settings → GitHub Apps → New GitHub App

2. **Basic Information:**
   - **Name:** `My Org CI/CD Bot` (or your org name)
   - **Homepage URL:** `https://github.com/YOUR_ORG`
   - **Webhook:** Uncheck "Active"

3. **Permissions (Repository):**
   - **Contents:** Read and write (for commits and releases)
   - **Pull requests:** Read and write (for PR comments)
   - **Metadata:** Read-only (automatically selected)
   - **Deployments:** Read and write (for deployment tracking)

4. **Permissions (Organization):** None needed

5. **Where can this GitHub App be installed?**
   - Select "Only on this account"

6. Click **Create GitHub App**

7. **Generate Private Key:**
   - Scroll down → "Generate a private key"
   - Download the `.pem` file
   - Keep it secure!

8. **Install the App:**
   - Click "Install App" in left sidebar
   - Choose your organization
   - Select "All repositories" or specific repos
   - Click "Install"

9. **Get App ID:**
   - Go back to your app settings
   - Copy the "App ID" number at the top

10. **Add to Repository Secrets:**
    - `WORKFLOW_APP_ID`: The App ID from step 9
    - `WORKFLOW_APP_PRIVATE_KEY`: Contents of the `.pem` file (entire file as multiline secret)

### Use GitHub App in Pipeline

The pipeline will automatically use the GitHub App if these secrets exist:

```yaml
# In your workflow, the pipeline checks for these automatically
secrets:
  GH_TOKEN: ${{ secrets.GH_TOKEN }} # Falls back to GITHUB_TOKEN if not present
  WORKFLOW_APP_ID: ${{ secrets.WORKFLOW_APP_ID }}
  WORKFLOW_APP_PRIVATE_KEY: ${{ secrets.WORKFLOW_APP_PRIVATE_KEY }}
```

---

## 🔐 Permissions

### Workflow Permissions

**Location:** Settings → Actions → General → Workflow permissions

**Required Setting:**

✅ **Read and write permissions**

- Allows workflows to create releases, comment on PRs, push code

✅ **Allow GitHub Actions to create and approve pull requests**

- Needed for release-please to create Release PRs
- Needed for auto-sync to create PRs (if using PR method)

---

## 👥 Team & Permissions

### Create Teams

**Location:** `Organization Settings → Teams`

#### Recommended Team Structure

```
navigaite/
├── engineering (Parent Team)
│   ├── frontend
│   ├── backend
│   ├── devops
│   └── qa
├── admins
└── contractors (if applicable)
```

#### Team Permissions

| Team                     | Permission Level | Purpose                                   |
| ------------------------ | ---------------- | ----------------------------------------- |
| **engineering** (Parent) | Write            | All developers, default access            |
| **frontend**             | Write            | Frontend-specific code                    |
| **backend**              | Write            | Backend-specific code                     |
| **devops**               | Maintain         | CI/CD, infrastructure                     |
| **qa**                   | Write            | Testing, quality assurance                |
| **admins**               | Admin            | Repository settings, sensitive operations |
| **contractors**          | Read             | External contributors                     |

### CODEOWNERS File

Create `.github/CODEOWNERS` for automatic review requests:

```
# Global owners (all files)
* @navigaite/engineering

# CI/CD and workflows
/.github/workflows/ @navigaite/devops
/.github/actions/ @navigaite/devops
/.github/pipeline.yaml @navigaite/devops

# Documentation
/docs/ @navigaite/engineering
README.md @navigaite/engineering

# Frontend (example)
/src/components/ @navigaite/frontend
/src/pages/ @navigaite/frontend
/src/styles/ @navigaite/frontend

# Backend (example)
/api/ @navigaite/backend
/server/ @navigaite/backend
/database/ @navigaite/backend

# Infrastructure
/terraform/ @navigaite/devops
/kubernetes/ @navigaite/devops
/docker-compose.yml @navigaite/devops
Dockerfile @navigaite/devops

# Configuration files
package.json @navigaite/devops
pyproject.toml @navigaite/devops
```

---

## 🛡️ Workflow-Based Security (Free Alternative)

**Instead of paid GitHub features, use these free workflow-based tools:**

### 1. Secret Scanning (TruffleHog)

**Already configured in:** `.github/workflows/universal-pipeline.yaml`

```yaml
security:
  enable: true
  trufflehog: true
```

**What it does:**

- ✅ Scans for secrets in code
- ✅ Checks commit history
- ✅ Runs on every push & PR
- ✅ 100% FREE

**TruffleHog detects:**

- API keys (AWS, GCP, Azure, etc.)
- Database credentials
- Private keys
- OAuth tokens
- 700+ credential types

### 2. Dependency Vulnerability Scanning (Trivy)

**Already configured in:** `.github/workflows/nightly-maintenance.yaml`

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

**What it does:**

- ✅ Scans dependencies for CVEs
- ✅ Checks container images
- ✅ Runs nightly
- ✅ Uploads to GitHub Security tab
- ✅ 100% FREE

### 3. Dependency Updates (Dependabot)

**Already configured in:** `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly

  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
```

**What it does:**

- ✅ Creates PRs for dependency updates
- ✅ Groups minor/patch updates
- ✅ Works on ALL repos (public & private)
- ✅ 100% FREE

### 4. Pre-Commit Secret Protection (Git Hooks)

**Create `.git-hooks/pre-commit`:**

```bash
#!/bin/bash
# Prevent committing secrets

echo "🔍 Scanning for secrets..."

# Check for common secret patterns
if git diff --cached | grep -E "(api_key|API_KEY|secret|SECRET|password|PASSWORD|token|TOKEN)" > /dev/null; then
    echo "⚠️  WARNING: Potential secret detected!"
    echo "Please review your changes before committing."
    echo ""
    echo "To bypass this check (NOT RECOMMENDED):"
    echo "  git commit --no-verify"
    exit 1
fi

echo "✅ No secrets detected"
```

**Setup:**

```bash
mkdir -p .git-hooks
chmod +x .git-hooks/pre-commit
git config core.hooksPath .git-hooks
```

### 5. Code Quality (SonarQube Alternative)

**For FREE code quality analysis, add to workflow:**

```yaml
- name: Code Quality Check
  run: |
    # Run linters
    npm run lint || true

    # Check code complexity
    npx complexity-report src/ || true

    # Check for code smells
    npx jscpd src/ || true
```

### 6. License Compliance Check

**Add to nightly maintenance:**

```yaml
- name: License Compliance
  run: |
    echo "Checking licenses..."
    npx license-checker --production --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC"
```

### Comparison: Paid vs Free

| Feature                | GitHub (Paid)         | Our Workflow (Free)   |
| ---------------------- | --------------------- | --------------------- |
| Secret Scanning        | $$$                   | ✅ TruffleHog         |
| Dependency Alerts      | $$$ (private)         | ✅ Trivy + Dependabot |
| Vulnerability Database | Limited               | ✅ Full CVE database  |
| Push Protection        | $$$                   | ✅ Pre-commit hooks   |
| Container Scanning     | $$$                   | ✅ Trivy              |
| License Compliance     | $$$                   | ✅ license-checker    |
| **Total Cost**         | **$21-49/user/month** | **$0**                |

---

## 🛡️ Optional: GitHub Code Scanning (If You Want to Pay)

**Only enable these if you have GitHub Advanced Security:**

### Enable CodeQL

**Location:** Settings → Code security and analysis

```
⚠️ PAID FEATURE (GitHub Advanced Security)
Cost: $49/user/month (Enterprise only)

✅ Enable: Code scanning
✅ Set up: CodeQL analysis
   - Languages: JavaScript, TypeScript, Python
   - Schedule: Weekly scans
```

### Enable Secret Scanning

```
⚠️ PAID FEATURE for private repos
FREE for public repos

✅ Enable: Secret scanning
✅ Enable: Push protection
```

**Our Recommendation:** Use the free workflow-based alternatives above instead!

---

## ✅ Complete Setup Checklist

### Organization Settings (One-Time Setup)

#### General & Policies

- [ ] Organization profile configured (name, email, URL, description)
- [ ] Repository policies configured

#### Access Section

- [ ] Organization roles assigned (Owners, Members, Security managers)
- [ ] Repository roles configured (base permissions: Read)
- [ ] Member privileges configured:
  - [ ] Base permissions: Read
  - [ ] Repository creation: Enabled for members
  - [ ] Repository deletion: Disabled for members
  - [ ] Repository forking: Enabled
  - [ ] Pages creation: Enabled
- [ ] Moderation settings configured (if needed)

#### Code, Planning, and Automation

- [ ] Repository defaults: Default branch set to `main`
- [ ] Actions → General settings configured:
  - [ ] Actions permissions: Allow all actions
  - [ ] Fork PR approvals: Enabled for first-time contributors
  - [ ] Workflow permissions: Read and write
  - [ ] Allow GitHub Actions to create and approve PRs: Enabled
  - [ ] Artifact retention: 90 days
  - [ ] Log retention: 90 days
- [ ] Runners configured (if using self-hosted)
- [ ] Webhooks configured (if needed)
- [ ] Packages settings: Private by default

#### Security Section

- [ ] Authentication security: 2FA required for all members
- [ ] Advanced Security:
  - [ ] Dependency graph: Enabled (FREE)
  - [ ] Dependabot alerts: Disabled (use workflow alternative)
  - [ ] Secret scanning: Disabled (use TruffleHog)
  - [ ] Push protection: Disabled (use pre-commit hooks)
- [ ] Verified and approved domains: navigaite.com added
- [ ] Organization secrets configured (shared across repos)

#### Third-party Access

- [ ] GitHub Apps reviewed and approved
- [ ] OAuth app policy: Access restriction enabled
- [ ] Personal access tokens: Approval required

#### Archive

- [ ] Audit log review scheduled (quarterly)

#### Teams & Permissions

- [ ] Teams created (engineering, frontend, backend, devops, qa, admins)
- [ ] Team permissions assigned to repositories
- [ ] CODEOWNERS file created

### Repository Settings

- [ ] Repository description and topics added
- [ ] Issues enabled
- [ ] Wikis disabled (use docs/ folder)
- [ ] Allow merge commits: ✅
- [ ] Allow squash merging: ✅
- [ ] Auto-delete branches: ✅
- [ ] Always suggest updating PRs: ✅
- [ ] Allow auto-merge: ✅

### Branch Protection

- [ ] `main` branch protection configured
  - [ ] Require PR (1+ approval)
  - [ ] Require status checks (setup, lint, test, build)
  - [ ] Require conversation resolution
  - [ ] Allow github-actions[bot] to bypass
- [ ] `dev` branch protection configured
  - [ ] Require PR (1 approval)
  - [ ] Same status checks as main
  - [ ] Allow github-actions[bot] to bypass

### Secrets Configuration

- [ ] `GH_TOKEN` or GitHub App credentials added
- [ ] Deployment provider secrets added:
  - [ ] Vercel: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
  - [ ] DigitalOcean: `DIGITALOCEAN_TOKEN`
  - [ ] Docker: `DOCKER_REGISTRY_USERNAME`, `DOCKER_REGISTRY_PASSWORD`
- [ ] Organization secrets added (if shared)
- [ ] Secrets verified (test workflow)

### Environments

- [ ] `preview` environment created (no protection)
- [ ] `staging` environment created (deploy from: dev)
- [ ] `production` environment created (deploy from: main, require reviewers)
- [ ] Deployment branch rules configured
- [ ] Environment-specific secrets added (if needed)

### Permissions

- [ ] Workflow permissions set to "Read and write" (Org level)
- [ ] Workflow permissions set to "Read and write" (Repo level)
- [ ] "Allow GitHub Actions to create and approve PRs" enabled

### Security (Free Alternatives)

- [ ] TruffleHog secret scanning (in pipeline)
- [ ] Trivy vulnerability scanning (nightly)
- [ ] Dependabot configured (.github/dependabot.yml)
- [ ] Pre-commit hooks created (.git-hooks/pre-commit)
- [ ] CODEOWNERS file added (.github/CODEOWNERS)

### Pipeline Configuration

- [ ] `.github/workflows/ci.yaml` created
- [ ] `.github/pipeline.yaml` configured
- [ ] `.github/release-please-config.json` committed
- [ ] `.github/dependabot.yml` committed
- [ ] Nightly maintenance workflow deployed

---

## 🔧 Testing Your Setup

### 1. Test Branch Protection

```bash
# Try to push directly to main (should fail)
git checkout main
echo "test" >> README.md
git commit -m "test: direct push"
git push origin main
# Expected: ❌ Error - branch protection

# Create PR instead (should work)
git checkout -b test/branch-protection
git push origin test/branch-protection
gh pr create --base main
# Expected: ✅ PR created, status checks run
```

### 2. Test Secrets

Create a test workflow:

```yaml
# .github/workflows/test-secrets.yaml
name: Test Secrets
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Check Secrets
        run: |
          echo "GH_TOKEN: ${{ secrets.GH_TOKEN != '' && 'SET' || 'MISSING' }}"
          echo "VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN != '' && 'SET' || 'MISSING' }}"
```

Run it manually: Actions → Test Secrets → Run workflow

### 3. Test Full Pipeline

```bash
# Create feature branch
git checkout -b feat/test-pipeline

# Make a change
echo "# Test" >> test.md
git add test.md
git commit -m "feat: test pipeline"

# Push and create PR
git push origin feat/test-pipeline
gh pr create --base dev --title "feat: test pipeline"

# Watch Actions tab
# Expected: All checks should run and pass
```

---

## 🆘 Troubleshooting

### "Resource not accessible by integration"

**Cause:** Insufficient permissions

**Fix:**

1. Check Settings → Actions → General → Workflow permissions
2. Enable "Read and write permissions"
3. Enable "Allow GitHub Actions to create and approve pull requests"

### "Protected branch update failed"

**Cause:** Trying to push to protected branch

**Fix:**

1. For `main`: Always use PRs
2. For auto-sync: Add `github-actions[bot]` to bypass list

### "Secret not found"

**Cause:** Secret name typo or not set

**Fix:**

1. Go to Settings → Secrets and variables → Actions
2. Check secret name matches exactly (case-sensitive)
3. Verify secret has a value (edit and re-save if needed)

### "Environment not found"

**Cause:** Environment doesn't exist or wrong name

**Fix:**

1. Go to Settings → Environments
2. Create environment with exact name from config
3. Name must match config file exactly (case-sensitive)

---

## 📚 Additional Resources

- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps)

---

**Next:** [Auto-Sync Feature Guide](./AUTO_SYNC_FEATURE.md)
