# VM-1 Agent State

This document records the runtime, network, repository, test matrix, and synchronization state of VM-1.
Owned exclusively by the VM-1 Developer / Test Engineer Agent.

---

## 1. Host & Identity Information

- **Role**: VM-1 Developer / Test Engineer, build artifact creator, malicious/clean test application maintainer, attack scenario engineer, integration-test client
- **Hostname**: `ubuntu`
- **Primary Interface (`ens33`)**: `192.168.88.132/24`
- **Secondary Interface (`ens37`)**: `192.168.152.131/24`
- **Primary Workspace**: `/home/ubuntu/pipejack-dev`
- **SSH Client**: Configured with Ed25519 keypair (`/home/ubuntu/.ssh/id_ed25519`) authorized for passwordless access to VM-2 (`ubuntu@192.168.88.133`).

---

## 2. Git State & Synchronization

- **Working Directory**: `/home/ubuntu/pipejack-dev`
- **Current Branch**: `main`
- **Current Head Commit**: `bf10ca156082f7d65534256f90a0336a57fc986d`
- **Commit Subject**: `docs: Add shared agent context and VM-2 state tracking`
- **Configured Remotes**:
  - `sync-bare`: `ssh://ubuntu@192.168.88.133/home/ubuntu/pipejack.git` (Primary private shared bare Git repository on VM-2)
  - `origin`: `ubuntu@192.168.88.133:/home/ubuntu/local-repo.git` (Legacy local demo remote)
- **Tracking Branch**: `sync-bare/main`
- **Synchronization Status**: Synchronized with `sync-bare/main` at commit `bf10ca1`.

---

## 3. Visible Project & Application Structure

Within the primary workspace `/home/ubuntu/pipejack-dev`, the following directories and components are present:

### Tracked Repository Components
- **`pipejack/`**: Core PipeJack Security Engine (Go module)
  - `cmd/pipejackd`: Security daemon sidecar orchestrating snapshotting, polling, firewalling, and PDP evaluation.
  - `internal/pdp`: Policy Decision Point evaluating process, filesystem, and egress policies.
  - `internal/proctree`: Process scanner polling `/proc` and correlating container cgroups.
  - `internal/netmon`: Passive network egress monitor inspecting `/proc/net/*` and socket inodes.
  - `internal/egressfw`: Active iptables firewall managing container network namespace filtering.
  - `internal/anomaly`: Rolling statistical deviation and new binary detector.
  - `fschecker`: Deterministic Merkle tree generator and validator.
- **`docs/`**: Shared documentation suite
  - `PIPEJACK_AGENT_CONTEXT.md`: Cross-VM shared architecture and collaboration model.
  - `agent-vm2-state.md`: Runtime and service state of VM-2 (owned by VM-2 agent).
  - `agent-vm1-state.md`: Runtime and test state of VM-1 (owned by VM-1 agent).
- **`evil-pkg/`**: Malicious dependency testing package.
- **`cilium-ebpf/`, `golang-sys/`**: eBPF and low-level Go system libraries.

### Visible Application Symlinks
The test and development applications reside in `/home/ubuntu` and are visible inside `/home/ubuntu/pipejack-dev` via symbolic links:
- `banking-api` &rarr; `/home/ubuntu/banking-api`
- `nodejs-app` &rarr; `/home/ubuntu/nodejs-app`
- `nodejs-malicious` &rarr; `/home/ubuntu/nodejs-malicious`
- `python-app` &rarr; `/home/ubuntu/python-app`
- `python-malicious` &rarr; `/home/ubuntu/python-malicious`
- `attacks` &rarr; `/home/ubuntu/attacks`

---

## 4. Application Details & Vectors

1. **Banking API (Java / Spring Boot 3.2.0, Java 17)**:
   - Location: `/home/ubuntu/banking-api`
   - Clean profile: Uses `pom-clean.xml` without execution plugins. Produces `[VERDICT] ALLOW`.
   - Malicious profile: Uses `pom.xml` binding `exec-maven-plugin` to execute `malicious.sh` during packaging. Attempts exfiltration to `10.255.255.1` and appends backdoor into `AccountController.java`. Produces `[VERDICT] BLOCK` (quarantined).

2. **Node.js App (Clean)**:
   - Location: `/home/ubuntu/nodejs-app`
   - Express server with standard build/start scripts. Produces `[VERDICT] ALLOW`.

3. **Node.js Malicious (Supply Chain)**:
   - Location: `/home/ubuntu/nodejs-malicious`
   - `postinstall` hook executes `postinstall.js`, which initiates an outbound HTTP POST to `10.255.255.1:80/exfil` using Node's built-in `http` module. The binary is `/usr/local/bin/node` (allowlisted), but the egress network sensor catches the unauthorized destination. Produces `[VERDICT] BLOCK` (quarantined).

4. **Python App (Clean)**:
   - Location: `/home/ubuntu/python-app`
   - Flask microservice with clean requirements (`flask==3.0.0`). Produces `[VERDICT] ALLOW`.

5. **Python Malicious (Supply Chain)**:
   - Location: `/home/ubuntu/python-malicious`
   - `setup.py` attempts outbound HTTP POST to `10.255.255.1:80/exfil` during package import before `setup()`. Caught by network egress sensor during `pip install .`. Produces `[VERDICT] BLOCK` (quarantined).

---

## 5. Attack Scenarios Library

Location: `/home/ubuntu/attacks`
All scenarios wrap the Banking API with dedicated attack scripts:
- **`01-shell-exec`**: Direct shell execution (`/bin/sh -c 'curl ...'`). Caught by process tree diff and egress monitor. Verdict: `BLOCK`.
- **`02-http-exfil`**: Reading `~/.npmrc` and POSTing to `10.255.255.1:8443`. Caught by egress monitor and process scanner. Verdict: `BLOCK`.
- **`03-fs-tamper`**: Modifies and deletes source files during build without network traffic. Caught by filesystem Merkle root difference. Verdict: `BLOCK`.
- **`04-base64-shell`**: Base64-obfuscated payload decoded and executed at runtime. Caught by process tree scanner. Verdict: `BLOCK`.
- **`05-multi-stage`**: Recon + file tamper + exfiltration in a single build. Triggers all three sensors. Verdict: `BLOCK`.
- **`06-slow-exfil`**: Sustained 8-second HTTP connection to `10.255.255.1:8080`. Caught by background network poller. Verdict: `BLOCK`.
- **`07-anomaly`**: Deviant build characteristics against historical baseline. Caught by statistical anomaly engine. Verdict: `BLOCK`.

---

## 6. VM-2 Integration & Health

- **Target Address**: `192.168.88.133`
- **CI Service Port**: `8888`
- **ICMP Ping**: 0% packet loss (avg 1.8ms)
- **Health Check (`GET http://192.168.88.133:8888/health`)**:
  ```json
  {"status":"ok","service":"pipejack-ci","timestamp":"2026-10-03T05:25:21Z"}
  ```
- **Upload Endpoint**: `POST http://192.168.88.133:8888/upload` (accepts multipart `file=@<tarball>`)

---

## 7. Test Matrix Execution & Verification Summary

| Target / Scenario | Artifact | HTTP Code | CI Verdict | Enforcement Action | Verification |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Java Clean** | `banking-api-clean.tar.gz` | `200` | `ALLOW` | Built, Published, Deployed | PASS |
| **Java Malicious** | `banking-api-malicious.tar.gz` | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Node.js Clean** | `nodejs-app-clean.tar.gz` | `200` | `ALLOW` | Built, Published, Deployed | PASS |
| **Node.js Malicious** | `nodejs-app-malicious.tar.gz` | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Python Clean** | `python-app-clean.tar.gz` | `200` | `ALLOW` | Built, Published, Deployed | PASS |
| **Python Malicious** | `python-app-malicious.tar.gz` | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Attack 01 (shell-exec)** | `attack-01-shell-exec.tar.gz` | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Attack 02 (http-exfil)** | `attack-02-http-exfil.tar.gz` | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Attack 03 (fs-tamper)** | `attack-03-fs-tamper.tar.gz` | `200 (Empty)`* | `BLOCK` | Quarantine build compilation failed | DEFECT (Integration) |
| **Attack 04 (base64-shell)**| `attack-04-base64-shell.tar.gz`| `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Attack 05 (multi-stage)** | `attack-05-multi-stage.tar.gz` | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Attack 06 (slow-exfil)**  | `attack-06-slow-exfil.tar.gz`  | `403` | `BLOCK` | Quarantined (`-quarantine` tag) | PASS |
| **Attack 07 (anomaly)**     | `attack-07-anomaly.tar.gz`     | `200` | `ALLOW` | Anomaly finding (advisory mode) | PASS (Advisory) |

---

## 8. Current Known Issues & Adjustments

1. **Quarantine Build Compile Failure (Scenario 03)**:
   - When an attack deletes required source files, `custom-ci` attempts `docker build` for the quarantine image, which fails compilation. `custom-ci/main.go` returns prematurely on line 566 without writing the HTTP response headers or body.
2. **`attacks/run-all.sh` timeout**:
   - The runner script originally had `curl -m 30`, which timed out before Maven build containers could complete full package compilation (~130-150s).
   - Adjusted to `-m 180` to reliably accommodate Java compilation while maintaining automated test execution.
3. **Anomaly Engine Duration Z-Score Jitter**:
   - Cold builds taking ~30s against a warm baseline mean of ~10s trigger high-sigma duration anomalies.

