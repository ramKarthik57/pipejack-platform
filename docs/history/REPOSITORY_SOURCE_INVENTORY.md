# Repository Source Inventory Manifest

This document records the original source locations, owners, purpose, and destination paths for all consolidated project materials.

| Source Area | Original VM | Original Path | Purpose / Role | Component Owner | Target Path in Unified Repo | Decision |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Core Security Engine** | VM-2 | `/home/ubuntu/pipejack-dev/pipejack` | Process tree, Merkle fs, netmon, egressfw, anomaly, PDP | VM-2 (Security Lead) | `core/pipejack/` | **INCLUDE** |
| **Vendored eBPF Library**| VM-2 | `/home/ubuntu/pipejack-dev/cilium-ebpf` | eBPF kernel bytecode loader & ring buffer | VM-2 (Security Lead) | `core/cilium-ebpf/` | **INCLUDE** |
| **Vendored Syscalls** | VM-2 | `/home/ubuntu/pipejack-dev/golang-sys` | Low-level Linux system call bindings | VM-2 (Security Lead) | `core/golang-sys/` | **INCLUDE** |
| **CI Orchestrator** | VM-2 | `/home/ubuntu/custom-ci` | CI daemon, cgroup discovery, container builds | VM-2 (Security Lead) | `services/custom-ci/` | **INCLUDE** |
| **Banking Application** | VM-1 | `/home/ubuntu/banking-api` | Java 17 Spring Boot microservice & tests | VM-1 (Developer Lead) | `applications/banking-api/` | **INCLUDE** |
| **Calculator Application**| VM-1 | `/home/ubuntu/spring-calc` | Safe AST arithmetic & financial evaluator | VM-1 (Developer Lead) | `applications/calculator-api/` | **INCLUDE** |
| **Node.js Payment App** | VM-1 | `/home/ubuntu/nodejs-app` | Node.js 18 Express payment authorization service | VM-1 (Developer Lead) | `applications/nodejs-app/` | **INCLUDE** |
| **Python Analytics App** | VM-1 | `/home/ubuntu/python-app` | Python 3.12 real-time fraud risk studio | VM-1 (Developer Lead) | `applications/python-app/` | **INCLUDE** |
| **Malicious Node.js** | VM-1 | `/home/ubuntu/nodejs-malicious` | Supply chain postinstall hook exfiltration fixture | VM-1 (QA / Attack Lead) | `security-fixtures/nodejs-malicious/` | **INCLUDE** |
| **Malicious Python** | VM-1 | `/home/ubuntu/python-malicious` | Malicious setup.py socket exfiltration fixture | VM-1 (QA / Attack Lead) | `security-fixtures/python-malicious/` | **INCLUDE** |
| **Vulnerable Testbed** | VM-1 | `/home/ubuntu/vuln-app` | General vulnerable application baseline | VM-1 (QA / Attack Lead) | `security-fixtures/vuln-app/` | **INCLUDE** |
| **Attack Scenarios 01-07**| VM-1 | `/home/ubuntu/attacks/` | 7 automated adversarial attack suites | VM-1 (QA / Attack Lead) | `attacks/` | **INCLUDE** |
| **Demo Console** | VM-2 | `/home/ubuntu/pipejack-demo-console` | Central presentation console & interactive UI | VM-2 (Integration Lead) | `demo/demo-console/` | **INCLUDE** |
| **Docker Configurations**| VM-2 | `/home/ubuntu/custom-ci/Dockerfile.*` | Pinned immutable builder & runtime Dockerfiles | VM-2 (Security Lead) | `deployment/docker/` | **INCLUDE** |
| **Systemd Service** | VM-2 | `/etc/systemd/system/pipejack-ci.service` | Production Linux systemd service unit | VM-2 (Security Lead) | `deployment/systemd/` | **INCLUDE** |
| **Zero-Trust Policies** | VM-2 | `/home/ubuntu/custom-ci/policy-*.yaml` | Process, Merkle fs, and network egress rules | VM-2 (Security Lead) | `deployment/policies/` | **INCLUDE** |
| **Client Upload Tool** | VM-1 | `/home/ubuntu/pipejack-upload.sh` | Client-side packaging and build streaming script | VM-1 (Developer Lead) | `scripts/pipejack-upload.sh` | **INCLUDE** |
| **Project Documentation** | VM-2 | `/home/ubuntu/pipejack-dev/docs/` | Architecture, engineering audit, regression reports | Joint VM-1 & VM-2 | `docs/` | **INCLUDE** |
