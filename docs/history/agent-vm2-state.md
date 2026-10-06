# VM-2 Agent State

This file records the runtime, network, service, and repository state of VM-2.
Owned exclusively by the VM-2 Integrator / Security Engineer Agent.

---

## 1. Git State & Repository Information

- **Working Directory**: `/home/ubuntu/pipejack-dev`
- **Current Branch**: `main`
- **Current Head Commit**: `749b9252e021ce41dbfb300c8b34a2354b809bf4`
- **Commit History Summary**:
  - `749b925`: docs: Establish two-VM synchronization baseline (SYNC_BASELINE.md)
  - `253c1c7`: docs(vm-1): Add VM-1 agent state and verification report
  - `bf10ca1`: docs: Add shared agent context and VM-2 state tracking
  - `9c770bb`: Merge branch 'origin/main' into main (combines VM-1 evil-pkg tests with VM-2 security engine)
- **Configured Remotes**:
  - `sync-bare`: `/home/ubuntu/pipejack.git` (URL for VM-1 over SSH: `ssh://ubuntu@192.168.88.133/home/ubuntu/pipejack.git`)
  - `origin`: `https://github.com/ramKarthik57/pipejack-test.git` (upstream tracking)

---

## 2. Network & Host Configuration

- **VM-2 IP Address**:
  - Primary interface (`ens33`): `192.168.88.133/24`
  - Secondary interface (`ens37`): `192.168.152.130/24`
  - Docker bridge (`docker0`): `172.17.0.1/16`
- **VM-1 IP Address**:
  - Discovered via neighbor/ARP and sshd logs: `192.168.88.132`
  - ICMP Ping: 0% packet loss (latency ~1-6 ms)
  - SSH Ingress: Active from VM-1 to VM-2 (`192.168.88.133:22`)
- **VM-2 SSH Server**:
  - Service: `ssh.service` active and running on `0.0.0.0:22`
  - Public Key for VM-2: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINT8OW8+JvjYzpAucDqozEKDn3T5BwpOvGmcPcRPmlGX vm2-pipejack`
  - Authorized Keys path: `/home/ubuntu/.ssh/authorized_keys`

---

## 3. Service & Daemon Status

- **Systemd Unit**: `pipejack-ci.service`
  - Unit Path: `/etc/systemd/system/pipejack-ci.service`
  - Status: `active (running)`
  - Enabled: `enabled` (auto-starts on boot)
  - Main PID: 2703 (binary: `/usr/local/bin/pipejack-ci`)
  - Working Directory: `/home/ubuntu/custom-ci`
  - Log Destination: `/var/log/pipejack-ci.log`
- **HTTP Service**:
  - Listen Port: `8888` (`ss -ltnp` confirmed listening)
  - Health Endpoint: `http://localhost:8888/health` -> `{"status":"ok","service":"pipejack-ci","timestamp":"..."}`
  - Upload Endpoint: `http://192.168.88.133:8888/upload`
- **Environment Configuration**: `/etc/pipejack/ci.env`
  - `PIPEJACK_BIN=/usr/local/bin/pipejack-ci`
  - `PIPEJACK_WORKDIR=/home/ubuntu/custom-ci`
  - `PIPEJACK_PORT=8888`
  - `PIPEJACK_ENFORCE=1` (enforcement enabled)
  - `PIPEJACK_FAST=0` (full pipeline with build, push, deploy)
  - `PIPEJACK_DEV=0` (production real build)

---

## 4. Docker & Registry Status

- **Local Registry**: `registry:2` container running on `0.0.0.0:5000` (container ID `16ca16d8cf86`)
- **Sidecar Image**: `pipejack-daemon:latest` present
- **Build Base Images**:
  - `maven:3.8-eclipse-temurin-17`
  - `node:18-alpine`
  - `python:3.12-alpine`

---

## 5. Security & Baseline Status

- **Cryptographic Attestations**:
  - Directory: `/home/ubuntu/pipejack-attestations/`
  - Chain Integrity: Fully intact (`verify-attest.go` verified all historical build entries without errors)
  - Key Pair: Ed25519 in `/home/ubuntu/.pipejack/attest-key` and `.pub`
- **Anomaly Detection Baselines**:
  - Directory: `/home/ubuntu/pipejack-baseline/`
  - Active Baselines:
    - `banking-api.json`: Rolling metrics from 20 builds
    - `node.js-app.json`: Rolling metrics baseline
    - `python-app.json`: Rolling metrics baseline

---

## 6. Last Validations Performed

1. **Unit & Package Tests**:
   - `pipejack-dev/pipejack`: `go test -v ./...` executed across all internal packages (`anomaly`, `egressfw`, `netmon`, `pdp`) -> **100% PASS**.
   - `custom-ci`: `go test` and `go vet` executed -> **CLEAN / PASS**.
2. **Attestation Chain Verification**:
   - `verify-attest.go` executed over `/home/ubuntu/pipejack-attestations/` -> **CHAIN INTACT**.
3. **CI Daemon Health Check**:
   - `curl -s http://localhost:8888/health` verified -> **STATUS OK**.
4. **Git Synchronization**:
   - Created `/home/ubuntu/pipejack.git` bare synchronization repository.
   - Pushed merged `main` containing all VM-1 and VM-2 commits.
   - Baseline established at `749b925`.
5. **Phase 1 Deep Engineering Audit**:
   - Completed factual discovery audit across all subsystems, sensors, policies, and tests.
   - Generated `docs/PHASE1_ENGINEERING_AUDIT.md`.
   - All 26 unit tests passed; all 58 historical attestations verified.
