# PipeJack: Multi-Sensor Zero-Trust Security Platform for CI/CD Pipelines

[![Go Report Card](https://goreportcard.com/badge/github.com/ramKarthik57/pipejack-test/pipejack)](https://github.com/ramKarthik57/pipejack-test)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Enforced-success.svg)](SECURITY.md)
[![Verification Status](https://img.shields.io/badge/Verification-READY__FOR__FINAL__DEMO-brightgreen.svg)](docs/PHASE2A_REGRESSION_RESULTS.md)

**PipeJack** is an autonomous, multi-sensor zero-trust security enforcement platform engineered to defend modern Continuous Integration and Continuous Delivery (CI/CD) toolchains against software supply chain attacks, build-time code injection, rogue process execution, and covert data exfiltration.

---

## 1. Problem Statement & Research Objective

Modern build environments execute complex third-party package dependency scripts (`postinstall`, `setup.py`, Maven build plugins) inside privileged or semi-isolated worker containers. Adversaries exploit these opaque build phases to execute malicious binaries, inject backdoors, modify compilation outputs, and exfiltrate secrets before static application security testing (SAST) or container image scanning can detect them.

### Objective
PipeJack introduces an active, transparent sidecar monitoring and enforcement architecture that enforces **zero-trust execution invariants** throughout the entire containerized build lifecycle:
1. **Host-Level Process Interception**: Continuous tracking of all processes spawned inside the build container cgroup.
2. **Cryptographic Merkle Tree Filesystem Baselines**: Instant detection of unauthorized mutations, injected backdoors, or deleted critical files.
3. **Container-Isolated Network Egress Enforcement**: Active kernel firewalling and socket monitoring to block unauthorized network exfiltration.
4. **Statistical Anomaly Detection**: Real-time evaluation against rolling baseline profiles for builds.
5. **Deterministic Policy Decision Point (PDP)**: Instant `ALLOW` or `BLOCK` verdicts preventing malicious images from reaching production registries.
6. **Cryptographic Attestation Chain**: Ed25519 digital signatures and SHA-256 Merkle linking providing immutable provenance for every build.

---

## 2. High-Level Architecture & VM Topology

PipeJack operates across a two-VM integration topology separating developer-side payload generation from server-side security enforcement:

```
+-----------------------------------------------------------------------------------+
| VM-1 (192.168.88.132) — Developer & Adversarial Lead                              |
| - Application Sources: Java 17 Banking API, Calculator API, Node.js, Python 3.12  |
| - Attack Fixtures: Shell injection, HTTP exfiltration, Merkle fs tampering, etc.  |
| - Client Invocation: pipejack-upload.sh -> POST /upload (VM-2 :8888)              |
+-----------------------------------------------------------------------------------+
                                         │ HTTP POST /upload (:8888)
                                         ▼
+-----------------------------------------------------------------------------------+
| VM-2 (192.168.88.133) — Security, CI & Attestation Lead                           |
|                                                                                   |
| 1. CI Orchestrator (`pipejack-ci.service` :8888):                                 |
|    - Unpacks workspace, auto-detects stack (Maven / npm / pip)                    |
|    - Spawns build container under Docker 28.2.2 with Linux cgroup v2 scope        |
|    - Injects `pipejack-daemon` sidecar (--pid=container, --network=container)     |
|                                                                                   |
| 2. Multi-Sensor Security Engine (`pipejackd`):                                    |
|    - [Sensor 1] Process Tree Differ: scans /proc every 150ms in build cgroup      |
|    - [Sensor 2] Filesystem Merkle Baseline: pre/post SHA-256 workspace diffing    |
|    - [Sensor 3] Network Egress Firewall: active iptables PIPEJACK_EGRESS chain    |
|    - [Sensor 4] Anomaly Engine: z-score tracking across 4 telemetry dimensions    |
|                                                                                   |
| 3. Policy Decision Point (PDP):                                                   |
|    - Evaluates process allowlists, fs mutations, and egress rules                 |
|    - ALLOW -> Build & push to localhost:5000 registry -> Deploy live microservice|
|    - BLOCK -> Quarantine image (<tag>-quarantine) -> Return deterministic HTTP 403|
|                                                                                   |
| 4. Cryptographic Provenance Ledger:                                               |
|    - Computes canonical build hash -> Ed25519 signature -> prev_hash chain link  |
|    - Stored in /home/ubuntu/pipejack-attestations/ & verifiable via verify-attest |
+-----------------------------------------------------------------------------------+
```

---

## 3. Repository Structure

```
pipejack/
├── README.md                           # Main project documentation
├── LICENSE                             # Apache 2.0 open-source license
├── SECURITY.md                         # Security policy and disclosure
├── CONTRIBUTING.md                     # Contributor workflow and standards
├── CODEOWNERS                          # Code ownership mappings
├── .gitignore                          # Standardized ignore rules
│
├── core/                               # VM-2: Core PipeJack Security Engine
│   ├── pipejack/                       # Main Go module
│   │   ├── cmd/pipejackd/              # PipeJack security daemon entry point
│   │   ├── cmd/proctree/               # Standalone process tree CLI
│   │   ├── fschecker/                  # SHA-256 Merkle tree baseline engine
│   │   ├── proctree/                   # Linux cgroup v2 /proc scanner
│   │   ├── internal/anomaly/           # Statistical anomaly detection (z-scores)
│   │   ├── internal/egressfw/          # iptables network firewall engine
│   │   ├── internal/netmon/            # Passive /proc/net socket monitor
│   │   ├── internal/pdp/               # Policy Decision Point engine
│   │   ├── ebpfctrl/                   # eBPF tracepoint controller
│   │   ├── netblock/                   # eBPF socket block C programs
│   │   ├── go.mod                      # Core Go module definition
│   │   └── go.sum                      # Core Go dependency checksums
│   ├── cilium-ebpf/                    # Vendored eBPF library
│   └── golang-sys/                     # Vendored system call library
│
├── services/                           # VM-2: CI & Attestation Microservices
│   └── custom-ci/                      # PipeJack CI Orchestrator
│       ├── main.go                     # HTTP server, cgroup discovery, pipeline
│       ├── attest.go                   # Ed25519 signing & attestation ledger
│       ├── verify-attest.go            # Attestation ledger chain verifier
│       ├── quarantine_test.go          # Quarantine failure regression tests
│       ├── deploy.sh                   # Deployment script
│       ├── anomaly/                    # Anomaly baseline profile storage
│       ├── go.mod                      # Service Go module definition
│       └── go.sum                      # Service Go dependency checksums
│
├── applications/                       # VM-1: Client Applications
│   ├── banking-api/                    # Java 17 / Maven Banking Microservice
│   ├── calculator-api/                 # Java 17 / Maven Safe AST Calculator
│   ├── nodejs-app/                     # Node.js 18 Payment Service
│   └── python-app/                     # Python 3.12 Real-Time Analytics Engine
│
├── security-fixtures/                  # VM-1: Adversarial & Vulnerable Fixtures
│   ├── nodejs-malicious/               # Malicious npm postinstall exfiltration
│   ├── python-malicious/               # Malicious setup.py socket exfiltration
│   ├── vuln-app/                       # Vulnerable microservice testbed
│   └── evil-pkg/                       # Rogue supply chain package
│
├── attacks/                            # VM-1: 7 Attack Scenarios
│   ├── 01-shell-exec/                  # Unauthorized /bin/sh binary execution
│   ├── 02-http-exfil/                  # Outbound HTTP exfiltration via curl
│   ├── 03-fs-tamper/                   # In-situ source code tampering
│   ├── 04-base64-shell/                # Base64-obfuscated shell invocation
│   ├── 05-multi-stage/                 # Staged dropper & payload execution
│   ├── 06-slow-exfil/                  # Trickling rate-limited exfiltration
│   ├── 07-anomaly/                     # Process count & binary statistical anomaly
│   └── run-all.sh                      # Master attack execution suite
│
├── demo/                               # Demonstration Console & Subsystems
│   └── demo-console/
│       ├── server.py                   # High-performance demonstration backend
│       ├── static/                     # Generative UI, SVG assets, live app
│       └── verify_all_enhancements.py  # End-to-end browser verification suite
│
├── deployment/                         # Production Deployment Configurations
│   ├── docker/                         # Pinned immutable Dockerfiles
│   │   ├── Dockerfile.spring           # Pinned Maven & Temurin 17 digests
│   │   ├── Dockerfile.calc             # Pinned AST Calculator digests
│   │   ├── Dockerfile.app              # Pinned Node.js 18 digests
│   │   └── Dockerfile.python           # Pinned Python 3.12 digests
│   ├── systemd/                        # Linux Systemd Service Unit
│   │   ├── pipejack-ci.service         # Systemd service unit definition
│   │   └── ci.env                      # Production environment configuration
│   └── policies/                       # Strict Zero-Trust Security Policies
│       ├── policy-banking.yaml         # Java Banking API security policy
│       ├── policy-node.yaml            # Node.js Payment security policy
│       ├── policy-python.yaml          # Python Analytics security policy
│       └── policy-spring.yaml          # Spring Calculator security policy
│
├── scripts/                            # Operational & Upload Scripts
│   ├── pipejack-upload.sh              # Client multi-image upload utility
│   └── deploy-ci.sh                    # Host service deployment helper
│
└── docs/                               # Comprehensive Technical Documentation
    ├── architecture/                   # Architectural specifications
    ├── audits/                         # Formal engineering & adversarial audits
    ├── operations/                     # Deployment and runbooks
    ├── repository/                     # Manifests and source maps
    ├── PIPEJACK_AGENT_CONTEXT.md       # Master agent context & design invariants
    ├── SYNC_BASELINE.md                # Multi-VM synchronization baseline
    ├── PHASE1_ENGINEERING_AUDIT.md     # Phase 1 deep engineering audit
    ├── PHASE1_ADVERSARIAL_AUDIT.md     # Phase 1 adversarial audit
    ├── PHASE2A_REQUIRED_HARDENING.md   # Phase 2A security hardening report
    └── PHASE2A_REGRESSION_RESULTS.md   # Complete regression test results
```

---

## 4. Multi-Sensor Security Enforcement

### 1. Process Tree Differ (`proctree`)
- Actively watches `/proc` inside the container cgroup (`/sys/fs/cgroup/.../docker-<id>.scope`).
- Matches executable paths against strict allowlists (e.g., `/usr/bin/mvn`, `/opt/java/openjdk/bin/java`, `/usr/local/bin/node`).
- Detects unauthorized binary executions (e.g., `/bin/sh`, `/usr/bin/curl`, `/usr/bin/python`) even if spawned by legitimate tools.

### 2. Filesystem Merkle Baseline (`fschecker`)
- Computes canonical SHA-256 Merkle tree root over `/workspace` prior to build execution.
- Re-scans post-build and computes a surgical diff of all modified, added, and deleted files.
- Enforces strict allowlists on build output artifacts (e.g., `target/**`, `build/**`) while blocking any modification to source directories (`src/**`, `package.json`).

### 3. Network Egress Firewall & Monitor (`egressfw`, `netmon`)
- Injects a dedicated `PIPEJACK_EGRESS` iptables chain directly into the build container's shared network namespace.
- Drops all unauthorized outbound TCP/UDP traffic while permitting explicit loopback and approved upstream mirrors.
- Passive socket monitor reads `/proc/net/{tcp,tcp6,udp,udp6}` and correlates socket inodes to container PIDs.

### 4. Statistical Anomaly Detection (`anomaly`)
- Evaluates four telemetry dimensions: `process_count`, `file_change_count`, `network_count`, and `duration_ms`.
- Computes z-scores against rolling 20-build baselines and flags unauthorized binary executions as high-risk anomalies.

### 5. Cryptographic Attestation (`attest`)
- Generates canonical build metadata, computes SHA-256 `self_hash`, and signs with an Ed25519 digital private key.
- Links to the previous build's `self_hash` (`prev_hash`) to form an unbroken, tamper-evident cryptographic provenance ledger.

---

## 5. Verification & Testing

### Running Core Unit Tests
```bash
cd core/pipejack
go test -v -count=1 ./...
go test -race ./...
go vet ./...
```

### Running CI Service Tests
```bash
cd services/custom-ci
go test -v -count=1 ./...
go vet ./...
```

### Verifying Attestation Ledger Integrity
```bash
cd services/custom-ci
go run verify-attest.go
```

### Executing Live Client Uploads (from VM-1)
```bash
# Clean Java Build
./scripts/pipejack-upload.sh clean-java.tar.gz

# Malicious Java Build (Blocks with curl violation)
./scripts/pipejack-upload.sh malicious-java.tar.gz

# All 7 Attack Scenarios
cd attacks && ./run-all.sh
```

---

## 6. Immutable Builder Digest Pinning

All builder and runtime container images use immutable SHA-256 content digests to prevent upstream supply chain poisoning:

| Workload | Image Reference | Pinned SHA-256 Digest |
| :--- | :--- | :--- |
| **Java Builder** | `maven` | `sha256:40fcff4c4043d6adc90286c2e38ec70950f34f6dd5784f7e524866c66520cc23` |
| **Java Runtime** | `eclipse-temurin` | `sha256:92999aea37688157a53a40bfcb187c30f317422e028045fd5fc5c548fde9e626` |
| **Node.js** | `node` | `sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e` |
| **Python** | `python` | `sha256:0687a6bc9716edc2a6ee0fbfb0f87e7ee358b262b67c9215de91bc9b2d38ba71` |

---

## 7. License

Licensed under the [Apache License, Version 2.0](LICENSE).
Copyright © 2026 PipeJack Contributors.
