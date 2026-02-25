# 🛍️ GitHub Actions Marketplace - Curated List

This document lists all the proven, high-quality GitHub Actions from the marketplace that are used or recommended for the Universal Pipeline
v2.

## ✅ Currently Used Actions

### Core Actions (by GitHub)

| Action                                                                | Version | Purpose                        | Stars | Maintained |
| --------------------------------------------------------------------- | ------- | ------------------------------ | ----- | ---------- |
| [actions/checkout](https://github.com/actions/checkout)               | v4      | Checkout repository code       | 6k+   | ✅ GitHub  |
| [actions/setup-node](https://github.com/actions/setup-node)           | v4      | Setup Node.js                  | 3.7k+ | ✅ GitHub  |
| [actions/setup-python](https://github.com/actions/setup-python)       | v5      | Setup Python                   | 1.5k+ | ✅ GitHub  |
| [actions/upload-artifact](https://github.com/actions/upload-artifact) | v4      | Upload build artifacts         | 3.1k+ | ✅ GitHub  |
| [actions/github-script](https://github.com/actions/github-script)     | v7      | Run JavaScript with GitHub API | 4k+   | ✅ GitHub  |
| [github/codeql-action](https://github.com/github/codeql-action)       | v3      | Security analysis              | 1.1k+ | ✅ GitHub  |

### Release & Version Management

| Action                                                                                  | Version | Purpose                           | Stars | Maintained |
| --------------------------------------------------------------------------------------- | ------- | --------------------------------- | ----- | ---------- |
| [googleapis/release-please-action](https://github.com/googleapis/release-please-action) | v4      | Automated releases with changelog | 3k+   | ✅ Google  |

### Security Scanning

| Action                                                                                  | Version | Purpose                    | Stars | Maintained       |
| --------------------------------------------------------------------------------------- | ------- | -------------------------- | ----- | ---------------- |
| [trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)             | main    | Secrets scanning           | 15k+  | ✅ TruffleHog    |
| [actions/dependency-review-action](https://github.com/actions/dependency-review-action) | v4      | Dependency vulnerabilities | 300+  | ✅ GitHub        |
| [aquasecurity/trivy-action](https://github.com/aquasecurity/trivy-action)               | master  | Container security scanner | 1k+   | ✅ Aqua Security |

### Deployment

| Action                                                                      | Version | Purpose                       | Stars | Maintained      |
| --------------------------------------------------------------------------- | ------- | ----------------------------- | ----- | --------------- |
| [digitalocean/app_action](https://github.com/digitalocean/app_action)       | v1.1.5  | Deploy to DigitalOcean        | 100+  | ✅ DigitalOcean |
| [docker/login-action](https://github.com/docker/login-action)               | v3      | Login to container registries | 1.2k+ | ✅ Docker       |
| [docker/metadata-action](https://github.com/docker/metadata-action)         | v5      | Extract Docker metadata       | 700+  | ✅ Docker       |
| [docker/build-push-action](https://github.com/docker/build-push-action)     | v5      | Build and push Docker images  | 4.2k+ | ✅ Docker       |
| [docker/setup-buildx-action](https://github.com/docker/setup-buildx-action) | v3      | Setup Docker Buildx           | 1k+   | ✅ Docker       |
| [docker/setup-qemu-action](https://github.com/docker/setup-qemu-action)     | v3      | Setup QEMU for multi-arch     | 600+  | ✅ Docker       |

### Flutter/Mobile

| Action                                                                | Version | Purpose           | Stars | Maintained   |
| --------------------------------------------------------------------- | ------- | ----------------- | ----- | ------------ |
| [subosito/flutter-action](https://github.com/subosito/flutter-action) | v2      | Setup Flutter SDK | 2.2k+ | ✅ Community |

### Testing & Coverage

| Action                                                              | Version | Purpose                    | Stars | Maintained |
| ------------------------------------------------------------------- | ------- | -------------------------- | ----- | ---------- |
| [codecov/codecov-action](https://github.com/codecov/codecov-action) | v4      | Upload coverage to Codecov | 1.4k+ | ✅ Codecov |

### Maintenance

| Action                                                                            | Version | Purpose                   | Stars | Maintained   |
| --------------------------------------------------------------------------------- | ------- | ------------------------- | ----- | ------------ |
| [Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs) | v2      | Cleanup old workflow runs | 300+  | ✅ Community |

---

## 🚀 Recommended Additional Actions

### Dependency Management

| Action                                                                    | Purpose                      | Why Use It                                  | Stars    |
| ------------------------------------------------------------------------- | ---------------------------- | ------------------------------------------- | -------- |
| [dependabot](https://docs.github.com/en/code-security/dependabot)         | Automated dependency updates | Native GitHub, free, secure                 | Built-in |
| [renovatebot/github-action](https://github.com/renovatebot/github-action) | Alternative to Dependabot    | More customizable, supports more ecosystems | 1.5k+    |

### Code Quality

| Action                                                                    | Purpose                    | Why Use It                   | Stars |
| ------------------------------------------------------------------------- | -------------------------- | ---------------------------- | ----- |
| [trunk-io/trunk-action](https://github.com/trunk-io/trunk-action)         | Universal linter/formatter | Single tool for all linters  | 200+  |
| [reviewdog/action-setup](https://github.com/reviewdog/action-setup)       | Automated code review      | PR comments with suggestions | 7.7k+ |
| [super-linter/super-linter](https://github.com/super-linter/super-linter) | Multi-language linter      | One action for all languages | 9.4k+ |

### Performance & Optimization

| Action                                                                                | Purpose                  | Why Use It                    | Stars |
| ------------------------------------------------------------------------------------- | ------------------------ | ----------------------------- | ----- |
| [preactjs/compressed-size-action](https://github.com/preactjs/compressed-size-action) | Track bundle size        | Prevent bloat                 | 600+  |
| [CodSpeedHQ/action](https://github.com/CodSpeedHQ/action)                             | Performance benchmarking | Track performance regressions | 100+  |

### Notifications

| Action                                                                  | Purpose             | Why Use It     | Stars |
| ----------------------------------------------------------------------- | ------------------- | -------------- | ----- |
| [8398a7/action-slack](https://github.com/8398a7/action-slack)           | Slack notifications | Team awareness | 1.1k+ |
| [dawidd6/action-send-mail](https://github.com/dawidd6/action-send-mail) | Email notifications | Email alerts   | 800+  |

### Caching

| Action                                                                              | Purpose            | Why Use It           | Stars |
| ----------------------------------------------------------------------------------- | ------------------ | -------------------- | ----- |
| [actions/cache](https://github.com/actions/cache)                                   | Cache dependencies | Faster builds        | 4.4k+ |
| [mozilla-actions/sccache-action](https://github.com/mozilla-actions/sccache-action) | Compiler cache     | Speed up compilation | 100+  |

### Documentation

| Action                                                                                          | Purpose                     | Why Use It            | Stars |
| ----------------------------------------------------------------------------------------------- | --------------------------- | --------------------- | ----- |
| [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) | Deploy to GitHub Pages      | Free hosting for docs | 4.2k+ |
| [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)                     | Alternative GH Pages deploy | More features         | 4.6k+ |

### Deployment Helpers

| Action                                                                                            | Purpose                      | Why Use It     | Stars |
| ------------------------------------------------------------------------------------------------- | ---------------------------- | -------------- | ----- |
| [cloudflare/wrangler-action](https://github.com/cloudflare/wrangler-action)                       | Deploy to Cloudflare Workers | Edge computing | 1.2k+ |
| [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials) | AWS authentication           | Deploy to AWS  | 1k+   |
| [google-github-actions/auth](https://github.com/google-github-actions/auth)                       | GCP authentication           | Deploy to GCP  | 300+  |

### Testing

| Action                                                                                      | Purpose               | Why Use It              | Stars |
| ------------------------------------------------------------------------------------------- | --------------------- | ----------------------- | ----- |
| [cypress-io/github-action](https://github.com/cypress-io/github-action)                     | Run Cypress E2E tests | Official Cypress action | 1.2k+ |
| [microsoft/playwright-github-action](https://github.com/microsoft/playwright-github-action) | Run Playwright tests  | Cross-browser testing   | 300+  |
| [k6io/action](https://github.com/grafana/k6-action)                                         | Load testing with k6  | Performance testing     | 400+  |

---

## 🎯 Action Selection Criteria

When choosing GitHub Actions, we prioritize:

1. **✅ Official & Verified** - Actions by GitHub, Google, Docker, etc.
2. **⭐ High Stars & Usage** - Popular, battle-tested
3. **🔄 Actively Maintained** - Recent updates, responsive maintainers
4. **📚 Good Documentation** - Clear usage examples
5. **🔒 Security** - No known vulnerabilities, trusted publisher
6. **🚀 Performance** - Fast execution, efficient caching
7. **🎨 Good DX** - Easy to configure, helpful errors

---

## 🔧 Implementation Status

### ✅ Already Integrated

- Setup (Node, Python, Flutter)
- Dependency installation & caching
- Security scanning (TruffleHog, Trivy, Dependency Review)
- Release automation (Release Please)
- Docker deployment (multi-arch, multi-registry)
- Vercel & DigitalOcean deployment
- Workflow cleanup

### 🚧 Recommended Next Steps

1. **Add Dependabot** - Create `.github/dependabot.yml`
2. **Add Super Linter** - Consolidate linting (or keep Trunk)
3. **Add Slack notifications** - For deployment alerts
4. **Add Codecov** - For test coverage tracking (already supported)
5. **Add Playwright/Cypress** - For E2E testing
6. **Add bundle size tracking** - For frontend projects

---

## 💡 Pro Tips

### Cache Everything

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

### Matrix Builds

```yaml
strategy:
  matrix:
    node-version: [18, 20, 22]
    os: [ubuntu-latest, windows-latest, macos-latest]
```

### Conditional Steps

```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

### Reusable Workflows

```yaml
# .github/workflows/reusable.yaml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
```

---

## 📚 Resources

- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Awesome Actions List](https://github.com/sdras/awesome-actions)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Action Versioning Best Practices](https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-release-management-for-actions)

---

**Last Updated:** 2025-12-09

**Maintained By:** Universal Pipeline v2 Team
