# VM-1 Handoff Document

**File Owner**: VM-1 (Developer / QA Lead / Repository Auditor)  
**Access Rule**: Owned exclusively by VM-1. VM-2 reads this file; VM-2 never edits it.

---

- **STATUS**: READY_FOR_REVIEW
- **CURRENT TASK**: GitHub Post-Publication Source Audit, Reconciliation & Hardening Completed
- **BRANCH**: feature/vm1-final-source-audit
- **BASE COMMIT**: 674bedfcf6d2e5260a26ea591737ff871baaa85b (GitHub origin/main)
- **FILES CHANGED**:
  - `applications/calculator-api/build-tarball.sh` (Added packaging tool for calculator API parity)
  - `attacks/01-shell-exec/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/02-http-exfil/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/03-fs-tamper/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/04-base64-shell/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/05-multi-stage/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/06-slow-exfil/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/07-anomaly/build.sh` (Made BANKING path dynamically resolve to repository applications/banking-api)
  - `attacks/run-all.sh` (Made scenario discovery portable to repo root or ~/attacks)
  - `scripts/pipejack-upload.sh` (Parameterized CI_ENDPOINT to support environment variable override)
  - `security-fixtures/evil-pkg/package.json` (Restored missing npm rogue supply chain fixture)
  - `security-fixtures/evil-pkg/build.sh` (Added npm pack builder script for evil-pkg fixture)
  - `security-fixtures/evil-pkg/README.md` (Documented evil-pkg security fixture behavior)
  - `docs/VM1_SOURCE_MAP.md` (Added evil-pkg entry to source map)
  - `docs/FINAL_VM1_QA_AUDIT.md` (Synchronized VM-1 final QA audit report)
  - `docs/VM1_GITHUB_POSTPUBLICATION_AUDIT.md` (Added comprehensive post-publication audit report)
  - `docs/VM1_HANDOFF.md` (Updated VM-1 handoff state)
- **TESTS RUN**:
  - Clean Application Suite: Built from source and uploaded to `http://192.168.88.133:8888/upload`
    - Java Banking API (`/tmp/banking-api-clean.tar.gz`): Build ID `1791218843`
    - Java Calculator API (`/tmp/calculator-api.tar.gz`): Build ID `1791219182`
    - Node.js App (`/tmp/nodejs-app-clean.tar.gz`): Build ID `1791219066`
    - Python App (`/tmp/python-app-clean.tar.gz`): Build ID `1791219119`
  - Malicious Application Suite: Built from source and uploaded to `http://192.168.88.133:8888/upload`
    - Java Banking API Malicious (`/tmp/banking-api-malicious.tar.gz`): Build ID `1791218952`
    - Node.js App Malicious (`/tmp/nodejs-app-malicious.tar.gz`): Build ID `1791219095`
    - Python App Malicious (`/tmp/python-app-malicious.tar.gz`): Build ID `1791219145`
  - Attack Scenarios 01–07: Executed via `./attacks/run-all.sh` from repository root
  - Secret & Credential Scanning: Automated regex scan for private keys, GitHub tokens, AWS keys
  - Clean Clone Reproducibility: Validated repository cloning and execution portability
- **TEST RESULTS**:
  - Clean Workloads: 4 / 4 ALLOW (HTTP 200 OK, Ed25519 attestation signed and chained, images deployed)
  - Malicious Workloads: 3 / 3 BLOCK (HTTP 403 Forbidden, policy violations recorded, quarantined)
  - Attack Scenarios: 7 / 7 PASS (Scenarios 01–06: BLOCK & Quarantined; Scenario 07: ALLOW Advisory)
  - Secret Hygiene: 100% CLEAN (Zero credentials or private keys in repository source trees)
  - Clean Clone Buildability: PASS (Attack suites and app packaging now completely portable without hardcoded home paths)
- **REQUEST TO OTHER AGENT (VM-2)**:
  - VM-2 should inspect and review feature branch `feature/vm1-final-source-audit` on the official GitHub repository (`https://github.com/ramKarthik57/pipejack-platform.git`).
  - Read [`VM1_GITHUB_POSTPUBLICATION_AUDIT.md`](../audits/VM1_GITHUB_POSTPUBLICATION_AUDIT.md) for full audit details and evidence.
  - Merge branch `feature/vm1-final-source-audit` into `main` and fast-forward the shared bare repository (`sync-bare`) as appropriate.
  - (Optional VM-2 item): Inspect `scripts/deploy-ci.sh` to ensure `main.go` path points to `services/custom-ci/main.go`.
- **BLOCKERS**:
  - None.
- **NEXT ACTION**:
  - Await VM-2 review and merge of `feature/vm1-final-source-audit` into `main`.
