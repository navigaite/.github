#!/bin/bash

# =================================================================
# Navigaite CI/CD Pipeline Setup Script
# -----------------------------------------------------------------
# Purpose: Set up a NextJS project with Navigaite CI/CD workflows
# Author: Navigaite Team
# Last Updated: April 30, 2025
# =================================================================

# Color codes for beautiful terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions for consistent logging
log_header() {
  echo -e "\n${BOLD}${BLUE}=======================================================${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${BOLD}${BLUE}=======================================================${NC}\n"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_info() {
  echo -e "${CYAN}ℹ️  $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

log_step() {
  echo -e "${PURPLE}🔷 $1${NC}"
}

# Script start
log_header "Navigaite CI/CD Pipeline Setup"
log_info "This script will integrate Navigaite CI/CD workflows into your NextJS project"

# Create GitHub Actions workflow directory
log_step "Creating .github/workflows directory..."
mkdir -p .github/workflows
log_success "Directory structure created"

# Create workflow file
log_step "Creating CI/CD workflow file..."
cat > .github/workflows/ci-cd.yml << 'EOL'
name: CI/CD Pipeline

on:
  push:
    branches: [develop, main, 'feature/**', 'hotfix/**', 'release/**']
  pull_request:
    branches: [develop, main]
  workflow_dispatch:
    inputs:
      release:
        description: 'Trigger a release'
        required: false
        type: boolean
        default: false

jobs:
  # Standard Pipeline for feature branches and PRs
  standard-pipeline:
    if: ${{ !github.event.inputs.release }}
    uses: navigaite/workflow-test/.github/workflows/nextjs-pipeline.yml@main
    with:
      node-version: '18'
      vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
      trunk-auto-fix: false
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
      github-token: ${{ secrets.GITHUB_TOKEN }}

  # Release management (triggered manually)
  release:
    if: ${{ github.event.inputs.release && startsWith(github.ref, 'refs/heads/release/') }}
    uses: navigaite/workflow-test/.github/workflows/release.yml@main
    with:
      node-version: '18'
      production-branch: 'main'
      develop-branch: 'develop'
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
EOL
log_success "CI/CD workflow file created: .github/workflows/ci-cd.yml"

# Setup Trunk
log_step "Setting up Trunk for code quality checks..."
mkdir -p .trunk
cat > .trunk/trunk.yaml << 'EOL'
version: 0.1
cli:
  version: 1.16.0
plugins:
  sources:
    - id: trunk
      ref: v1.2.5
      uri: https://github.com/trunk-io/plugins
runtimes:
  enabled:
    - node@18.12.1
    - python@3.10.8
lint:
  enabled:
    - eslint@8.54.0
    - prettier@3.1.0
    - git-diff-check
    - markdownlint@0.37.0
    - actionlint@1.6.26
    - gitleaks@8.18.0
    - yamllint@1.32.0
  ignore:
    - linters: [ALL]
      paths:
        - node_modules/**
        - .next/**
        - build/**
        - dist/**
        - coverage/**
EOL
log_success "Trunk configuration created: .trunk/trunk.yaml"

# Setup commitlint configuration
log_step "Setting up commitlint configuration..."
cat > commitlint.config.js << 'EOL'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'body-leading-blank': [1, 'always'],
    'body-max-line-length': [2, 'always', 100],
    'footer-leading-blank': [1, 'always'],
    'footer-max-line-length': [2, 'always', 100],
    'header-max-length': [2, 'always', 100],
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [
      2,
      'never',
      ['sentence-case', 'start-case', 'pascal-case', 'upper-case'],
    ],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'type-enum': [
      2,
      'always',
      [
        'build',
        'chore',
        'ci',
        'docs',
        'feat',
        'fix',
        'perf',
        'refactor',
        'revert',
        'style',
        'test',
      ],
    ],
  },
};
EOL
log_success "Commitlint configuration created: commitlint.config.js"

# Setup Open Commits configuration
log_step "Setting up Open Commits configuration..."
cat > oc.config.js << 'EOL'
module.exports = {
  commit: {
    conventional: true,
    maxSubjectLength: 72,
    maxBodyLineLength: 100,
  },
  scope: {
    autoDetect: true,
    allowMultiple: true,
  },
  hooks: {
    preCommit: true,
  },
  format: {
    capitalizeFirstLetter: false,
    addPeriod: false,
  }
};
EOL
log_success "Open Commits configuration created: oc.config.js"

# Install necessary npm packages
log_step "Installing required npm packages..."
npm install --save-dev @commitlint/cli @commitlint/config-conventional
log_success "Required npm packages installed"

# Add husky for git hooks
log_step "Installing husky for git hooks..."
npm install --save-dev husky
log_success "Husky installed"

# Setup husky
log_step "Setting up husky..."
npx husky install
npm pkg set scripts.prepare="husky install"
log_success "Husky setup complete"

# Add commitlint hook
log_step "Adding commitlint hook..."
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
log_success "Commitlint hook added"

# Setup complete
log_header "Setup Complete!"
log_info "Your project is now configured with Navigaite CI/CD workflows"
log_info "You can trigger workflows by pushing to feature/*, hotfix/*, or release/* branches"
log_info "For manual releases, use the workflow_dispatch event in GitHub Actions"

# Optional next steps
log_warning "Make sure your repository has the required secrets set up:"
echo -e "  - ${YELLOW}VERCEL_TOKEN${NC}"
echo -e "  - ${YELLOW}VERCEL_PROJECT_ID${NC}"
echo -e "  - ${YELLOW}GITHUB_TOKEN${NC} (usually available by default)"

echo ""
log_info "📋 Next steps:"
echo "1. Add VERCEL_TOKEN and VERCEL_PROJECT_ID secrets to your GitHub repository"
echo "2. Push this configuration to your repository"
echo "3. Create the develop and main branches if they don't exist"
echo ""
log_info "For more information, see the integration guide at: https://github.com/navigaite/workflow-test/blob/main/docs/INTEGRATION_GUIDE.md"
