## Description
Provide a concise explanation of the changes made and the problem being resolved.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Security hardening (mitigates potential vulnerability or evasion)
- [ ] Documentation update
- [ ] Refactoring / Performance enhancement

## Subsystem Impact
- [ ] `core/pipejack` (Daemon, Proctree, Merkle, Netmon, Anomaly, PDP)
- [ ] `services/custom-ci` (Orchestrator, Quarantine, Attestation)
- [ ] `applications` / `security-fixtures` / `attacks`
- [ ] `deployment` / `policies`

## Testing Performed
- [ ] Unit tests pass cleanly: `go test -v -count=1 ./...`
- [ ] Linter & vet pass: `go vet ./...`
- [ ] Attestation verification passes: `go run verify-attest.go`
- [ ] Security Invariants Preserved (Zero-trust defaults untouched)

## Checklist
- [ ] My code adheres to the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation accordingly
- [ ] No secrets, keys, or internal credentials are committed
