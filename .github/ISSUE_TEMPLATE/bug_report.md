---
name: Bug report
about: Create a report to help us improve PipeJack
title: '[BUG] '
labels: 'bug'
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**Affected Subsystem**
- [ ] Process Tree Differ (`proctree`)
- [ ] Filesystem Merkle Baseline (`fschecker`)
- [ ] Network Egress Firewall / Monitor (`egressfw`, `netmon`)
- [ ] Anomaly Detection Engine (`anomaly`)
- [ ] Policy Decision Point (`pdp`)
- [ ] CI Orchestrator (`services/custom-ci`)
- [ ] Cryptographic Attestation (`attest`)
- [ ] Other

**Environment**
 - OS: [e.g. Ubuntu 24.04 LTS]
 - Kernel: [e.g. Linux 6.8.0]
 - Docker Version: [e.g. 28.2.2]
 - Go Version: [e.g. 1.23.2]

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. Upload payload '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Logs & Diagnostic Output**
Include output from `journalctl -u pipejack-ci` or test output.
