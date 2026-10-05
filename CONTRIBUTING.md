# Contributing to PipeJack

Thank you for your interest in contributing to the PipeJack Zero-Trust CI/CD Security Platform!

## Development Guidelines

1. **Two-VM Collaboration Model**:
   - VM-1 acts as the Developer / QA / Attack scenario author.
   - VM-2 acts as the Security / CI Integration / Attestation maintainer.
2. **Coding Standards**:
   - Go: Run `go fmt ./...`, `go vet ./...`, and ensure `go test -race ./...` passes.
   - Python: Follow PEP 8 guidelines.
   - Node.js: Follow ES6+ conventions.
3. **Commit Messages**:
   - Follow Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`.
4. **Security Invariant**:
   - Never weaken default policy enforcement (`PIPEJACK_ENFORCE=1`, `PIPEJACK_FAST=0`, `PIPEJACK_DEV=0`) in production code.
