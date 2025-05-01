# Integration Guide: Navigaite CI/CD Pipeline

This guide provides step-by-step instructions for integrating the Navigaite CI/CD pipeline into your NextJS project.

## Prerequisites

- GitHub repository for your NextJS project
- Vercel account and project set up
- Administrator access to configure GitHub Actions and repository secrets

## Step 1: Add Required Secrets to Your Repository

1. Navigate to your GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `VERCEL_TOKEN`: Your Vercel deployment token
   - `VERCEL_PROJECT_ID`: Your Vercel project ID

### Getting Your Vercel Token

1. Go to your Vercel account settings
2. Navigate to Tokens
3. Create a new token with appropriate permissions
4. Copy the token value

### Getting Your Vercel Project ID

1. Go to your Vercel dashboard
2. Select your project
3. Go to Settings → General
4. Copy the Project ID

## Step 2: Add the Workflow File to Your Repository

Create a new file in your repository at `.github/workflows/ci-cd.yml` with the content from the [example workflow](./example-workflow.yml).

Customize the configuration as needed for your project:

- Adjust the Node.js version if required
- Change branch names if your GitFlow setup differs from the standard

## Step 3: Configure Linting Tools

### Setting up Trunk Check

1. Copy the Trunk configuration from this repository:

   ```bash
   mkdir -p .trunk
   cp /path/to/navigaite/workflow-test/config/.trunk/trunk.yaml .trunk/
   ```

2. Install Trunk CLI locally (optional for development):
   ```bash
   curl -fsSL https://get.trunk.io -o get-trunk.sh
   bash get-trunk.sh
   ```

### Setting up Commitlint

1. Install the required dependencies:

   ```bash
   npm install --save-dev @commitlint/cli @commitlint/config-conventional
   ```

2. Copy the commitlint config from this repository:
   ```bash
   cp /path/to/navigaite/workflow-test/config/commitlint.config.js ./
   ```

### Setting up Open Commits

1. Install Open Commits:

   ```bash
   npm install --save-dev @di-sukharev/opencommit
   ```

2. Copy the Open Commits config:
   ```bash
   cp /path/to/navigaite/workflow-test/config/oc.config.js ./
   ```

## Step 4: Configure GitFlow in Your Repository

Ensure your repository is set up with the following branches:

- `main`: Production code
- `develop`: Integration branch
- `feature/*`: Feature branches
- `release/*`: Release branches
- `hotfix/*`: Hotfix branches

### Branch Protection Rules

Configure branch protection rules for `main` and `develop` branches:

1. Go to Settings → Branches → Branch protection rules
2. Add rules for both `main` and `develop` branches:
   - Require pull requests before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging

## Step 5: Creating Releases

To create a new release:

1. Create a release branch from develop:

   ```bash
   git checkout develop
   git checkout -b release/x.y.z
   ```

2. Push the release branch:

   ```bash
   git push origin release/x.y.z
   ```

3. Trigger the release workflow manually:
   - Go to Actions → CI/CD Pipeline → Run workflow
   - Select the release branch
   - Check "Trigger a release"
   - Click "Run workflow"

## Troubleshooting

### Common Issues

1. **Vercel Deployment Fails**:

   - Check that VERCEL_TOKEN and VERCEL_PROJECT_ID are correctly set
   - Ensure your Vercel token has the correct permissions

2. **Missing Steps in Pipeline**:

   - Verify that your workflow file is correctly referencing the main workflow repository

3. **Commitlint Failures**:
   - Ensure commits follow the conventional commit format
   - Check that commitlint.config.js is correctly set up

### Getting Help

If you encounter any issues, please contact the DevOps team or open an issue in the workflow-test repository.
