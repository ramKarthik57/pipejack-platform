# PipeJack Continuous Integration Workflow

This directory contains the production-ready GitHub Actions Continuous Integration pipeline specification for PipeJack:

- **[`pipejack-ci.yml`](pipejack-ci.yml)**: Automated quality gate validating:
  - Repository checkout
  - Go toolchain (`go 1.25.0`)
  - Code formatting (`gofmt -l`)
  - Core security engine unit tests (`core/pipejack`) with race condition detection
  - Static analysis (`go vet ./...`)
  - Daemon and CLI compilation checks (`cmd/pipejackd`, `cmd/proctree`)
  - CI Orchestrator unit tests and compilation (`services/custom-ci`)
  - Multi-pattern secret and credential hygiene scanning

## Activation

To activate this workflow directly within GitHub Actions, copy it to the repository's `.github/workflows/` path:

```bash
mkdir -p .github/workflows
cp deployment/ci/pipejack-ci.yml .github/workflows/pipejack-ci.yml
git add .github/workflows/pipejack-ci.yml
git commit -m "ci: activate GitHub Actions workflow"
git push origin main
```

*(Note: Pushing changes to `.github/workflows/` on GitHub requires an authentication token with the explicit `workflow` scope).*
