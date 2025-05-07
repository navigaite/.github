# CodeQL Security Analysis Integration

This document provides information about the CodeQL security analysis integration in our CI/CD pipeline.

## Overview

[CodeQL](https://securitylab.github.com/tools/codeql/) is GitHub's semantic code analysis engine that helps identify vulnerabilities and
errors in your code. CodeQL treats code as data, allowing you to find potential vulnerabilities in your code with greater confidence than
traditional static analyzers.

Our implementation consists of two primary workflows:

1. **Reusable Workflow** (`codeql-analysis-reusable.yml`): A reusable workflow that can be called from other workflows.
2. **Standalone Workflow** (`codeql-security-analysis.yml`): A standalone workflow that runs on schedule and push events.

## How It Works

CodeQL works by:

1. Building a database representation of your codebase
2. Running a suite of queries against that database
3. Producing results that highlight potential security vulnerabilities or code quality issues

## Workflow Details

### 1. Reusable CodeQL Workflow

This workflow can be used by other workflows as a job:

```yaml
codeql-analysis:
  name: CodeQL Security Analysis
  uses: ./.github/workflows/codeql-analysis-reusable.yml
  with:
    languages: 'javascript,typescript'
    queries: 'security-and-quality'
```

### 2. Standalone CodeQL Analysis

This workflow runs:

- On pushes to main and develop branches
- On pull requests targeting main branch
- Weekly on Sunday at midnight
- Manually through workflow_dispatch

## Configuration Options

When calling the reusable workflow, you can configure these parameters:

| Parameter    | Description                        | Default                                                          |
| ------------ | ---------------------------------- | ---------------------------------------------------------------- |
| languages    | Languages to analyze               | javascript,typescript                                            |
| queries      | Additional queries to run          | security-and-quality                                             |
| paths        | Paths to analyze (comma-separated) | (empty)                                                          |
| paths-ignore | Paths to ignore (comma-separated)  | node_modules/\*\*,\*\*/dist/\*\*,\*\*/.next/\*\*,\*\*/build/\*\* |

## Integration with NextJS Pipeline

CodeQL analysis has been integrated into our NextJS CI/CD pipeline. It runs in parallel with other security scans, and the test job waits
for its completion before proceeding.

## Viewing Results

Security issues identified by CodeQL can be viewed in the Security tab of your repository on GitHub, under "Code scanning alerts."

## Customization

To customize the CodeQL analysis:

1. For query suites, see
   [GitHub's documentation on CodeQL query suites](https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/built-in-codeql-query-suites)
2. To add custom queries, create a `.github/codeql/custom-queries` directory and reference it in the workflow

## Best Practices

- Review CodeQL alerts promptly
- Set up notifications for new security alerts
- Consider adding CodeQL checks as required status checks for protected branches
