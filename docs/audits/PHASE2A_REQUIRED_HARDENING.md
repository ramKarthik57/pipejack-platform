# PipeJack — Phase 2A Required Security Hardening Report

**Role**: VM-2 Security / CI / Integration Lead  
**Branch**: `agent/vm2`  
**Host Environment**: VM-2 (`192.168.88.133`), Ubuntu 24.04 LTS (Linux kernel `6.8.0-31-generic`)  
**Shared Baseline**: `4d04391b14b74ef77976e9fafc0fafa19ba9954a`  
**CI Daemon**: `pipejack-ci.service` (Active, PID 15315, Port 8888, Health HTTP 200 OK)  
**Date**: October 2026  

---

## 1. Scope

Phase 2A delivers **only the mandatory, required security hardening items** identified during the Phase 1 Deep Engineering and Adversarial Audits:
1. **Quarantine / CI Error-Path Hardening**: Elimination of silent drops and empty HTTP responses when Docker quarantine builds fail on corrupted/tampered payloads (Scenario 03 root cause).
2. **`proctree` Standalone Unit Test Suite**: Comprehensive, deterministic tests for policy parsing, cgroup matching, binary allowlisting, process deduplication, and error paths.
3. **`fschecker` Standalone Unit Test Suite**: Comprehensive, deterministic tests for baseline Merkle root computation, empty/non-existent tree handling, ignore prefix filtering, diff detection (added/modified/deleted), and PDP pattern compatibility (`target/**`, `*.pyc`, `*.egg-info/**`).
4. **Builder Image Immutable Digest Pinning**: Elimination of mutable tags for all Java/Maven, Node.js, and Python builder and runtime images by pinning verified SHA-256 digests.

*Non-Goals Explicitly Excluded from Phase 2A*: eBPF migration, API token authentication, JSON schema policy formalization, dynamic deployment ports, automated image pruning, Kubernetes orchestration, and full in-memory interpreter hooking.

---

## 2. Phase 1 Findings Addressed

| Audit Finding ID | Severity | Problem Statement | Resolution in Phase 2A |
| :--- | :---: | :--- | :--- |
| **ADV-A03 / ENG-4.1** | **CRITICAL** | When an attack deletes or corrupts source code (Scenario 03 FS Tamper), the quarantine Docker build fails compilation. `custom-ci/main.go` exited silently without sending HTTP headers or body, producing client-side silent drops. | Redesigned artifact and quarantine error handling in `processArtifactManagement()`. If quarantine compilation fails on a `BLOCK` verdict, `custom-ci` now writes `HTTP 403 Forbidden` with explicit JSON detailing the block verdict and quarantine build failure. |
| **ENG-3.2** | **MEDIUM** | `pipejack/proctree` lacked dedicated unit tests (`[no test files]`), relying entirely on cross-VM integration tests. | Implemented `pipejack/proctree/scanner_test.go` with 10 deterministic test cases covering parsing, wildcards, malformed inputs, cgroup filtering, and host process deduplication. |
| **ENG-3.2** | **MEDIUM** | `pipejack/fschecker` lacked dedicated unit tests (`[no test files]`), leaving Merkle tree computation unverified in isolation. | Implemented `pipejack/fschecker/checker_test.go` with 11 deterministic test cases verifying SHA-256 digests, diff types, empty roots, and PDP glob pattern compatibility. |
| **ENG-2.4** | **HIGH** | Builder images used mutable tags (`maven:3.8-eclipse-temurin-17`, `node:18-alpine`, `python:3.12-alpine`), exposing builds to upstream tag mutation and supply-chain tampering. | Pinned all builder and runtime base images to immutable SHA-256 digests in both CI server orchestration (`custom-ci/main.go`) and Dockerfiles. |

---

## 3. Quarantine Defect Root Cause Analysis

In the original `custom-ci/main.go` implementation (lines 556–568):
```go
log("DOCKER BUILD", fmt.Sprintf("Building image %s ...", imageName))
if _, err := os.Stat(dockerfileHostPath); err == nil {
    copyFile(dockerfileHostPath, filepath.Join(workspace, "Dockerfile"))
} else {
    log("FAIL", "Dockerfile missing")
    return // <--- Defect: Naked return without writing HTTP status or JSON body
}
out, err := execHost("docker", "build", "-t", imageName, workspace)
log("DOCKER BUILD", filterDockerOutput(out))
if err != nil {
    log("FAIL", "Docker build failed")
    return // <--- Defect: Naked return without writing HTTP status or JSON body
}
```

When an adversarial attack (such as Scenario 03) modified or deleted essential application source files (`AccountService.java`), the PipeJack security sensors correctly caught the tampering and emitted `[VERDICT] BLOCK`.
However, because `policy-banking.yaml` had `quarantine: true`, the CI pipeline proceeded to build the quarantine image via `docker build`.
Inside the build container, `mvn clean package` failed compilation due to the missing source files.
The Go HTTP handler logged `Docker build failed` and executed a raw `return`.
In Go's `net/http` server, returning from a handler without invoking `w.WriteHeader()` or `w.Write()` causes the server to close the connection with an empty `HTTP 200 OK` (0 bytes payload), completely hiding the security verdict and confusing the developer client.

---

## 4. Quarantine Hardening Implementation

The artifact management and quarantine logic was refactored into a dedicated function `processArtifactManagement()` with strict fail-safe invariants:

1. **Deterministic Error Handling on BLOCK**:
   If `verdict == "BLOCK"`, any failure during quarantine image creation (whether missing Dockerfile or compiler/build failure) **MUST NEVER** result in a silent exit or status 200.
   Instead, the server issues:
   - Status: `HTTP 403 Forbidden`
   - Content-Type: `application/json`
   - Payload:
     ```json
     {
       "status": "blocked",
       "build_id": "<buildID>",
       "verdict": "BLOCK",
       "quarantine": "failed",
       "error": "quarantine build failed: compilation/build error"
     }
     ```
2. **Deterministic Error Handling on ALLOW**:
   If `verdict == "ALLOW"` but a non-malicious application build fails inside Docker, the server issues:
   - Status: `HTTP 500 Internal Server Error`
   - Content-Type: `application/json`
   - Payload:
     ```json
     {
       "status": "error",
       "build_id": "<buildID>",
       "verdict": "ALLOW",
       "error": "Docker build failed"
     }
     ```
3. **Preservation of Successful Quarantine**:
   When quarantine image building, tagging, and registry pushing succeed, the response remains identical to Phase 1:
   - Status: `HTTP 403 Forbidden`
   - Payload: `{"status":"quarantined","build_id":"...","verdict":"BLOCK","tag":"localhost:5000/...-quarantine"}`

---

## 5. New CI Regression Tests (`custom-ci/quarantine_test.go`)

A dedicated unit/regression test file was created for `custom-ci`:
- **`TestQuarantine_BlockedWithQuarantineSuccess`**: Verifies that when a build is blocked and quarantine succeeds, the client receives `HTTP 403`, `verdict: "BLOCK"`, `status: "quarantined"`, and the quarantine tag.
- **`TestQuarantine_BlockedWithQuarantineBuildFailure`**: Verifies that when a build is blocked and Docker compilation fails, the client receives `HTTP 403`, `verdict: "BLOCK"`, `status: "blocked"`, `quarantine: "failed"`, and the compilation error message.
- **`TestQuarantine_BlockedWithMissingDockerfile`**: Verifies that missing Dockerfiles on a blocked build return `HTTP 403` with `quarantine: "failed"`.
- **`TestBuild_CleanSuccessRemainsAllow`**: Verifies that a clean build with verdict `ALLOW` returns `HTTP 200` with `status: "pass"`.
- **`TestBuild_CleanBuildFailureReturnsError`**: Verifies that a clean build encountering Docker errors returns `HTTP 500` with `status: "error"` and `verdict: "ALLOW"`.

---

## 6. `proctree` Standalone Unit Tests (`pipejack/proctree/scanner_test.go`)

Implemented 10 standalone unit tests covering all pure logic without flaky timing dependencies:
1. `TestPolicyParsing_Valid`: Confirms YAML parsing of allowlisted executables.
2. `TestPolicyParsing_Wildcard`: Validates that wildcard (`"*"`) policies bypass process checking and return `nil, nil`.
3. `TestPolicyParsing_MissingFile`: Verifies clean error handling on missing policy files.
4. `TestPolicyParsing_MalformedYAML`: Validates syntax error detection for invalid YAML.
5. `TestInCgroup_EmptyTarget`: Confirms empty target matches all processes.
6. `TestInCgroup_NonExistentPID`: Confirms non-existent PIDs safely evaluate to `false`.
7. `TestInCgroup_SelfProcess`: Validates `/proc/<pid>/cgroup` string scanning against caller cgroup.
8. `TestScanCgroup_NonExistent`: Validates that querying an unassociated cgroup returns an empty list without error.
9. `TestScanCgroup_HostProcs`: Confirms `/proc` parsing, executable resolution, and path deduplication.
10. `TestRun_AllowlistDeduplicationAndDetection`: Validates policy allowlist filtering and ensures each executable path appears at most once in reported violations.

*Architectural Limitation Note*: Polling `/proc` every 150ms has an inherent blindspot for ephemeral sub-150ms binaries. This limitation is formally documented in the test suite and source; mitigation is provided by `netmon` and `fschecker`.

---

## 7. `fschecker` Standalone Unit Tests (`pipejack/fschecker/checker_test.go`)

Implemented 11 standalone unit tests covering Merkle tree computation and diff analysis:
1. `TestBuildMerkleTree_BaselineGeneration`: Verifies file hashing, sorting, and 64-character SHA-256 Merkle root generation.
2. `TestBuildMerkleTree_DeterministicOutput`: Verifies identical Merkle roots across independent runs with varying file creation order.
3. `TestBuildMerkleTree_EmptyDirectory`: Confirms empty directories evaluate to standard empty-string SHA-256 hash (`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`).
4. `TestBuildMerkleTree_NonExistentPath`: Validates error return for invalid filesystem roots.
5. `TestBuildMerkleTree_IgnorePrefixes`: Confirms exclusion of `target/`, `.git/`, and `node_modules/`.
6. `TestCompareSnapshots_UnchangedFilesystem`: Verifies zero changes detected on identical snapshots.
7. `TestCompareSnapshots_ModifiedFile`: Verifies detection and classification of modified files.
8. `TestCompareSnapshots_AddedFile`: Verifies detection of newly introduced files.
9. `TestCompareSnapshots_DeletedFile`: Verifies detection of deleted files.
10. `TestCompareSnapshots_MultiChange`: Verifies simultaneous handling of modified, added, and deleted files.
11. `TestPolicyPatternCompatibility`: Integrates `fschecker` output with `pdp.Evaluate()` to verify pattern filtering for `target/**`, `*.pyc`, `*.egg-info/**`, and unauthorized files like `Backdoor.java`.

---

## 8. Builder Images Before vs. After Pinning

| Runtime Stack | Original Reference (Mutable) | Pinned Reference (Immutable SHA-256 Digest) |
| :--- | :--- | :--- |
| **Java / Maven Builder** | `maven:3.8-eclipse-temurin-17` | `maven@sha256:40fcff4c4043d6adc90286c2e38ec70950f34f6dd5784f7e524866c66520cc23` |
| **Java Runtime Base** | `eclipse-temurin:17-jre` | `eclipse-temurin@sha256:92999aea37688157a53a40bfcb187c30f317422e028045fd5fc5c548fde9e626` |
| **Node.js Builder/Runtime** | `node:18-alpine` | `node@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e` |
| **Python Builder/Runtime** | `python:3.12-alpine` | `python@sha256:0687a6bc9716edc2a6ee0fbfb0f87e7ee358b262b67c9215de91bc9b2d38ba71` |

### Verification Method:
Digests were resolved directly from local image manifests using Docker inspection:
```bash
docker inspect <image:tag> --format '{{json .RepoDigests}}'
```
All pinned references were validated by executing test containers and test builds (`docker run --rm <image@sha256:...> ...`).

---

## 9. Test Results Summary

### Unit Tests
- **`pipejack/fschecker`**: 11 / 11 PASS (`0.009s`)
- **`pipejack/proctree`**: 10 / 10 PASS (`0.037s`)
- **`pipejack/internal/anomaly`**: 9 / 9 PASS (`0.005s`)
- **`pipejack/internal/egressfw`**: 2 / 2 PASS (`0.037s`)
- **`pipejack/internal/netmon`**: 9 / 9 PASS (`0.029s`)
- **`pipejack/internal/pdp`**: 6 / 6 PASS (`0.009s`)
- **`custom-ci`**: 5 / 5 PASS (`0.009s`)
- **Code Linter**: `go vet ./...` clean across both `pipejack` and `custom-ci` (0 warnings).

### Live CI Integration Tests
1. **Quarantine Build Failure (Scenario 03 Reproduction)**:
   - Payload: Node.js package with unauthorized egress (`curl`) and broken JSON in `package.json` causing quarantine `docker build` failure.
   - Result: **HTTP 403 Forbidden**
   - Body: `{"status":"blocked","build_id":"1791028379","verdict":"BLOCK","quarantine":"failed","error":"quarantine build failed: compilation/build error"}`
   - Attestation: Signed and chained (`1791028379.json`).
2. **Clean Node.js Build (Pinned Image)**:
   - Result: **HTTP 200 OK**, `verdict: "ALLOW"`, attestation signed, deployed.
3. **Malicious Node.js Build (Supply-Chain Egress)**:
   - Result: **HTTP 403 Forbidden**, `verdict: "BLOCK"`, tagged and quarantined (`localhost:5000/vuln-app:1791028422-quarantine`), deployment prevented.
4. **Clean Python Build (Pinned Image)**:
   - Result: **HTTP 200 OK**, `verdict: "ALLOW"`, attestation signed, deployed.

---

## 10. Attestation Chain & Service Health

- **Attestation Verification**: Executed `verify-attest.go` over all 66 historical attestations in `/home/ubuntu/pipejack-attestations/`:
  ```
  ✅ 1791028379.json  verdict=BLOCK (quarantine failed)
     self_hash match: true, signature valid: true, chain link: true
  ✅ 1791028422.json  verdict=BLOCK (quarantined)
     self_hash match: true, signature valid: true, chain link: true
  ✅ 1791028600.json  verdict=ALLOW (clean python)
     self_hash match: true, signature valid: true, chain link: true
  ✅ CHAIN INTACT
  ```
- **Daemon Status**:
  - `pipejack-ci.service` active and running (Main PID `15315`)
  - `systemctl is-active`: `active`
  - `systemctl is-enabled`: `enabled`
  - `/health` response: HTTP 200 `{"status":"ok","service":"pipejack-ci","timestamp":"..."}`

---

## 11. Remaining Limitations & Explicit Non-Goals

1. **Interpreter In-Memory Script Execution**:
   Scripts executing purely within allowlisted interpreters (`node`, `python3`) without spawning child processes do not trigger `proctree` binary path violations. They are intercepted by `netmon` (egress sockets) and `fschecker` (file changes).
2. **Cold-Start Duration Z-Scores**:
   Initial container compilation from a cold cache may deviate from warm baseline averages.
3. **Explicit Statement of Items NOT Fixed in Phase 2A**:
   - eBPF kernel tracepoint execution is not activated (`execwatch.go` remains dormant).
   - API endpoints remain unauthenticated (designed for isolated VM network).
   - Dynamic port allocation for deployed apps is not implemented.
