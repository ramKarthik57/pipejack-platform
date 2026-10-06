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

## Security Invariants Guaranteed by PipeJack

1. **Host-Level Isolation**: No build container process can execute unapproved binaries without triggering detection.
2. **Deterministic Quarantine**: Any build violating policy is tagged as quarantine and denied deployment to production clusters.
3. **Cryptographic Tamper-Evidence**: Attestation records signed with Ed25519 cannot be forged or reordered without invalidating the SHA-256 hash chain.
