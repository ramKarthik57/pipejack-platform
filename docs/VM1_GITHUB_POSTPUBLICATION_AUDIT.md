# PipeJack — VM-1 GitHub Post-Publication Source Audit Report

**Auditor**: Senior Developer / QA Engineer / Repository Auditor / Source-Code Custodian (VM-1)  
**Host Environment**: VM-1 (`192.168.88.132`), Ubuntu 24.04 LTS (`Linux 7.0.0-34-generic`)  
**Target Environment**: VM-2 (`192.168.88.133`), CI Daemon `:8888`, Demo Console `:8090`  
**Official GitHub Repository**: `https://github.com/ramKarthik57/pipejack-platform.git`  
**Base Commit**: `674bedfcf6d2e5260a26ea591737ff871baaa85b`  
**Feature Branch**: `feature/vm1-final-source-audit`  
**Date**: October 5, 2026  

---

## 1. Executive Summary

Following the initial consolidation, repository restructuring, and public GitHub publication of the PipeJack platform by VM-2, VM-1 performed an independent, authoritative post-publication audit and reconciliation of the source code, developer assets, security fixtures, and attack tooling.

### Key Audit Findings & Actions
1. **GitHub Baseline Integrity**: Verified `https://github.com/ramKarthik57/pipejack-platform.git` at commit `674bedf`. The monorepo structure cleanly decouples VM-1 applications/fixtures and VM-2 security daemon/CI services.
2. **Local VM-1 Comparison**: Performed recursive tree and file diffs against all active VM-1 directories (`banking-api`, `spring-calc`, `nodejs-app`, `python-app`, `nodejs-malicious`, `python-malicious`, `vuln-app`, `attacks`, and `pipejack-dev`).
3. **Reconciled Missing Fixtures (`evil-pkg`)**: Discovered that while `security-fixtures/evil-pkg/` was documented in `README.md`, the actual fixture package resided in `/home/ubuntu/pipejack-dev/evil-pkg` rather than `/home/ubuntu/evil-pkg`, causing it to be omitted from the initial commit. Restored `package.json`, created `build.sh` (which packages `evil-pkg-1.0.0.tgz`), added `README.md`, and updated `docs/VM1_SOURCE_MAP.md`.
4. **Added Parity Packaging Tooling (`calculator-api`)**: Added `applications/calculator-api/build-tarball.sh` to provide seamless single-command tarball packaging mirroring `banking-api`, `nodejs-app`, and `python-app`.
5. **Portability & Clean-Clone Hardening in Attack Tooling**:
   - Resolved hardcoded `BANKING=~/banking-api` paths in `attacks/01-shell-exec` through `attacks/07-anomaly` `build.sh` scripts. Replaced with dynamic discovery pointing to `../../applications/banking-api` relative to the script location, with automatic fallback to `~/banking-api`.
   - Updated `attacks/run-all.sh` to dynamically resolve attack scenario directories relative to the script location.
   - Updated `scripts/pipejack-upload.sh` to allow overriding `CI_ENDPOINT` via environment variables (`CI_ENDPOINT="${CI_ENDPOINT:-http://192.168.88.133:8888/upload}"`).
6. **Documentation Synchronization**: Integrated VM-1's comprehensive final QA report [`docs/FINAL_VM1_QA_AUDIT.md`](file:///home/ubuntu/pipejack-platform-vm1-audit/docs/FINAL_VM1_QA_AUDIT.md) into the unified repository.
7. **End-to-End Live CI Validation**:
   - Built fresh tarballs from repository sources and uploaded to VM-2 CI server (`192.168.88.133:8888`).
   - Clean builds: 4 / 4 ALLOW (Java Banking API, Java Calculator API, Node.js App, Python App).
   - Malicious builds: 3 / 3 BLOCK (Java Banking API Malicious, Node.js Malicious, Python Malicious).
   - Attack scenarios: 7 / 7 executed via repository `attacks/run-all.sh` (01–06: BLOCK & Quarantined, 07: ALLOW Advisory).
8. **Security & Secret Hygiene**: Verified zero private keys, API tokens, AWS credentials, or personal secrets in working copy or history.

---

## 2. GitHub Baseline Inspection

| Attribute | Verified Value |
| :--- | :--- |
| **Repository URL** | `https://github.com/ramKarthik57/pipejack-platform.git` |
| **Main Branch HEAD** | `674bedfcf6d2e5260a26ea591737ff871baaa85b` |
| **Commit Message** | `docs: finalize VM-1 handoff with official GitHub repository instructions` |
| **Audit Branch** | `feature/vm1-final-source-audit` |
| **License** | GPL-2.0-only (with Linux syscall exception) |
| **Secret Scanning** | Clean (0 detected credentials) |

---

## 3. Comprehensive Asset Inventory & Reconciliation Matrix

| VM-1 Host Source Path | Repository Target Path | Subsystem | Status | Actions Taken |
| :--- | :--- | :--- | :---: | :--- |
| `/home/ubuntu/banking-api/` | `applications/banking-api/` | Core Workload | **MATCH** | 100% byte-for-byte identical |
| `/home/ubuntu/spring-calc/` | `applications/calculator-api/` | Core Workload | **ENHANCED** | Added `build-tarball.sh` for build parity |
| `/home/ubuntu/nodejs-app/` | `applications/nodejs-app/` | Core Workload | **MATCH** | 100% byte-for-byte identical |
| `/home/ubuntu/python-app/` | `applications/python-app/` | Core Workload | **MATCH** | 100% byte-for-byte identical |
| `/home/ubuntu/nodejs-malicious/` | `security-fixtures/nodejs-malicious/` | Fixture | **MATCH** | 100% byte-for-byte identical |
| `/home/ubuntu/python-malicious/` | `security-fixtures/python-malicious/` | Fixture | **MATCH** | 100% byte-for-byte identical |
| `/home/ubuntu/vuln-app/` | `security-fixtures/vuln-app/` | Fixture | **MATCH** | 100% byte-for-byte identical |
| `/home/ubuntu/pipejack-dev/evil-pkg/` | `security-fixtures/evil-pkg/` | Fixture | **RESTORED** | Recovered `package.json`, added `build.sh` & `README.md` |
| `/home/ubuntu/attacks/01-shell-exec/` | `attacks/01-shell-exec/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/02-http-exfil/` | `attacks/02-http-exfil/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/03-fs-tamper/` | `attacks/03-fs-tamper/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/04-base64-shell/` | `attacks/04-base64-shell/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/05-multi-stage/` | `attacks/05-multi-stage/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/06-slow-exfil/` | `attacks/06-slow-exfil/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/07-anomaly/` | `attacks/07-anomaly/` | Attack Suite | **PORTABLE** | Replaced hardcoded `~/banking-api` with dynamic path |
| `/home/ubuntu/attacks/run-all.sh` | `attacks/run-all.sh` | Runner Script | **PORTABLE** | Script-relative scenario discovery & verdict mapping |
| `/home/ubuntu/pipejack-upload.sh` | `scripts/pipejack-upload.sh` | Client Script | **CONFIGURABLE**| Retained default, added `$CI_ENDPOINT` override |
| `/home/ubuntu/pipejack-dev/docs/FINAL_VM1_QA_AUDIT.md` | `docs/FINAL_VM1_QA_AUDIT.md` | Documentation | **SYNCHRONIZED**| Added VM-1 comprehensive final QA audit report |

---

## 4. Live Verification & Test Evidence

All builds were generated directly from the repository source trees (not using pre-existing local tarballs):

### Clean Application Suite

| Workload | Builder Script | Build ID | HTTP Status | Verdict | Attestation | Registry / Quarantine Status |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Banking API (Java 17)** | `banking-api/build-tarballs.sh` | `1791218843` | `200 OK` | `ALLOW` | Signed & Chained | `localhost:5000/banking-api:1791218843` (Deployed) |
| **Calculator API (Java 17)** | `calculator-api/build-tarball.sh` | `1791219182` | `200 OK` | `ALLOW` | Signed & Chained | `localhost:5000/calculator-api:1791219182` (Deployed) |
| **Payment Service (Node.js 18)** | `nodejs-app/build-tarball.sh` | `1791219066` | `200 OK` | `ALLOW` | Signed & Chained | `localhost:5000/vuln-app:1791219066` (Deployed) |
| **Analytics Core (Python 3.12)** | `python-app/build-tarball.sh` | `1791219119` | `200 OK` | `ALLOW` | Signed & Chained | `localhost:5000/vuln-app:1791219119` (Deployed) |

### Malicious Application Suite

| Workload | Vector | Build ID | HTTP Status | Verdict | Sensors Triggered | Quarantine Status |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **Banking API (Malicious)** | Exec Trojan (`malicious.sh`) | `1791218952` | `403 Forbidden` | `BLOCK` | Policy Decision violation | Quarantined |
| **Payment Service (Node.js)** | npm postinstall socket exfil | `1791219095` | `403 Forbidden` | `BLOCK` | Process Intercepted, FS Tamper, Egress Dropped | Quarantined |
| **Analytics Core (Python)** | setup.py curl exfil | `1791219145` | `403 Forbidden` | `BLOCK` | Process Intercepted, FS Tamper, Egress Dropped | Quarantined |

### Adversarial Scenarios Matrix (`attacks/run-all.sh`)

| Scenario | Vector Description | Observed Verdict | Status | Sensor Confirmation |
| :--- | :--- | :---: | :---: | :--- |
| **01-shell-exec** | Spawn `/bin/sh` payload during Maven compile | `BLOCK` | **PASS** | Process monitor blocked unauthorized binary |
| **02-http-exfil** | Outbound HTTP exfiltration via curl | `BLOCK` | **PASS** | Egress firewall dropped connection to `10.255.255.1:8443` |
| **03-fs-tamper** | Source code tampering during compilation | `BLOCK` | **PASS** | Merkle tree mismatch detected; quarantine handled |
| **04-base64-shell** | Obfuscated Base64 shell invocation | `BLOCK` | **PASS** | Decoded process intercept triggered |
| **05-multi-stage** | Staged compiler dropper | `BLOCK` | **PASS** | Multi-stage child process intercepted |
| **06-slow-exfil** | Low-frequency rate-limited exfiltration | `BLOCK` | **PASS** | Egress socket filter intercepted trickling traffic |
| **07-anomaly** | Statistical process count anomaly | `ALLOW` | **PASS** | Advisory mode evaluation permitted build |

---

## 5. Secret Hygiene & Code Cleanliness

The working tree was subjected to automated credential and secret scans:
- Zero RSA, Ed25519, or OpenSSH private keys found in committed trees.
- Zero GitHub personal access tokens (`ghp_*`) or AWS access keys (`AKIA*`) found.
- `.gitignore` cleanly excludes generated `*.tar.gz`, `*.tgz`, `node_modules/`, `target/`, and `__pycache__/` artifacts.
- No build-state artifacts or developer environment paths are committed.

---

## 6. Recommendations & Handoff to VM-2

1. **Merge Feature Branch**: VM-2 should review and merge `feature/vm1-final-source-audit` into `main`.
2. **Review `scripts/deploy-ci.sh`**:
   - `scripts/deploy-ci.sh` currently looks for `main.go` in `REPO_DIR` (line 16: `[ "$REPO_DIR/main.go" -nt "$BIN_SRC" ]`), which works inside `services/custom-ci/` but not from `scripts/`.
   - VM-2 (as owner of `services/`) may update `scripts/deploy-ci.sh` to reference `../services/custom-ci/main.go` or maintain `services/custom-ci/deploy.sh` as canonical.
3. **Canonical Baseline**: Once merged into `main`, both VM-1 and VM-2 can pull `main` from GitHub as the unified, definitive, post-publication baseline.
