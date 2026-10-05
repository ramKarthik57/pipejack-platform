# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| 1.0.x   | :x:                |

## Reporting a Vulnerability

The PipeJack project takes security vulnerabilities seriously.

To report a vulnerability or policy bypass vector:
1. Do **not** open a public GitHub issue.
2. Email security findings with reproducible steps and artifacts to: `security@pipejack.internal` (or project maintainers).
3. Specify the affected component:
   - Process Tree Differ (`proctree`)
   - Filesystem Merkle Baseline (`fschecker`)
   - Network Egress Firewall / Monitor (`netmon`, `egressfw`)
   - Anomaly Detection Engine (`anomaly`)
   - Policy Decision Point (`pdp`)
   - Cryptographic Attestation (`attest`)
4. Maintainers will acknowledge within 48 hours and provide a coordinated disclosure timeline.
