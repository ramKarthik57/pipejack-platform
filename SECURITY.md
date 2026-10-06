# Security Policy & Vulnerability Disclosure

PipeJack is a security-critical platform designed to enforce zero-trust invariants on software supply chains and build pipelines. We take vulnerability reports and security inquiries with utmost seriousness.

---

## Supported Versions

Only the current main release line receives active security updates and patches:

| Version | Supported | Description |
| :--- | :--- | :--- |
| `2.0.x` / `main` | :white_check_mark: | Active production baseline |
| `< 2.0.0` | :x: | Legacy / unsupported |

---

## Reporting a Vulnerability

If you discover a security vulnerability, policy bypass, container breakout, or attestation tampering mechanism in PipeJack, **please do not open a public issue**. Publicly disclosing an unpatched vulnerability exposes users to potential exploitation.

### Reporting Procedure:
1. Contact the project maintainers via GitHub Security Advisories or email the maintainer directly at the email listed on their GitHub profile (`@ramKarthik57`).
2. Provide a detailed report containing:
   - Affected component (`proctree`, `fschecker`, `egressfw`, `netmon`, `pdp`, `custom-ci`, or `attest`).
   - Step-by-step reproduction instructions, payload scripts, or test fixtures.
   - Analysis of exploitability and impact on zero-trust invariants.
   - Proposed mitigation or patch if available.

### Response & Coordinated Disclosure Timeline:
- **Initial Acknowledgment**: Within **48 hours** of report receipt.
- **Triage & Reproduction**: Within **5 business days**.
- **Fix & Advisory Release**: Coordinated with the reporter before public disclosure.

---

## Security Invariants Enforced by PipeJack

1. **Host-Isolated Process Monitoring**: Host-isolated sensors monitor container cgroups from outside the container namespace. Any unapproved binary execution that persists across the 150 ms `/proc` polling interval or spawns tracked child processes is deterministically flagged against the security policy baseline.
   *(Note: Sub-150 ms transient execution bursts that terminate prior to sensor sampling or in-memory shellcode execution without child process creation represent documented architectural boundaries; see [CURRENT_STATUS.md](docs/CURRENT_STATUS.md).)*
2. **Deterministic Policy Enforcement & Quarantine**: Any build violating security policy is tagged as `<image>:<tag>-quarantine` and denied deployment or admission to production registries.
3. **Cryptographic Tamper-Evidence**: Attestation records signed with Ed25519 cannot be forged or reordered without invalidating the sequential SHA-256 provenance hash chain.
