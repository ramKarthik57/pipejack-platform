# PipeJack Two-VM Synchronization Baseline

This document establishes the verified, synchronized baseline between VM-1 (Developer / Test Engineer) and VM-2 (Integrator / Security Engineer) for the PipeJack Security Engine and CI/CD environment.

---

## 1. Machine Identification & Network Topology

| Attribute | VM-1 (Developer / Test Side) | VM-2 (Integrator / Security Side) |
| :--- | :--- | :--- |
| **Role** | Test applications, attack scenarios, payload packaging, client-side testing | CI/CD server, PipeJack sensors, PDP, anomaly engine, attestation, deployment |
| **Primary IP (`ens33`)** | `192.168.88.132/24` | `192.168.88.133/24` |
| **Secondary IP (`ens37`)** | `192.168.152.131/24` | `192.168.152.130/24` |
| **Primary Workspace** | `/home/ubuntu/pipejack-dev` | `/home/ubuntu/pipejack-dev` |
| **Runtime Workdir** | `/home/ubuntu` (apps, attacks) | `/home/ubuntu/custom-ci` (service directory) |
| **SSH Connectivity** | SSH client (outbound to VM-2:22) | OpenSSH server listening on `0.0.0.0:22` |
| **SSH Authentication** | Ed25519 key (`~/.ssh/id_ed25519`) | Authorized keys contains VM-1 public key |

---

## 2. Agreed Git Remote & Repository Topology

- **Primary Shared Synchronization Remote**:
  - Remote Name: `sync-bare`
  - URL (from VM-1 over SSH): `ssh://ubuntu@192.168.88.133/home/ubuntu/pipejack.git`
  - URL (local on VM-2): `/home/ubuntu/pipejack.git`
  - Default Branch: `main`
- **Upstream Tracking Remote**:
  - Remote Name: `origin`
  - URL: `https://github.com/ramKarthik57/pipejack-test.git` (preserved as read/fetch mirror)

---

## 3. Agreed Baseline Commit & Branch

- **Active Branch**: `main`
- **Agreed Baseline Commit**:
  - Initial Reconciled Commit: `253c1c795909946dad15404c11282bedadae2d46`
  - Subject: `docs(vm-1): Add VM-1 agent state and verification report`
  - Baseline Reconciliation Commit: Includes this `docs/SYNC_BASELINE.md` specification.
- **Commit Lineage Summary**:
  ```
  * [CURRENT HEAD] (HEAD -> main, sync-bare/main) docs: Establish two-VM synchronization baseline
  * 253c1c7 docs(vm-1): Add VM-1 agent state and verification report
  * bf10ca1 docs: Add shared agent context and VM-2 state tracking
  * 9c770bb Merge branch 'origin/main' into main
  |\  
  | * 266cf10 (origin/main) add evil dependency (file exfil)
  | * 6887f14 review: clean build demo
  * | 9c2a1b8 Step 8-10: Anomaly detection, multi-language support, and production deployment
  * | 9763c05 Stop tracking prebuilt pipejackd-static binary
  * | 0ba3ac9 Fix .gitignore: anchor build artifacts to project root
  * | aa9b0d8 Step 6: network egress interceptor (passive + iptables) + docs
  |/  
  * 9892d24 Complete Phase 2 - all three sensors integrated and tested
  ```

---

## 4. Synchronization Procedure

Both agents adhere to the following workflow for all future iterations:

### Step 1: Pre-Change Verification
Before making changes, verify that the local working tree is clean and up to date:
```bash
git status
git fetch sync-bare
git merge --ff-only sync-bare/main
```

### Step 2: Local Development & Verification
- VM-1 develops in test applications (`banking-api`, `nodejs-*`, `python-*`, `attacks`).
- VM-2 develops in PipeJack core (`pipejack/`), CI server (`custom-ci/`), or policies (`policy-*.yaml`).
- Always run local tests before committing (`go test ./...`).

### Step 3: Atomic Commit & Push
Commit with clear descriptive messages and push to `sync-bare`:
```bash
git add <files>
git commit -m "<component>: <concise description>"
git push sync-bare main
```

### Step 4: Downstream Integration
The peer VM fetches and merges the change:
```bash
git fetch sync-bare
git merge sync-bare/main
```

### Prohibited Operations:
- Never run `git reset --hard` or `git clean -fd`.
- Never force-push (`git push --force` or `-f`) to `sync-bare`.
- Never commit runtime state (attestations, baselines, logs, compiled binaries).

---

## 5. Agent Ownership Model

- **VM-1 (Developer / Test Engineer)**:
  - **Owns**: Application codebases (`banking-api`, `nodejs-app`, `python-app`), supply-chain attack vectors (`evil-pkg`, `nodejs-malicious`, `python-malicious`), attack scenario scripts (`attacks/`), and VM-1 state documentation (`docs/agent-vm1-state.md`).
  - **Consults**: VM-2 when security policies require adjustments for new application dependencies.

- **VM-2 (Integrator / Security Engineer)**:
  - **Owns**: PipeJack engine (`pipejack/`), sensors (`proctree`, `fschecker`, `netmon`, `egressfw`), Policy Decision Point (`pdp`), anomaly engine (`anomaly`), CI server (`custom-ci/`), YAML policies, attestation engine (`attest.go`), systemd units, and VM-2 state documentation (`docs/agent-vm2-state.md`).
  - **Consults**: VM-1 to ensure build workflows match developer expectations and language conventions.

---

## 6. Runtime & CI Server Health Verification

- **Service Status**:
  - Unit: `pipejack-ci.service`
  - State: `active (running)`
  - Startup: `enabled` (auto-starts on system boot)
  - Port: `8888` listening on all interfaces (`0.0.0.0:8888`)
- **Health Probe**:
  ```bash
  $ curl -s http://localhost:8888/health
  {"status":"ok","service":"pipejack-ci","timestamp":"2026-10-03T06:03:19Z"}
  ```
- **Configuration (`/etc/pipejack/ci.env`)**:
  - `PIPEJACK_ENFORCE=1` (Enforcement active: violations trigger BLOCK)
  - `PIPEJACK_FAST=0` (Full pipeline: packaging, security scan, container build, deploy)
  - `PIPEJACK_DEV=0` (Production build execution)
- **Security Storage**:
  - Attestations: `/home/ubuntu/pipejack-attestations/` (cryptographic chain verified intact)
  - Baselines: `/home/ubuntu/pipejack-baseline/` (rolling anomaly profiles active)

---

## 7. Divergence & Working Tree Audit

- **Unpushed Commits**: 0
- **Divergent Branches**: 0 (`main` and `sync-bare/main` are identical)
- **Uncommitted Modifications**: None (working tree clean)
- **Runtime Symlinks Preserved**:
  - `/home/ubuntu/pipejack-dev/custom-ci` -> `/home/ubuntu/custom-ci` (ignored via `.gitignore`)
