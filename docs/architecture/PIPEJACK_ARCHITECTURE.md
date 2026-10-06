# PipeJack: Architectural Specification & Threat-Mitigation Design

![System Topology](../assets/system-topology.svg)

## 1. System Overview & Core Philosophy

Modern CI/CD pipelines represent one of the most critical yet least protected surfaces in enterprise software engineering. Contemporary build systems routinely execute untrusted third-party code—including package resolution hooks (`npm postinstall`, `pip setup.py`, Maven compiler plugins)—inside containerized worker nodes. While static application security testing (SAST) and container image scanning inspect code before execution or images post-compilation, the **build execution window itself remains completely opaque**.

PipeJack solves this build-time blind spot by establishing an active, transparent, host-level zero-trust security perimeter around containerized build tasks. Rather than relying solely on post-facto image scanners or in-container user-space wrappers (which can be easily evaded or disabled by malicious scripts running as `root` in the container), PipeJack enforces strict execution invariants from the host kernel and daemon layer.

```
                         ┌─────────────────────────────────┐
                         │   Untrusted Build Workspace     │
                         │   (Java, Node.js, Python, etc.) │
                         └───────────────┬─────────────────┘
                                         │
                   ┌─────────────────────▼─────────────────────┐
                   │    Containerized Build Isolation Boundary │
                   │       (Docker cgroup v2 + netns)          │
                   └───────┬─────────────┬─────────────┬───────┘
                           │             │             │
      ┌────────────────────▼──┐   ┌──────▼───────┐   ┌─▼──────────────────┐
      │  Process Invariants   │   │ Merkle Trees │   │  Network Egress    │
      │  (proctree: 150ms)    │   │ (fschecker)  │   │  (egressfw/netmon) │
      └────────────────────┬──┘   └──────┬───────┘   └─┬──────────────────┘
                           │             │             │
                   ┌───────▼─────────────▼─────────────▼───────┐
                   │        Policy Decision Point (PDP)        │
                   │     Zero-Trust Declarative Evaluation     │
                   └─────────────────────┬─────────────────────┘
                                         │
                        ┌────────────────┴────────────────┐
                        ▼                                 ▼
              ┌───────────────────┐             ┌───────────────────┐
              │  ALLOW: HTTP 200  │             │  BLOCK: HTTP 403  │
              │  • Push to Registry│            │  • Quarantine Tag  │
              │  • Deploy Service │             │  • Halt Deployment│
              └─────────┬─────────┘             └─────────┬─────────┘
                        │                                 │
                        └────────────────┬────────────────┘
                                         ▼
                   ┌───────────────────────────────────────────┐
                   │  Ed25519 Cryptographic Attestation Ledger │
                   │  Immutable SHA-256 Provenance Hash Chain  │
                   └───────────────────────────────────────────┘
```

---

## 2. Multi-Sensor Security Subsystems

![Build Security Lifecycle](../assets/multi-sensor-lifecycle.svg)

### 2.1 Process Tree Differ (`proctree`)
- **Location**: `core/pipejack/proctree/`, `core/pipejack/cmd/proctree/`
- **Mechanism**: Linux cgroup v2 `/proc` polling interval (150ms).
- **Functionality**:
  The Process Tree Differ maps the exact control group path of the build container (`/sys/fs/cgroup/system.slice/docker-<id>.scope`) and scans all active PIDs belonging to that scope every 150 milliseconds.
  For each detected PID, it resolves `/proc/<pid>/exe` to the absolute canonical binary path and checks it against the declared policy allowlist (`allowed_processes`).
- **Enforcement Rules**:
  - Compiler tools (`/usr/bin/mvn`, `/opt/java/openjdk/bin/java`, `/usr/local/bin/node`, `/usr/local/bin/python`) are permitted.
  - Interactive shells, rogue execution utilities, or downloaders (`/bin/sh`, `/bin/bash`, `/usr/bin/curl`, `/usr/bin/wget`, `/usr/bin/nc`) spawned outside policy immediately produce a critical violation.
- **Architectural Boundary Note**:
  The production runner operates via the resilient, kernel-portable Linux cgroup v2 `/proc` polling engine. The repository also vendors prototype eBPF tracepoint controllers (`ebpfctrl/`, `netblock/`) designed for zero-latency kernel tracepoints; in the current released baseline, cgroup `/proc` polling serves as the authoritative, non-flaky runtime sensor.

### 2.2 Filesystem Merkle Baseline Engine (`fschecker`)
- **Location**: `core/pipejack/fschecker/`
- **Mechanism**: Pre-build and post-build cryptographic SHA-256 Merkle tree calculation.
- **Functionality**:
  Before compiler execution begins, `fschecker` walks the `/workspace` hierarchy, computes individual SHA-256 hashes for all existing files, and derives a cryptographic root hash representing the exact workspace state.
  Following build execution, `fschecker` walks the workspace again, derives the new Merkle root, and generates a structured mutation diff:
  - `FilesAdded`: Files present post-build but absent pre-build.
  - `FilesModified`: Files whose SHA-256 hash mutated during the build.
  - `FilesDeleted`: Files removed during the build.
- **Enforcement Rules**:
  - Compiler output directories (`target/**`, `build/**`, `dist/**`, `__pycache__/**`) are explicitly allowed.
  - Source modifications (`src/**`, `pom.xml`, `package.json`, configuration files) or tampering with build scripts trigger an instant policy violation.

### 2.3 Network Egress Firewall & Socket Monitor (`egressfw`, `netmon`)
- **Location**: `core/pipejack/internal/egressfw/`, `core/pipejack/internal/netmon/`
- **Mechanism**: Active container network namespace `iptables` injection + passive `/proc/net` socket inspection.
- **Functionality**:
  To prevent supply chain packages from exfiltrating environment variables, credentials, or source code, PipeJack injects a dedicated `PIPEJACK_EGRESS` chain into the build container's network namespace:
  - Default policy: `DROP` outbound traffic.
  - Permitted: Loopback (`127.0.0.1/8`, `::1`) and explicitly approved repository mirrors (e.g., Maven Central, npmjs, PyPI) when configured.
  - Concurrently, `netmon` periodically reads `/proc/net/{tcp,tcp6,udp,udp6}`, translates hex-encoded IP addresses, and correlates open sockets with active container PIDs. Any socket opened to unauthorized destinations is flagged.

### 2.4 Statistical Anomaly Detection Engine (`anomaly`)
- **Location**: `core/pipejack/internal/anomaly/`
- **Mechanism**: Rolling 20-build window statistical z-score evaluation.
- **Functionality**:
  Tracks four continuous telemetry vectors across historical builds:
  1. `process_count`: Total distinct processes executed during build.
  2. `file_change_count`: Aggregate filesystem modifications.
  3. `network_count`: Total outbound socket connections observed.
  4. `duration_ms`: Total execution duration in milliseconds.
- **Advisory Baseline Mode**:
  Computes the mean (\(\mu\)) and standard deviation (\(\sigma\)) for each metric over a rolling window of recent builds. Telemetry points exceeding \(|z| > 3.0\) are flagged. In production CI mode, the anomaly engine operates in *advisory mode* to prevent false rejections during developer warmup cycles, while logging rich forensic audit data.

---

## 3. Policy Decision Point (PDP) & Enforcement Pipeline

- **Location**: `core/pipejack/internal/pdp/`
- **Policy Schema**: Declarative YAML specifying build invariants per stack.

```yaml
version: "1.0"
name: "banking-api-policy"
workload: "java"
enforcement:
  allowed_processes:
    - "/usr/bin/mvn"
    - "/opt/java/openjdk/bin/java"
    - "/bin/dash"
  forbidden_processes:
    - "/usr/bin/curl"
    - "/usr/bin/wget"
    - "/bin/nc"
  filesystem:
    allowed_mutation_patterns:
      - "target/**"
    prohibited_mutation_patterns:
      - "src/**"
      - "pom.xml"
  network:
    allow_outbound: false
```

### Decision Pipeline Flow:
1. **ALLOW Path**:
   - Zero unauthorized process executions.
   - Filesystem mutations confined strictly to allowed compiler output patterns.
   - Zero unauthorized network egress attempts.
   - CI Orchestrator builds production image, pushes to local registry (`localhost:5000/<app>:<tag>`), launches running container, and returns HTTP 200.
2. **BLOCK Path**:
   - One or more policy violations detected.
   - CI Orchestrator immediately tags container artifact as quarantine (`localhost:5000/<app>:<tag>-quarantine`).
   - Deployment is aborted. No running container is started.
   - CI Orchestrator returns HTTP 403 Forbidden with complete forensic breakdown.

---

## 4. Cryptographic Attestation Ledger

![Attestation Chain](../assets/attestation-chain.svg)

- **Location**: `services/custom-ci/attest.go`, `services/custom-ci/verify-attest.go`
- **Storage**: `/home/ubuntu/pipejack-attestations/*.json`

Every build executed by PipeJack generates an immutable, digitally signed attestation record:
1. **Canonical Build Serialization**: Build metadata, timestamp, git context, sensor violations, and PDP verdict are serialized into deterministic JSON.
2. **Self Hash**: A SHA-256 digest is computed over the canonical record (`self_hash`).
3. **Chain Link**: The previous build's `self_hash` is recorded as `prev_hash`, creating an unbroken cryptographic link.
4. **Digital Signature**: The record is signed with a host-protected Ed25519 private key.
5. **Chain Verification**: The companion utility `verify-attest.go` verifies the entire ledger from genesis to head:
   - Validates Ed25519 signatures using the public key.
   - Recomputes `self_hash` to prove zero tampering.
   - Verifies `prev_hash` continuity across every consecutive build.

---

## 5. Security Invariants Summary

| Invariant | Subsystem | Failure Outcome |
| :--- | :--- | :--- |
| **No Rogue Executables** | `proctree` | Immediate PDP BLOCK, quarantine tag, deployment halted. |
| **Source Immutability** | `fschecker` | Immediate PDP BLOCK, quarantine tag, deployment halted. |
| **Network Isolation** | `egressfw` + `netmon` | Dropped packet + socket violation -> PDP BLOCK. |
| **Immutability of Provenance** | `attest` | Tampering invalidates Ed25519 signature & chain hash. |
| **Builder Image Integrity** | Docker Digest Pinning | Prevents upstream tag-mutation and supply chain poisoning. |
