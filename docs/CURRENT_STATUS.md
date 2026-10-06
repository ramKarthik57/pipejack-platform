# PipeJack: Authoritative Current System Status

**Release Baseline**: v2.0.0-rc1 (Consolidated Multi-Stack Release)  
**Canonical Branch**: `main`  
**Official Repository**: [https://github.com/ramKarthik57/pipejack-platform](https://github.com/ramKarthik57/pipejack-platform)  
**Host Architecture**: Linux x86_64 (Ubuntu 24.04 LTS, Kernel 6.8+)  
**Evaluation Target Date**: October 2026  

This document serves as the **single authoritative source of truth** regarding PipeJack's currently implemented, verified, and operational capabilities.

---

## 1. Supported Toolchain & Runtime Environment

| Component | Authoritative Value | Verification Method |
| :--- | :--- | :--- |
| **Go Compiler** | `go 1.25.0` | `go version` & `go.mod` in both modules |
| **Docker Engine** | `Docker CE 28.2.2` | `docker version` |
| **Linux Control Groups** | `cgroup v2` (`system.slice`) | `/sys/fs/cgroup/cgroup.controllers` |
| **Network Filtering** | `iptables v1.8.10` (legacy/nft hybrid) | `iptables -V` |
| **Java Environment** | OpenJDK 17 (Eclipse Temurin 17 digest-pinned) | Container digest verification |
| **Node.js Environment**| Node.js 18 LTS (digest-pinned) | Container digest verification |
| **Python Environment** | Python 3.12 (digest-pinned) | Container digest verification |

---

## 2. Sensor Implementation Matrix

| Sensor / Subsystem | Current Implementation Mechanism | Operational Status | Invariant Enforced |
| :--- | :--- | :--- | :--- |
| **Process Tree Differ** (`proctree`) | Periodic `/proc` polling (150ms interval) filtered by container cgroup v2 scope. | **IMPLEMENTED & VERIFIED** | Executables must match policy allowlist (`allowed_processes`). |
| **Kernel Tracepoint Hooks** (`ebpfctrl/`, `netblock/`) | Vendored Cilium eBPF prototype bindings. | **ARCHITECTURAL PROTOTYPE** | Planned for zero-latency kernel tracepoints; cgroup polling is active runtime. |
| **Filesystem Baseline** (`fschecker`) | Pre-build and post-build SHA-256 recursive hashing over `/workspace` with diff engine. | **IMPLEMENTED & VERIFIED** | Source trees (`src/**`, manifests) must remain byte-for-byte immutable. |
| **Egress Firewall** (`egressfw`) | Injected container netns `PIPEJACK_EGRESS` iptables chain with default DROP. | **IMPLEMENTED & VERIFIED** | Outbound TCP/UDP traffic dropped unless explicitly allowlisted. |
| **Socket Monitor** (`netmon`) | Periodic inspection of `/proc/net/{tcp,tcp6,udp,udp6}` mapped to container PIDs. | **IMPLEMENTED & VERIFIED** | Outbound socket connections flagged. |
| **Statistical Anomaly Engine** (`anomaly`) | Rolling 20-build window z-score evaluation (\(|z| > 3.0\)) over 4 telemetry metrics. | **IMPLEMENTED & VERIFIED (Advisory Default)** | Telemetry outliers logged; promotes to BLOCK when `anomaly_block: true`. |
| **Policy Decision Point** (`pdp`) | Strict declarative YAML rule evaluation engine. | **IMPLEMENTED & VERIFIED** | Deterministic `ALLOW` (HTTP 200) or `BLOCK` (HTTP 403) verdict. |
| **Attestation Ledger** (`attest`) | Ed25519 digital signature + SHA-256 sequential `prev_hash` chaining per build. | **IMPLEMENTED & VERIFIED** | 282+ consecutive build records cryptographically verified intact. |

---

## 3. Enforcement & Deployment Model

1. **Default Enforcement State**:
   - `PIPEJACK_ENFORCE=1`: Active blocking enabled.
   - Any violation from `proctree`, `fschecker`, `egressfw`, or `netmon` produces a `BLOCK` verdict.
2. **ALLOW Path**:
   - Workload compiles cleanly with zero policy violations.
   - Image tagged as `localhost:5000/<app>:<tag>`.
   - Pushed to local registry and started as a running microservice container.
   - Returns `HTTP 200 OK`.
3. **BLOCK / Quarantine Path**:
   - Any invariant violation detected.
   - Image tagged as `localhost:5000/<app>:<tag>-quarantine`.
   - Microservice deployment aborted. No container launched.
   - Returns `HTTP 403 Forbidden` with forensic breakdown.

---

## 4. Adversarial Attack Scenarios (01–07) Status

| Scenario | Attack Vector | Primary Sensor | Current Verdict | Quarantine Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **01-shell-exec** | Unauthorized `/bin/sh` execution | `proctree` | **BLOCK (403)** | Quarantined (`<tag>-quarantine`), deployment blocked |
| **02-http-exfil** | Outbound `/usr/bin/curl` exfiltration | `proctree` + `egressfw` | **BLOCK (403)** | Dropped at netns firewall, quarantined |
| **03-fs-tamper** | In-situ `src/` source code tampering | `fschecker` | **BLOCK (403)** | Workspace root digest mutated, quarantined |
| **04-base64-shell**| Obfuscated Base64 shell pipe | `proctree` | **BLOCK (403)** | Kernel `/proc/<pid>/exe` caught, quarantined |
| **05-multi-stage** | Staged dropper script in `/tmp` | `fschecker` + `proctree` | **BLOCK (403)** | Staged binary addition & exec caught, quarantined |
| **06-slow-exfil** | Trickling low-rate socket transmission | `egressfw` + `netmon` | **BLOCK (403)** | SYN dropped by iptables netns chain, quarantined |
| **07-anomaly** | Process explosion & rapid file churn | `anomaly` | **ALLOW (Advisory)** | Telemetry flagged, findings signed in attestation |

*Note on Scenario 07*: Under default production policies, the anomaly engine operates in **advisory mode** (`anomaly_block: false`) to prevent false-positive build interruptions during developer warmup. Findings are signed into the immutable attestation ledger. When `anomaly_block: true` is configured in policy YAML, Scenario 07 promotes to `BLOCK (403)`.

---

## 5. Attestation Ledger Integrity (Historical Validation Evidence)

- **Ledger Storage**: `/home/ubuntu/pipejack-attestations/`
- **Total Historical Records Audited**: 282 consecutive build records (Historical evidence compiled during multi-VM validation session)
- **Ed25519 Cryptographic Signatures**: 282 / 282 Valid (100%)
- **SHA-256 Provenance Chain Links**: 282 / 282 Continuous (100%)
- **Verification Tool**: `services/custom-ci/verify-attest.go`
- **Audit Verdict**: `CHAIN INTACT (HISTORICAL VALIDATION EVIDENCE)`

---

## 6. Continuous Integration & Quality Gates

- **Unit Test Suite**: 52 / 52 passing across `core/pipejack` and `services/custom-ci` (100% freshly verified).
- **Static Analysis**: `go vet ./...` clean across all packages.
- **Race Condition Detection**: `go test -race ./...` passing.
- **Secret Hygiene**: 0 credentials, private keys, or tokens committed.
- **GitHub Actions CI Pipeline**: Active and operational at `.github/workflows/pipejack-ci.yml`. Automatically executes formatting checks, core security engine tests, race condition detection, static analysis (`go vet`), compilation checks, and secret hygiene scanning on every push to `main` and pull request.

---

## 7. Known Boundary Conditions & Limitations

1. **Sampling Interval (150ms)**: Sub-150ms ephemeral fork-exec bursts could theoretically terminate before the polling cycle. eBPF tracepoint bindings (`ebpfctrl/`) are vendored to eliminate this boundary in future releases.
2. **In-Memory Non-Disk Attacks**: Reflective bytecode execution within an authorized runtime that neither touches the filesystem nor invokes child processes is outside the current multi-sensor detection boundary.
3. **Host Kernel Privilege**: PipeJack assumes the host Linux kernel and Docker daemon have not suffered container escape vulnerabilities.
