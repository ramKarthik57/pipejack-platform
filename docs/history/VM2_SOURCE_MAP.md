# VM-2 Source Map

This document maps all assets originating from **VM-2 (192.168.88.133)** to their canonical destinations in the unified PipeJack GitHub repository.

| Original VM-2 Path | Unified Repository Path | Role / Purpose | Classification |
| :--- | :--- | :--- | :--- |
| `/home/ubuntu/pipejack-dev/pipejack/` | `core/pipejack/` | Core Security Engine (Daemon, Sensors, PDP) | SOURCE |
| `/home/ubuntu/pipejack-dev/cilium-ebpf/` | `core/cilium-ebpf/` | Vendored eBPF library for tracepoint interception | SOURCE |
| `/home/ubuntu/pipejack-dev/golang-sys/` | `core/golang-sys/` | Vendored system call bindings | SOURCE |
| `/home/ubuntu/custom-ci/main.go` | `services/custom-ci/main.go` | CI HTTP Orchestrator, Cgroup Discovery | SERVICE |
| `/home/ubuntu/custom-ci/attest.go` | `services/custom-ci/attest.go` | Ed25519 digital attestation signing | SERVICE |
| `/home/ubuntu/custom-ci/verify-attest.go` | `services/custom-ci/verify-attest.go` | Attestation ledger chain verification utility | SERVICE |
| `/home/ubuntu/custom-ci/quarantine_test.go` | `services/custom-ci/quarantine_test.go` | Regression test suite for quarantine paths | TEST |
| `/home/ubuntu/custom-ci/Dockerfile.*` | `deployment/docker/` | Pinned immutable builder & runtime Dockerfiles | DEPLOYMENT DEFINITION |
| `/etc/systemd/system/pipejack-ci.service` | `deployment/systemd/pipejack-ci.service`| Linux systemd service unit definition | DEPLOYMENT DEFINITION |
| `/etc/pipejack/ci.env` | `deployment/systemd/ci.env` | Production daemon environment configuration | CONFIGURATION |
| `/home/ubuntu/custom-ci/policy-*.yaml` | `deployment/policies/` | Strict zero-trust security policy specifications | CONFIGURATION |
| `/home/ubuntu/pipejack-demo-console/` | `demo/demo-console/` | Web presentation console, generative UI, tests | DEMO / PRESENTATION |
| `/home/ubuntu/pipejack-dev/docs/` | `docs/` | Authoritative architecture, audits, and runbooks | DOCUMENTATION |
