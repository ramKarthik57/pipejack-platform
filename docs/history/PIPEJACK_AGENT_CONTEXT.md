# PipeJack Architecture & Agent Context

This document captures the real, verified implementation of the PipeJack Security Engine as deployed on VM-2 and integrated with VM-1.

---

## 1. High-Level Architecture & VM Topology

```
+-----------------------------------------------------------------------------------+
| VM-1 (192.168.88.132)                                                             |
| Developer & Attack Agent                                                          |
| - Application source development (Java, Node.js, Python)                          |
| - Malicious attack fixtures & exploit scripts (attack.sh, evil dependencies)      |
| - Packaging source bundles (.tar.gz)                                              |
| - Triggering CI build: curl -F "file=@app.tar.gz" http://192.168.88.133:8888/upload|
+-----------------------------------------------------------------------------------+
                                         │ HTTP POST /upload (:8888)
                                         ▼
+-----------------------------------------------------------------------------------+
| VM-2 (192.168.88.133)                                                             |
| Integration & Security Agent                                                      |
|                                                                                   |
| 1. Systemd Service: pipejack-ci.service (PID /usr/local/bin/pipejack-ci)          |
|    - Working directory: /home/ubuntu/custom-ci                                    |
|    - Health endpoint: http://localhost:8888/health                                |
|    - Config: /etc/pipejack/ci.env (PIPEJACK_ENFORCE=1, FAST=0, DEV=0)             |
|                                                                                   |
| 2. CI Workflow Pipeline (/upload):                                                |
|    - Extract tarball to /tmp/workspace-<buildID>                                  |
|    - Project auto-detection (Java pom.xml, Node.js package.json, Python setup)    |
|    - Spawn build container (maven:3.8, node:18-alpine, python:3.12-alpine)        |
|    - Discover container cgroup: /sys/fs/cgroup/.../docker-<id>.scope              |
|    - Select policy: policy-banking.yaml / policy-node.yaml / policy-python.yaml   |
|    - Launch PipeJack Sidecar container (pipejack-daemon):                         |
|      * --pid=container:<buildContainer>                                           |
|      * --network=container:<buildContainer>                                       |
|      * --privileged                                                               |
|      * -v /workspace:/workspace:ro                                                |
|      * -v policy.yaml:/app/policy.yaml                                            |
|                                                                                   |
| 3. Security Engine Sensors (pipejackd):                                           |
|    [Sensor 1] Process Tree Differ:                                                |
|      * Polls /proc every 150ms filtered by build cgroup                           |
|      * Evaluates /proc/<pid>/exe against allowed_binaries / blocked_binaries       |
|      * Emits VIOLATION: unauthorized binary <path>                                |
|      * Aggregates all seen binaries into PIPEJACK_BINARIES list                    |
|    [Sensor 2] Filesystem Merkle Baseline:                                         |
|      * Pre-build SHA-256 Merkle root computation over workspace                   |
|      * Post-build Merkle root computation, diffing modified/added/deleted files    |
|      * Evaluates against allowed_filesystem_changes (globs, /** prefixes)         |
|    [Sensor 3] Network Egress Monitor & Firewall:                                  |
|      * Passive: Polls /proc/net/{tcp,tcp6,udp,udp6} every 100ms                   |
|      * Maps socket inodes to cgroup PIDs, matches remote IP:port vs allowed_egress|
|      * Active (enforce_network: true): Injects iptables PIPEJACK_EGRESS chain     |
|        into shared container netns; dumps counters and cleans up on exit          |
|                                                                                   |
| 4. Policy Decision Point (PDP):                                                   |
|    - Evaluates process violations, fs changes, network egress violations          |
|    - Emits Decision: ALLOW or BLOCK with itemized reasons                         |
|                                                                                   |
| 5. Statistical Anomaly Detection:                                                 |
|    - Evaluates process_count, file_change_count, network_count, duration_ms       |
|    - Calculates z-score vs rolling 20-build baseline in /home/ubuntu/pipejack-baseline|
|    - Identifies unexpected new binaries not in known baseline set (>=80% ratio)   |
|    - Can promote verdict to BLOCK if anomaly_block: true                          |
|                                                                                   |
| 6. Cryptographic Attestation Chain:                                               |
|    - Ed25519 digital signature over canonical SHA-256 hash of build metadata     |
|    - Chained: prev_hash links to prior build's self_hash                          |
|    - Persisted in /home/ubuntu/pipejack-attestations/<buildID>.json + index.json   |
|    - Verifiable via verify-attest.go                                              |
|                                                                                   |
| 7. Deployment & Quarantine Enforcement:                                           |
|    - ALLOW: Builds Docker image, pushes to localhost:5000 registry, deploys app  |
|    - BLOCK + Quarantine: Tags image as <image>-quarantine, pushes, skips deploy   |
|    - BLOCK (no quarantine): Discards image immediately, returns HTTP 403 Forbidden|
+-----------------------------------------------------------------------------------+
```

---

## 2. Responsibilities & Ownership Boundaries

### VM-1: Developer & Adversarial Testing Agent
- **Owns**:
  - Client application source code (Banking API, Calculator, Node.js App, Python App).
  - Malicious payloads, build hooks (`postinstall`, `setup.py`), and attack scripts (`attack.sh`).
  - Packaging and submitting test payloads to VM-2 CI.
  - Verifying client-side responses (HTTP 200 vs HTTP 403, JSON result payload).
- **Boundaries**:
  - VM-1 must NOT modify the security engine source, CI daemon, policies, or systemd services on VM-2.
  - Security change requests must be proposed via Git commits and synchronized.

### VM-2: Integration & Security Engineering Agent
- **Owns**:
  - PipeJack security daemon (`pipejack-dev/pipejack/cmd/pipejackd`).
  - Security sensors: Process Tree differ (`proctree`), Filesystem Merkle checker (`fschecker`), Network egress monitor (`netmon`), iptables firewall (`egressfw`).
  - Policy Decision Point (`pdp`).
  - Anomaly detection engine (`anomaly`).
  - CI server orchestration (`custom-ci/main.go`).
  - Policy specifications (`policy-*.yaml`).
  - Attestation generator and verifier (`attest.go`, `verify-attest.go`).
  - Host deployment, Docker sidecar packaging, systemd service, and health monitoring.
- **Boundaries**:
  - VM-2 preserves application source compatibility.
  - VM-2 does not tamper with test payloads or falsify security verdicts.

---

## 3. Source Tree & Component Breakdown

### Repository Layout: `/home/ubuntu/pipejack-dev`
- **`pipejack/`**: Core PipeJack Security Engine (Go module `github.com/ramKarthik57/pipejack-test/pipejack`)
  - **`cmd/pipejackd/main.go`**: Sidecar daemon entrypoint. Orchestrates pre-build snapshot, launches `netmon` (100ms) and `proctree` (150ms) background pollers, applies `egressfw` iptables rules, listens for `SIGTERM`/`SIGINT`, captures post-build snapshot, executes PDP, emits `PIPEJACK_BINARIES`, and prints detection summary.
  - **`internal/pdp/pdp.go`**: Policy Decision Point. Reads YAML policy, matches observed process executions against `allowed_binaries`/`blocked_binaries`, matches filesystem modifications against `allowed_filesystem_changes` using recursive globs (`dir/**`, `*.ext`, prefix wildcards), evaluates `networkViolations`, and decides `ALLOW` or `BLOCK`.
  - **`internal/proctree/scanner.go`**: Pure `/proc` process scanner. Matches process cgroups using `/proc/<pid>/cgroup`, reads symlink `/proc/<pid>/exe`, detects unauthorized binaries, and provides `ScanCgroup` to extract all unique executables.
  - **`internal/netmon/netmon.go`**: Network egress passive sensor. Parses `/proc/net/tcp`, `tcp6`, `udp`, `udp6`, resolves socket inodes to PIDs via `/proc/<pid>/fd/*`, checks cgroup membership, compares destination IPs and ports against `allowed_egress` CIDR/port rules.
  - **`internal/egressfw/egressfw.go`**: Network egress active enforcement. Manages iptables `PIPEJACK_EGRESS` chain in container network namespace, adds permit rules for `allowed_egress`, drops unauthorized traffic, and logs packet counters.
  - **`internal/anomaly/anomaly.go`**: Rolling statistical deviation detector. Maintains sliding window of last 20 builds in `/home/ubuntu/pipejack-baseline/<project>.json`. Evaluates mean/stddev z-scores for numeric metrics (process count, file changes, network connections, duration) and detects unobserved binaries (<80% baseline threshold).
  - **`fschecker/checker.go`**: Deterministic Merkle tree generator. Recursively hashes files with SHA-256 and computes single root hash. Diffs pre-build and post-build trees.
  - **`docs/`**: Engineering documentation for architecture, network egress, anomaly detection, multi-language pipelines, and production deployment.

### CI/CD Server: `/home/ubuntu/custom-ci`
- **`main.go`**: HTTP CI server listening on `:8888`. Endpoints:
  - `POST /upload`: Receives multipart `.tar.gz` bundle, extracts workspace, auto-detects language, launches isolated build container, attaches `pipejack-daemon` sidecar with shared PID and network namespaces, executes build/test commands, terminates sidecar on completion, parses detection logs, evaluates PDP + anomaly engine, writes attestation, executes quarantine/deployment actions, and returns JSON status.
  - `GET /health`: Health check endpoint returning status, service name, and RFC3339 timestamp.
- **`attest.go`**: Cryptographic attestation module. Generates Ed25519 keypair in `/home/ubuntu/.pipejack/attest-key`, computes SHA-256 `self_hash`, signs it, and maintains continuous hash chain via `prev_hash` in `/home/ubuntu/pipejack-attestations/`.
- **`verify-attest.go`**: Standalone attestation verifier. Iterates through all attestation JSON files, recomputes hashes, verifies Ed25519 signatures against public key, and validates hash chain links.
- **`deploy.sh`**: Idempotent production installer. Builds `custom-ci`, installs binary to `/usr/local/bin/pipejack-ci`, reloads systemd, and restarts `pipejack-ci.service`.
- **Policies**:
  - `policy-banking.yaml`: Java Banking API strict policy.
  - `policy-spring.yaml`: Java permissive policy.
  - `policy-node.yaml`: Node.js Employee Manager policy with npm/node allowlists.
  - `policy-python.yaml`: Python service policy with python3/pip allowlists.

---

## 4. Execution & Decision Flow (Trace)

### 1. Upload & Workspace Initialization
1. Client POSTs `file` (`.tar.gz`) to `http://<VM-2-IP>:8888/upload`.
2. `custom-ci` saves upload to `/tmp/upload-<buildID>.tar.gz` and unpacks into `/tmp/workspace-<buildID>`.
3. Language and project detection:
   - `pom.xml` -> Java/Spring (`maven:3.8-eclipse-temurin-17`)
   - `package.json` -> Node.js (`node:18-alpine`)
   - `requirements.txt` / `setup.py` / `pyproject.toml` -> Python (`python:3.12-alpine`)

### 2. Isolated Container & Sidecar Startup
1. Build container `build-<buildID>` starts running `sleep 600` with workspace mounted at `/app`.
2. Host cgroup path is identified via `docker inspect` and `/sys/fs/cgroup`.
3. Policy file is mapped based on project type.
4. Sidecar container `sidecar-<buildID>` (`pipejack-daemon`) is launched sharing `--pid=container:build-<buildID>` and `--network=container:build-<buildID>`.
5. Pre-build Merkle root is computed over `/workspace`.
6. Background monitors (`netmon`, `proctree`) start polling; iptables `PIPEJACK_EGRESS` chain is established.

### 3. Build & Test Phase
1. `custom-ci` executes build commands in container via `docker exec`:
   - Java: `mvn clean package`
   - Node.js: `npm install && npm run build && npm test`
   - Python: `pip install --no-cache-dir .` (or `-r requirements.txt`)
2. Sensors detect active processes, cgroup-bounded executable paths, filesystem modifications, and outbound sockets.

### 4. Teardown & Decision
1. `custom-ci` sends `SIGTERM` to `sidecar-<buildID>`.
2. Sidecar stops pollers, dumps iptables counter evidence, cleans up firewall rules, takes post-build Merkle snapshot, runs `pdp.Evaluate()`, outputs `PIPEJACK DETECTION SUMMARY` and `PIPEJACK_BINARIES`.
3. `custom-ci` reads sidecar log:
   - Extracts process violations, filesystem changes, network egress violations, and Merkle roots.
   - Evaluates statistical anomaly engine (`anomaly.Evaluate()`).
   - If PDP or Anomaly blocks, `verdict = BLOCK`; otherwise `ALLOW`. Fail-closed triggers if sidecar output is corrupt or missing.

### 5. Attestation & Enforcement
1. `writeAttestation()` signs build record and writes to `/home/ubuntu/pipejack-attestations/<buildID>.json`.
2. Enforcement actions:
   - `ALLOW`: Builds target image, pushes to `localhost:5000`, deploys application container.
   - `BLOCK` + `quarantine: true`: Builds target image, tags as `<image>-quarantine`, pushes to registry, skips deployment, returns HTTP 403.
   - `BLOCK` + `quarantine: false`: Drops build immediately, skips image build/push/deploy, returns HTTP 403.

---

## 5. Synchronization Model with VM-1

- **Primary Private Remote**: `sync-bare`
  - URL: `ssh://ubuntu@192.168.88.133/home/ubuntu/pipejack.git`
  - Bare Git repository hosted on VM-2.
  - Fully private, zero cloud/public dependency.
- **Upstream Mirror Remote**: `origin`
  - URL: `https://github.com/ramKarthik57/pipejack-test.git`
  - Preserved as read/fetch mirror.
- **Workflow Protocol**:
  1. VM-1 pulls latest changes from `sync-bare` (`git pull sync-bare main`).
  2. VM-1 develops application/test changes and commits to Git.
  3. VM-1 pushes changes to `sync-bare` (`git push sync-bare main`).
  4. VM-2 pulls from `sync-bare`, reviews diff, runs integration tests and security scans.
  5. Never execute destructive resets or force pushes on shared branches.
