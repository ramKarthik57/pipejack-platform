# PipeJack Policy Specification Guide

## 1. Overview

PipeJack policies are declarative YAML definitions that specify the exact execution, filesystem, and network constraints permitted for a specific application or build stack. Policies are evaluated by the Policy Decision Point (PDP) located in `core/pipejack/internal/pdp/`.

Policies reside in the `deployment/policies/` directory.

---

## 2. Policy Schema Reference

A complete PipeJack policy contains three main sections:

```yaml
version: "1.0"
name: "banking-api-policy"
workload: "java"

enforcement:
  allowed_processes:
    - "/usr/bin/mvn"
    - "/opt/java/openjdk/bin/java"
    - "/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
    - "/bin/dash"
    - "/bin/bash"

  forbidden_processes:
    - "/usr/bin/curl"
    - "/usr/bin/wget"
    - "/bin/nc"
    - "/usr/bin/python3"
    - "/usr/bin/perl"

  filesystem:
    allowed_mutation_patterns:
      - "target/**"
      - ".m2/**"
    prohibited_mutation_patterns:
      - "src/**"
      - "pom.xml"

  network:
    allow_outbound: false
    allowed_destinations:
      - "127.0.0.1"
      - "::1"

# Anomaly Configuration
anomaly_enabled: true          # enable statistical telemetry evaluation (default: true)
anomaly_threshold: 3.0         # z-score deviation cutoff |z| > 3.0 (default: 3.0)
anomaly_min_baseline: 5        # min builds needed before evaluating anomalies (default: 5)
anomaly_block: false           # false = advisory audit only; true = hard quarantine (default: false)
```

### Fields:
- **`version`**: Policy format version (currently `"1.0"`).
- **`name`**: Unique identifier for this policy.
- **`workload`**: Target ecosystem (`"java"`, `"nodejs"`, `"python"`, `"spring"`).
- **`enforcement.allowed_processes`**: List of exact binary paths or glob patterns permitted to run within the container cgroup.
- **`enforcement.forbidden_processes`**: Explicit blacklist of high-risk binaries. If encountered, immediately triggers violation even if wildcard allows.
- **`enforcement.filesystem.allowed_mutation_patterns`**: Glob expressions for directories where build artifacts (binaries, `.class`, `.jar`, `.whl`) are created.
- **`enforcement.filesystem.prohibited_mutation_patterns`**: Glob expressions where mutations are strictly prohibited (source files, manifests).
- **`enforcement.network.allow_outbound`**: Boolean (`true`/`false`) indicating whether external internet connections are permitted.
- **`enforcement.network.allowed_destinations`**: IP addresses or CIDR blocks permitted for network egress.
- **`anomaly_enabled`**: Boolean enabling statistical baseline z-score evaluation.
- **`anomaly_threshold`**: Float cutoff for outlier z-score detection (standard default: `3.0`).
- **`anomaly_min_baseline`**: Integer minimum historical builds required before anomaly evaluation activates.
- **`anomaly_block`**: Boolean determining enforcement mode (`false` = advisory audit signed in attestation; `true` = hard BLOCK and quarantine).

---

## 3. Shipped Production Policies

The repository includes pre-tuned, hardened production policies in `deployment/policies/`:

| Policy File | Target Application | Stack | Allowed Outputs | Network Policy |
| :--- | :--- | :--- | :--- | :--- |
| `policy-banking.yaml` | Java Banking API | Java 17 / Maven | `target/**` | Localhost only |
| `policy-spring.yaml` | Spring Calculator API | Java 17 / Maven | `target/**` | Localhost only |
| `policy-node.yaml` | Node.js Payment Service | Node.js 18 / npm | `dist/**`, `node_modules/**` | Localhost only |
| `policy-python.yaml` | Python Analytics Engine | Python 3.12 / pip | `build/**`, `dist/**`, `*.egg-info` | Localhost only |

---

## 4. Policy Matching Logic & Precedence

1. **Forbidden Process Check**:
   If an observed process matches any entry in `forbidden_processes`, a critical violation is issued immediately.
2. **Allowed Process Check**:
   If `allowed_processes` is specified, every observed process must match at least one allowed entry. If not matched, an unauthorized process violation is issued.
3. **Filesystem Pattern Evaluation**:
   Every added, modified, or deleted file is evaluated against `prohibited_mutation_patterns`. If matched, a filesystem tampering violation is emitted. Next, each modified file must match an entry in `allowed_mutation_patterns`; any unapproved mutation outside build output targets is flagged.
4. **Network Evaluation**:
   If `allow_outbound` is `false`, any outbound socket connecting outside loopback produces a network egress violation.
