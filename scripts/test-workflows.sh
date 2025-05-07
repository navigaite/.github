#!/bin/bash

# Test GitHub Actions workflows locally using Act
# This script uses Act to run the actual GitHub Actions workflow files

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
WORKFLOW_FILE=""
EVENT_TYPE="push"
BRANCH="develop"
RELEASE_VERSION=""
TEST_DIR="$(pwd)/act-test"

# Helper functions
print_section() {
	echo -e "${BLUE}========================================${NC}"
	echo -e "${BLUE}==== $1${NC}"
	echo -e "${BLUE}========================================${NC}"
}

show_usage() {
	echo -e "Usage: $0 [options]"
	echo -e ""
	echo -e "Options:"
	echo -e "  --workflow WORKFLOW    Specify workflow file to test (e.g., lint.yml, release.yml, nextjs-pipeline.yml)"
	echo -e "  --event EVENT_TYPE     Specify event type (push, pull_request, workflow_dispatch) [default: push]"
	echo -e "  --branch BRANCH        Specify branch name [default: develop]"
	echo -e "  --release VERSION      For testing release workflow: specify version (e.g., 1.0.0)"
	echo -e "  --help                 Show this help message"
	echo -e ""
	echo -e "Examples:"
	echo -e "  $0 --workflow lint.yml"
	echo -e "  $0 --workflow release.yml --event workflow_dispatch --branch release/1.0.0 --release 1.0.0"
	echo -e "  $0 --workflow nextjs-pipeline.yml --branch feature/new-feature"
	exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--workflow)
		WORKFLOW_FILE="$2"
		shift 2
		;;
	--event)
		EVENT_TYPE="$2"
		shift 2
		;;
	--branch)
		BRANCH="$2"
		shift 2
		;;
	--release)
		RELEASE_VERSION="$2"
		shift 2
		;;
	--help)
		show_usage
		;;
	*)
		echo -e "${RED}Unknown argument: $1${NC}"
		show_usage
		;;
	esac
done

# Check if act is installed
if ! command -v act &>/dev/null; then
	echo -e "${RED}Error: act is not installed. Please install it first:${NC}"
	echo -e "${YELLOW}brew install act${NC}"
	exit 1
fi

# Check required arguments
if [[ -z ${WORKFLOW_FILE} ]]; then
	echo -e "${RED}Error: --workflow is required${NC}"
	show_usage
fi

# Check if workflow file exists
if [[ ! -f ".github/workflows/${WORKFLOW_FILE}" ]]; then
	echo -e "${RED}Error: Workflow file .github/workflows/${WORKFLOW_FILE} does not exist${NC}"
	exit 1
fi

# Display test info
print_section "Workflow Test Configuration"
echo -e "Workflow File: ${CYAN}.github/workflows/${WORKFLOW_FILE}${NC}"
echo -e "Event Type: ${CYAN}${EVENT_TYPE}${NC}"
echo -e "Branch: ${CYAN}${BRANCH}${NC}"
if [[ -n ${RELEASE_VERSION} ]]; then
	echo -e "Release Version: ${CYAN}${RELEASE_VERSION}${NC}"
fi

# Create test environment
print_section "Setting up test environment"

# Create .env file for act
echo -e "Creating .env file for act..."
cat >.env <<EOL
GITHUB_REPOSITORY=test-org/test-repo
GITHUB_SHA=$(git rev-parse HEAD)
GITHUB_REF=refs/heads/${BRANCH}
EOL

if [[ ${BRANCH} == release/* || ${BRANCH} == hotfix/* ]]; then
	echo -e "Setting up release environment..."
	# Add VERSION env variable for release workflow
	if [[ -z ${RELEASE_VERSION} ]]; then
		# Extract version from branch name
		RELEASE_VERSION=${BRANCH#*/}
		echo -e "Extracted version from branch name: ${CYAN}${RELEASE_VERSION}${NC}"
	fi
	echo "VERSION=${RELEASE_VERSION}" >>.env
fi

# Create event payload file
print_section "Creating event payload"
if [[ ${EVENT_TYPE} == "workflow_dispatch" ]]; then
	if [[ ${WORKFLOW_FILE} == "release.yml" ]]; then
		echo -e "Creating workflow_dispatch event for release workflow..."
		cat >event.json <<EOL
{
  "inputs": {
    "release": true
  },
  "ref": "refs/heads/${BRANCH}"
}
EOL
	else
		echo -e "Creating generic workflow_dispatch event..."
		cat >event.json <<EOL
{
  "inputs": {},
  "ref": "refs/heads/${BRANCH}"
}
EOL
	fi
elif [[ ${EVENT_TYPE} == "pull_request" ]]; then
	echo -e "Creating pull_request event..."
	cat >event.json <<EOL
{
  "pull_request": {
    "base": {
      "sha": "$(git rev-parse HEAD~1)",
      "ref": "main"
    },
    "head": {
      "sha": "$(git rev-parse HEAD)",
      "ref": "${BRANCH}"
    }
  },
  "ref": "refs/heads/${BRANCH}"
}
EOL
else
	# Default push event
	echo -e "Creating push event..."
	cat >event.json <<EOL
{
  "ref": "refs/heads/${BRANCH}"
}
EOL
fi

# Create custom secrets file for act
# Note: In a real setup, you'd want to use real test values here
print_section "Setting up test secrets"
cat >.secrets <<EOL
GITHUB_TOKEN=test_github_token
APP_ID=test_app_id
APP_PRIVATE_KEY=test_private_key
OPENAI_API_KEY=test_openai_key
EOL

# Run the workflow using act
print_section "Running workflow .github/workflows/${WORKFLOW_FILE} with act"
echo -e "${YELLOW}This will run GitHub Actions in a local Docker container${NC}"
echo -e "${YELLOW}Note: Some features like GitHub API calls may not work as expected${NC}"
echo -e ""

# Run with -v flag for verbose output
echo -e "Running: act --workflows=.github/workflows/${WORKFLOW_FILE} --eventpath=event.json --env-file=.env --secret-file=.secrets -v ${EVENT_TYPE}"
act --workflows=.github/workflows/"${WORKFLOW_FILE}" --eventpath=event.json --env-file=.env --secret-file=.secrets -v "${EVENT_TYPE}"

EXIT_CODE=$?

# Clean up
print_section "Cleaning up temporary files"
rm -f event.json .env .secrets

if [[ ${EXIT_CODE} -eq 0 ]]; then
	echo -e "${GREEN}Workflow test completed successfully!${NC}"
else
	echo -e "${RED}Workflow test failed with exit code ${EXIT_CODE}${NC}"
fi

# Tips for troubleshooting
echo -e ""
echo -e "${YELLOW}Tips for troubleshooting:${NC}"
echo -e "1. Try running with '-v' flag for verbose output"
echo -e "2. Some GitHub functions might not work locally (e.g., GitHub API calls)"
echo -e "3. Check act documentation for more options: https://github.com/nektos/act"

exit "${EXIT_CODE}"
