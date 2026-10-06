# PipeJack Quick Start & Reproduction Guide

This guide enables evaluators and developers to run PipeJack and verify its zero-trust build security capabilities in minutes.

---

## 1. Prerequisites

- **Operating System**: Linux (Ubuntu 22.04 LTS or 24.04 LTS recommended, x86_64)
- **Linux Control Groups**: cgroup v2 enabled (default on modern Linux)
- **Docker Engine**: Docker 24.0+ (Docker 28+ tested)
- **Go**: Go 1.22+ (Go 1.23.2 tested)
- **Utilities**: `iptables`, `curl`, `tar`, `python3`

---

## 2. Fast Single-Machine Setup

You can run PipeJack locally on a single workstation without requiring multiple virtual machines:

### Step 1: Clone the Repository
```bash
git clone https://github.com/ramKarthik57/pipejack-platform.git
cd pipejack-platform
```

### Step 2: Build the Core Binaries
```bash
# Build the security daemon & CLI
cd core/pipejack
go build -o ../../bin/pipejackd ./cmd/pipejackd
go build -o ../../bin/proctree ./cmd/proctree
cd ../..

# Build the CI service
cd services/custom-ci
go build -o ../../bin/pipejack-ci .
cd ../..
```

### Step 3: Run Unit Tests
```bash
# Core engine tests
(cd core/pipejack && go test -v -count=1 ./...)

# CI Orchestrator tests
(cd services/custom-ci && go test -v -count=1 ./...)
```

### Step 4: Verify Attestation Ledger Integrity
```bash
cd services/custom-ci
go run verify-attest.go
```

---

## 3. Two-VM Distributed Topology Setup

In production and formal demonstrations, PipeJack operates across two virtual machines:

```
[ VM-1: 192.168.88.132 ]  ──(HTTP :8888)──>  [ VM-2: 192.168.88.133 ]
Client Apps & Attacks                          CI & Security Engine
```

### On VM-2 (Server / Security Node):
1. **Start Docker Registry**:
   ```bash
   docker run -d -p 5000:5000 --restart=always --name registry registry:2
   ```
2. **Start the CI Orchestrator**:
   ```bash
   sudo systemctl restart pipejack-ci.service
   # Or run directly:
   cd services/custom-ci && sudo ./pipejack-ci
   ```
3. **Start the Interactive Demo Console (Optional)**:
   ```bash
   cd demo/demo-console && python3 server.py --port 8090
   ```
   Open `http://192.168.88.133:8090` in your browser.

### On VM-1 (Client / Developer Node):
1. **Submit a Clean Java Build**:
   ```bash
   CI_ENDPOINT="http://192.168.88.133:8888" ./scripts/pipejack-upload.sh clean-java.tar.gz
   ```
   *Expected Output*: `HTTP 200 OK` — Build verified clean, image pushed to registry, microservice deployed.

2. **Submit a Malicious Payload (HTTP Exfiltration)**:
   ```bash
   CI_ENDPOINT="http://192.168.88.133:8888" ./scripts/pipejack-upload.sh malicious-java.tar.gz
   ```
   *Expected Output*: `HTTP 403 Forbidden` — Unauthorized curl execution blocked, image tagged `<tag>-quarantine`, deployment prevented.

3. **Execute Master Attack Suite**:
   ```bash
   cd attacks
   ./run-all.sh
   ```

---

## 4. Verification Checkpoints

After running builds, verify system state on VM-2:

```bash
# Check running containers (only ALLOW builds will be running)
docker ps

# Check local registry quarantine tags
curl -s http://localhost:5000/v2/_catalog

# Audit cryptographic attestation records
cd services/custom-ci && go run verify-attest.go
```
