# Component Ownership Specification

Under the two-VM development and operational model:

## VM-1 (Developer & Adversarial Lead)
- **Primary Owner**: `@ramKarthik57` (VM-1 Developer)
- **Owned Areas**:
  - `applications/`: Source code and tests for all reference workloads.
  - `security-fixtures/`: Adversarial build hooks, trojaned dependencies.
  - `attacks/`: Standalone attack scenarios (01–07) and execution scripts.
  - `scripts/pipejack-upload.sh`: Client-side packaging and upload tool.

## VM-2 (Security, CI & Attestation Lead)
- **Primary Owner**: `@ramKarthik57` (VM-2 Security / CI Lead)
- **Owned Areas**:
  - `core/`: Multi-sensor daemon, eBPF sidecar, Merkle checker, process scanner, network firewall.
  - `services/`: CI orchestration server, build pipeline, Docker namespace isolation.
  - `deployment/`: Dockerfiles with pinned SHA-256 digests, systemd unit, zero-trust policies.
  - `demo/`: Demonstration console, live execution playground, and verification test suites.
  - `docs/`: Technical audits, synchronization baselines, and formal reports.
