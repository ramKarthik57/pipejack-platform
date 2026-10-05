# VM-2 Handoff Document

**File Owner**: VM-2 (Security / CI Integration Lead)  
**Access Rule**: Owned exclusively by VM-2. VM-1 reads this file; VM-2 never edits VM1_HANDOFF.md.

---

- **STATUS**: COMPLETE
- **CURRENT TASK**: Phase 2A Required Security Hardening Completed, Verified & Merged to Main
- **BRANCH**: main
- **CURRENT COMMIT**: bd4c24e6ffec161fb4fc8403bc68a6f3b061d4b6
- **FILES CHANGED**:
  - `pipejack/proctree/scanner_test.go` (new unit test suite: 10 tests)
  - `pipejack/fschecker/checker_test.go` (new unit test suite: 11 tests)
  - `docs/PHASE2A_REQUIRED_HARDENING.md` (comprehensive Phase 2A technical report)
  - `docs/PHASE2A_REGRESSION_RESULTS.md` (VM-1 adversarial regression report)
  - `docs/VM1_HANDOFF.md` (VM-1 handoff certifying validation)
  - `docs/VM2_HANDOFF.md` (updated handoff state)
  - Host runtime changes in `custom-ci/`:
    - `custom-ci/main.go` (quarantine error path hardening, builder image digest pinning, processArtifactManagement)
    - `custom-ci/quarantine_test.go` (new regression test suite: 5 tests)
    - `custom-ci/Dockerfile.spring`, `Dockerfile.calc`, `Dockerfile.app`, `Dockerfile.python`, `Dockerfile.node` (pinned immutable digests)
    - `deploy.sh` executed, `pipejack-ci.service` running updated binary (PID 15315)
- **TESTS RUN**:
  - Full test suite across both VMs: 52 unit tests (47 `pipejack` + 5 `custom-ci`)
  - Complete live adversarial regression suite (Clean & Malicious Java, Node.js, Python, Attacks 01–07)
  - Attestation ledger chain verification: 100% verified intact
  - Daemon health probe: `curl -s http://192.168.88.133:8888/health` &rarr; HTTP 200 OK
- **TEST RESULTS**:
  - Unit tests: 52 / 52 PASS (100%)
  - Clean builds: 3 / 3 ALLOW, built, published, deployed
  - Malicious builds: 3 / 3 BLOCK, tagged and quarantined
  - Scenario 03 (FS Tamper) defect: RESOLVED (HTTP 403 Forbidden with valid JSON diagnostics, no silent drop)
  - Attacks 01–07: 7 / 7 PASS
  - Attestation ledger: CHAIN INTACT
  - Builder images: Immutable SHA-256 digests verified
- **REQUEST TO OTHER AGENT (VM-1)**:
  - VM-1 should pull latest `main` from `sync-bare` (`git pull sync-bare main`).
  - Stand by for Phase 2B / Phase 3 planning.
- **BLOCKERS**:
  - None. Phase 2A required hardening successfully completed.
- **NEXT ACTION**:
  - Coordinate with team on Phase 2B objectives.

---

## Verified Phase 2A Runtime State

### 1. Pinned Builder & Runtime Image Digests
- Java Builder: `maven@sha256:40fcff4c4043d6adc90286c2e38ec70950f34f6dd5784f7e524866c66520cc23`
- Java Runtime: `eclipse-temurin@sha256:92999aea37688157a53a40bfcb187c30f317422e028045fd5fc5c548fde9e626`
- Node.js: `node@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e`
- Python: `python@sha256:0687a6bc9716edc2a6ee0fbfb0f87e7ee358b262b67c9215de91bc9b2d38ba71`

### 2. CI Daemon & Attestation Status
- `pipejack-ci.service`: Active (running), PID `15315`
- Port: `8888` listening on `0.0.0.0`
- Attestation ledger: Verified in `/home/ubuntu/pipejack-attestations/`, Ed25519 chain intact
- Anomaly profiles: Active in `/home/ubuntu/pipejack-baseline/`
