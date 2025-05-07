#!/bin/bash

# Simulation script for testing the CI/CD pipeline locally
# This script mimics the behavior of the GitHub Actions workflow

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
NODE_VERSION="18"
TRUNK_AUTO_FIX=false
WORKFLOW_TYPE="standard"
RELEASE_BRANCH=""
VERSION=""

# Helper functions
print_section() {
	echo -e "${BLUE}========================================${NC}"
	echo -e "${BLUE}==== $1${NC}"
	echo -e "${BLUE}========================================${NC}"
}

run_cmd() {
	echo -e "${YELLOW}\$ $1${NC}"
	eval "$1"
	local EXIT_CODE=$?
	if [[ ${EXIT_CODE} -ne 0 ]]; then
		echo -e "${RED}Command failed with exit code ${EXIT_CODE}${NC}"
		exit "${EXIT_CODE}"
	fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--workflow)
		WORKFLOW_TYPE="$2"
		shift 2
		;;
	--release)
		RELEASE_BRANCH="$2"
		shift 2
		;;
	--version)
		VERSION="$2"
		shift 2
		;;
	--trunk-auto-fix)
		TRUNK_AUTO_FIX=true
		shift
		;;
	*)
		echo -e "${RED}Unknown argument: $1${NC}"
		exit 1
		;;
	esac
done

# Display simulation info
print_section "Pipeline Simulation Info"
echo -e "Workflow Type: ${CYAN}${WORKFLOW_TYPE}${NC}"
echo -e "Node Version: ${CYAN}${NODE_VERSION}${NC}"
echo -e "Trunk Auto Fix: ${CYAN}${TRUNK_AUTO_FIX}${NC}"

if [[ ${WORKFLOW_TYPE} == "release" ]]; then
	if [[ -z ${RELEASE_BRANCH} ]]; then
		echo -e "${RED}Error: Release workflow requires --release parameter with branch name${NC}"
		exit 1
	fi
	if [[ -z ${VERSION} ]]; then
		# Extract version from release branch
		if [[ ${RELEASE_BRANCH} == release/* ]]; then
			VERSION=${RELEASE_BRANCH#release/}
			echo -e "Extracted version from branch name: ${CYAN}${VERSION}${NC}"
		elif [[ ${RELEASE_BRANCH} == hotfix/* ]]; then
			VERSION=${RELEASE_BRANCH#hotfix/}
			echo -e "Extracted version from branch name: ${CYAN}${VERSION}${NC}"
		else
			echo -e "${RED}Error: Release branch must start with 'release/' or 'hotfix/'${NC}"
			exit 1
		fi
	fi
	echo -e "Release Branch: ${CYAN}${RELEASE_BRANCH}${NC}"
	echo -e "Version: ${CYAN}${VERSION}${NC}"
fi

echo ""
echo -e "${GREEN}Starting simulation...${NC}"
echo ""

# Create a temporary directory for simulation
TEMP_DIR=$(mktemp -d)
echo -e "Creating temporary workspace at ${CYAN}${TEMP_DIR}${NC}"

# Copy project files to temp directory
run_cmd "cp -R $(pwd)/* ${TEMP_DIR}/"
cd "${TEMP_DIR}" || exit

# Create a minimal package.json if it doesn't exist
if [[ ! -f "package.json" ]]; then
	print_section "Creating minimal package.json"
	cat >package.json <<EOL
{
  "name": "workflow-test",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "lint": "eslint ."
  },
  "devDependencies": {
    "@commitlint/cli": "^17.0.0",
    "@commitlint/config-conventional": "^17.0.0"
  }
}
EOL
fi

# Initialize Git repository if not already
if [[ ! -d ".git" ]]; then
	print_section "Initializing Git repository"
	run_cmd "git init"
	run_cmd 'git config user.name "Simulation User"'
	run_cmd 'git config user.email "simulation@example.com"'
	run_cmd "git add ."
	run_cmd 'git commit -m "chore: initial commit"'

	# Create branches
	run_cmd "git branch develop"
	run_cmd "git branch main"
fi

if [[ ${WORKFLOW_TYPE} == "lint" ]]; then
	# Simulate lint workflow
	print_section "Simulating Lint Workflow"

	# Install dependencies
	print_section "Installing dependencies"
	if command -v npm &>/dev/null; then
		run_cmd "npm install"
	else
		echo -e "${YELLOW}npm not found, skipping dependency installation${NC}"
	fi

	# Check if trunk is installed
	if command -v trunk &>/dev/null; then
		print_section "Running Trunk Check"
		if [[ ${TRUNK_AUTO_FIX} == true ]]; then
			run_cmd "trunk check --all --fix || true"
		else
			run_cmd "trunk check --all || true"
		fi
	else
		echo -e "${YELLOW}Trunk not found, skipping trunk checks${NC}"
		echo -e "${YELLOW}To install trunk: curl -fsSL https://get.trunk.io -o get-trunk.sh && bash get-trunk.sh${NC}"
	fi

	# Simulate commitlint
	print_section "Checking commit messages with commitlint"
	if command -v npx &>/dev/null; then
		run_cmd "npx commitlint --from HEAD~10 --to HEAD || true"
	else
		echo -e "${YELLOW}npx not found, skipping commitlint${NC}"
	fi

elif [[ ${WORKFLOW_TYPE} == "pipeline" ]]; then
	# Simulate nextjs-pipeline workflow
	print_section "Simulating NextJS Pipeline Workflow"

	# Install dependencies
	print_section "Installing dependencies"
	if command -v npm &>/dev/null; then
		run_cmd "npm install"
	else
		echo -e "${YELLOW}npm not found, skipping dependency installation${NC}"
	fi

	# Lint check
	print_section "Running lint checks"
	if command -v trunk &>/dev/null; then
		run_cmd "trunk check --all || true"
	else
		echo -e "${YELLOW}Trunk not found, skipping trunk checks${NC}"
	fi

	# Run tests if package.json has a test script
	if grep -q '"test":' "package.json"; then
		print_section "Running tests"
		run_cmd "npm test || true"
	else
		echo -e "${YELLOW}No test script found in package.json, skipping tests${NC}"
	fi

	# Build
	print_section "Building project"
	if grep -q '"build":' "package.json"; then
		run_cmd "npm run build || true"
	else
		echo -e "${YELLOW}No build script found in package.json, skipping build${NC}"
	fi

	print_section "Pipeline simulation completed"
	echo -e "${GREEN}In a real workflow, deployment preview would occur here${NC}"

elif [[ ${WORKFLOW_TYPE} == "release" ]]; then
	# Simulate release workflow
	print_section "Simulating Release Workflow"

	# Checkout or create the release branch
	run_cmd "git checkout -b ${RELEASE_BRANCH} 2>/dev/null || git checkout ${RELEASE_BRANCH}"

	# Update version in package.json
	print_section "Updating version in package.json"
	run_cmd "npm version ${VERSION} --no-git-tag-version"
	run_cmd "git add package.json package-lock.json 2>/dev/null || git add package.json"
	run_cmd "git commit -m \"chore: bump version to ${VERSION}\""

	# Find previous tag or use default
	PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
	if [[ -z ${PREV_TAG} ]]; then
		echo -e "${YELLOW}No previous tag found, using all history for changelog${NC}"
	else
		echo -e "Previous tag: ${CYAN}${PREV_TAG}${NC}"
	fi

	# Generate changelog
	print_section "Generating changelog"

	# Install required packages for changelog generation
	run_cmd "npm install --no-save axios @octokit/rest conventional-changelog-parser"

	# Create a simple changelog generator script
	cat >generate-simple-changelog.js <<'EOL'
const fs = require('fs');
const { execSync } = require('child_process');

// Get command line args
const version = process.argv[2];
const prevTag = process.argv[3] || '';

console.log(`Generating changelog for version ${version} since ${prevTag || 'beginning'}`);

// Get commits
let commitData = '';
try {
  if (prevTag) {
    commitData = execSync(`git log ${prevTag}..HEAD --pretty=format:"%h %s (%an)" --no-merges`).toString();
  } else {
    commitData = execSync('git log --pretty=format:"%h %s (%an)" --no-merges -n 100').toString();
  }
} catch (error) {
  console.error('Error getting commit data:', error.message);
  process.exit(1);
}

// Parse conventional commits
const commits = commitData.split('\n').filter(line => line.trim() !== '');
const categorizedCommits = {
  features: [],
  fixes: [],
  docs: [],
  chore: [],
  other: []
};

commits.forEach(commit => {
  const match = commit.match(/^[a-f0-9]+ (feat|fix|docs|chore|refactor|test|style|perf|build|ci|revert)(\([^)]+\))?:\s*(.+)/i);
  if (match) {
    const [, type, , message] = match;

    if (type.toLowerCase() === 'feat') {
      categorizedCommits.features.push(commit);
    } else if (type.toLowerCase() === 'fix') {
      categorizedCommits.fixes.push(commit);
    } else if (type.toLowerCase() === 'docs') {
      categorizedCommits.docs.push(commit);
    } else if (['chore', 'refactor', 'test', 'style', 'perf', 'build', 'ci'].includes(type.toLowerCase())) {
      categorizedCommits.chore.push(commit);
    } else {
      categorizedCommits.other.push(commit);
    }
  } else {
    categorizedCommits.other.push(commit);
  }
});

// Generate markdown
let changelog = `# Release v${version}\n\n`;

if (categorizedCommits.features.length > 0) {
  changelog += `## 🌟 Enhancements\n\n`;
  categorizedCommits.features.forEach(commit => {
    changelog += `- ${commit}\n`;
  });
  changelog += '\n';
}

if (categorizedCommits.fixes.length > 0) {
  changelog += `## 🐛 Bug Fixes\n\n`;
  categorizedCommits.fixes.forEach(commit => {
    changelog += `- ${commit}\n`;
  });
  changelog += '\n';
}

if (categorizedCommits.docs.length > 0) {
  changelog += `## 📚 Documentation\n\n`;
  categorizedCommits.docs.forEach(commit => {
    changelog += `- ${commit}\n`;
  });
  changelog += '\n';
}

if (categorizedCommits.chore.length > 0) {
  changelog += `## ⚙️ Other Changes\n\n`;
  categorizedCommits.chore.forEach(commit => {
    changelog += `- ${commit}\n`;
  });
  changelog += '\n';
}

if (categorizedCommits.other.length > 0) {
  changelog += `## Other\n\n`;
  categorizedCommits.other.forEach(commit => {
    changelog += `- ${commit}\n`;
  });
  changelog += '\n';
}

changelog += `**Full Changelog**: ${prevTag ? `${prevTag}...v${version}` : `...v${version}`}\n`;

// Write to file
fs.writeFileSync('CHANGELOG.md', changelog);
console.log('Changelog written to CHANGELOG.md');
EOL

	run_cmd "node generate-simple-changelog.js ${VERSION} \"${PREV_TAG}\""

	# Display the generated changelog
	print_section "Generated Changelog"
	cat CHANGELOG.md

	# Create git tag
	print_section "Creating git tag"
	run_cmd "git tag -a v${VERSION} -m \"Release v${VERSION}\""

	# Simulate merging to main
	print_section "Simulating merge to main"
	run_cmd "git checkout main"
	run_cmd "git merge --no-ff ${RELEASE_BRANCH} -m \"chore(release): merge ${RELEASE_BRANCH} into main\""

	# Simulate merging to develop
	print_section "Simulating back-merge to develop"
	run_cmd "git checkout develop"
	run_cmd "git merge --no-ff main -m \"chore(back-merge): sync main into develop after v${VERSION}\""

	print_section "Release simulation completed"
	echo -e "${GREEN}In a real workflow, a GitHub Release would be created here${NC}"

else
	echo -e "${RED}Unsupported workflow type: ${WORKFLOW_TYPE}${NC}"
	exit 1
fi

print_section "Simulation completed successfully"
echo -e "${GREEN}Temporary workspace is at: ${TEMP_DIR}${NC}"
echo -e "${GREEN}You can navigate there to inspect the results${NC}"
echo -e "${YELLOW}Don't forget to delete the temporary directory when done:${NC}"
echo -e "${YELLOW}rm -rf ${TEMP_DIR}${NC}"
