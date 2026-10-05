# PipeJack Architecture Specification

## 1. Executive Summary
PipeJack is a multi-sensor, host-assisted zero-trust security architecture designed specifically for containerized CI/CD build environments. By enforcing invariants at the kernel, process, filesystem, and network layers, PipeJack prevents malicious payloads from executing unauthorized actions or contaminating production container registries.

## 2. Sensor Subsystems
1. **Process Tree Differ (`proctree`)**: Intercepts process creation events within the build cgroup using `/proc` scanning and eBPF tracepoints. Verifies executable hashes and binaries against strict policy allowlists.
2. **Filesystem Merkle Baseline (`fschecker`)**: Generates pre-build and post-build cryptographic Merkle trees across the workspace. Prohibits modifications to source files while allowing legitimate compiler outputs.
3. **Network Egress Firewall (`egressfw`) & Monitor (`netmon`)**: Establishes strict container network namespace isolation via iptables `PIPEJACK_EGRESS` rules and active socket-to-PID correlation.
4. **Statistical Anomaly Engine (`anomaly`)**: Continuously monitors execution telemetry (duration, process count, mutation volume, network calls) against rolling 20-build baselines using z-score statistical variance.
5. **Policy Decision Point (`pdp`)**: Evaluates multi-sensor telemetry against declarative YAML policies to issue authoritative `ALLOW` or `BLOCK` decisions.
6. **Cryptographic Attestation Chain (`attest`)**: Signs canonical build records with Ed25519 digital signatures and chains each record to the previous build hash.
