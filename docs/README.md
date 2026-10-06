# PipeJack Documentation Hub

Welcome to the technical documentation repository for the PipeJack Zero-Trust CI/CD Security Platform.

---

## Master Status & Research
- **[Authoritative Current Status](CURRENT_STATUS.md)**: The single definitive source of truth for release baseline, active sensors, toolchains, and verified claims.
- **[Research Contribution & Design Framing](research/CONTRIBUTION.md)**: Academic framing of the build-time blind spot, threat model, multi-sensor strategy, and experimental results.
- **[Release Certification Review](../PIPEJACK_FINAL_RELEASE_REVIEW.md)**: Official release scorecard, audit verification evidence, and quality gate sign-off.

---

## Documentation Taxonomy

### 1. Architecture & Design
- **[System Architecture Specification](architecture/PIPEJACK_ARCHITECTURE.md)**: Deep dive into the host-level sidecar engine, process differ, filesystem integrity baseline, network egress firewall, and policy decision point.
- **[System Topology Diagram](assets/system-topology.svg)**: Visual representation of the two-VM architecture and network flow.
- **[Build Security Lifecycle Diagram](assets/multi-sensor-lifecycle.svg)**: Step-by-step invariant enforcement from ingestion to attestation.
- **[Attestation Ledger Diagram](assets/attestation-chain.svg)**: SHA-256 ledger hash chain and Ed25519 digital signature structure.

### 2. Security & Policies
- **[Threat Model & Trust Boundaries](security/THREAT_MODEL.md)**: Threat environment, STRIDE analysis, attacker capabilities, and security boundaries.
- **[Policy Specification Guide](security/POLICIES.md)**: Declarative YAML policy schema, pattern matching rules, allowlist syntax, and default application policies.

### 3. Testing & Adversarial Validation
- **[Attack Scenarios & Adversarial Matrix](testing/ATTACK_SCENARIOS.md)**: Comprehensive breakdown of Scenarios 01 through 07, payload details, sensor responses, and quarantine actions.
- **[Authoritative Validation Report](testing/VALIDATION_REPORT.md)**: Complete verification results for 52 unit tests, multi-stack builds, attack suite runs, and 282+ attestation records.
- **[Sanitized Evidence Pack](testing/evidence/)**: Verifiable forensic build outputs, attestation audit tail, and system health checks.

### 4. Operations & Runbooks
- **[Quick Start & Reproduction Guide](operations/QUICK_START.md)**: Reproducible single-machine setup and dual-VM production configuration guide.
- **[Operations & Maintenance Runbook](operations/RUNBOOK.md)**: Service management, log inspection, Docker registry maintenance, and troubleshooting.

### 5. Audits & Engineering Verification
- **[Phase 1 Engineering Audit](audits/PHASE1_ENGINEERING_AUDIT.md)**: Deep forensic audit of original codebase and subsystem boundaries.
- **[Phase 1 Adversarial Audit](audits/PHASE1_ADVERSARIAL_AUDIT.md)**: Initial adversarial penetration testing findings.
- **[Phase 2A Security Hardening](audits/PHASE2A_REQUIRED_HARDENING.md)**: Fixes applied for policy bypass vectors, network egress leaks, and cgroup tracking.
- **[Phase 2A Regression Results](audits/PHASE2A_REGRESSION_RESULTS.md)**: Regression test results verifying zero broken invariants.
- **[Final VM-1 QA Audit](audits/FINAL_VM1_QA_AUDIT.md)**: Comprehensive quality assurance audit performed on VM-1.
- **[VM-1 Post-Publication Audit](audits/VM1_GITHUB_POSTPUBLICATION_AUDIT.md)**: Verification of GitHub branch parity and application fixes.
- **[GitHub Repository Final Report](audits/GITHUB_REPOSITORY_FINAL_REPORT.md)**: Consolidation audit report for repository release.

### 6. Engineering History & Multi-VM Coordination
- **[Agent Coordination](history/AGENT_COORDINATION.md)**: Multi-VM agent workflow and synchronization logs.
- **[Master Context](history/PIPEJACK_AGENT_CONTEXT.md)**: Historical agent design context and invariant definitions.
- **[Sync Baseline](history/SYNC_BASELINE.md)**: Snapshot baseline of files across VM-1 and VM-2.
- **[Repository Layout](history/REPOSITORY_LAYOUT.md)**: File layout mapping across virtual machines.
- **[Source Inventory](history/REPOSITORY_SOURCE_INVENTORY.md)**: Complete source catalog before repository consolidation.
- **[File Manifest](history/repository-file-manifest.txt)**: Comprehensive SHA-256 manifest of consolidated files.
