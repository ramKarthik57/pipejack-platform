# Contributing to PipeJack

Thank you for your interest in contributing to the PipeJack Zero-Trust CI/CD Security Platform! We welcome contributions from developers, security researchers, and DevOps engineers.

---

## Code of Conduct & Contribution Standards

PipeJack enforces strict security and engineering invariants. All contributions are expected to adhere to high code quality, comprehensive testing, and strict zero-trust principles.

---

## Development Environment Setup

### Prerequisites
- Linux OS with cgroup v2 enabled
- Docker Engine 24.0+
- Go 1.25+ (Go 1.25.0 verified)
- `iptables` and `python3`

### Building the Project
```bash
# Build core daemon & proctree CLI
cd core/pipejack
go build ./...

# Build custom CI orchestrator
cd ../../services/custom-ci
go build ./...
```

---

## Testing & Quality Assurance

Before submitting any Pull Request, ensure that all tests pass without errors or race conditions:

```bash
# Run Core Engine tests
cd core/pipejack
go test -v -count=1 ./...
go test -race ./...
go vet ./...

# Run CI Orchestrator tests
cd ../../services/custom-ci
go test -v -count=1 ./...
go vet ./...

# Verify Attestation Ledger Integrity
go run verify-attest.go
```

---

## Coding Standards

1. **Go Guidelines**:
   - Format code using `go fmt ./...`.
   - Ensure all public functions, structs, and packages have descriptive comments.
   - Return clear, typed errors; avoid unhandled panics in daemon routines.
2. **Commit Messages**:
   - Use Conventional Commits formatting:
     - `feat:` New features or sensor capabilities
     - `fix:` Bug fixes or policy bypass remediations
     - `docs:` Documentation improvements
     - `test:` Unit, integration, or adversarial test additions
     - `chore:` Dependency bumps, CI updates, refactoring
3. **Security Invariant Rule**:
   - Never weaken default policy enforcement (`PIPEJACK_ENFORCE=1`, `PIPEJACK_FAST=0`, `PIPEJACK_DEV=0`) in production code paths.
   - Never commit private keys, tokens, or credentials to Git.

---

## Submitting Pull Requests

1. Fork the repository and create your feature branch: `git checkout -b feature/my-feature`.
2. Commit your changes with descriptive commit messages.
3. Push to your branch and open a Pull Request against the `main` branch.
4. Complete the PR template checklist to facilitate review.
