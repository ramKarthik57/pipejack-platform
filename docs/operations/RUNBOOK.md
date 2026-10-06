# PipeJack Operations & Maintenance Runbook

## 1. System Services Overview

On the security enforcement node (VM-2), PipeJack runs as a managed systemd service alongside Docker engine and the local image registry:

| Component | Management Command | Port / Target | Log Destination |
| :--- | :--- | :--- | :--- |
| **CI Orchestrator** | `sudo systemctl status pipejack-ci.service` | `:8888` | `journalctl -u pipejack-ci -f` |
| **Local Docker Registry** | `docker ps -f name=registry` | `:5000` | `docker logs registry` |
| **Demo Console** | `systemctl status pipejack-demo.service` or direct | `:8090` | `/tmp/pipejack_demo_access.log` |

---

## 2. Common Operational Tasks

### Restarting the CI Service
```bash
sudo systemctl restart pipejack-ci.service
sudo systemctl status pipejack-ci.service --no-pager
```

### Inspecting Live Build Telemetry
To monitor build container creation and real-time sensor evaluations:
```bash
journalctl -u pipejack-ci.service -f -n 100
```

### Checking Registry Images & Quarantine Tags
```bash
# Query list of repository images
curl -s http://localhost:5000/v2/_catalog | jq .

# Query tags for a specific image
curl -s http://localhost:5000/v2/vuln-app/tags/list | jq .
```
Quarantined builds will display with `-quarantine` suffixes (e.g., `test-build-1-quarantine`).

### Auditing Attestation Records
Attestation files are stored permanently in `/home/ubuntu/pipejack-attestations/`:
```bash
ls -lt /home/ubuntu/pipejack-attestations/ | head -20
```
To verify cryptographic ledger integrity:
```bash
cd /home/ubuntu/pipejack-dev/services/custom-ci
go run verify-attest.go
```

---

## 3. Troubleshooting & Diagnostics

### Symptom: `Failed to locate container cgroup scope`
- **Cause**: Docker container finished execution before `proctree` attached, or cgroup v2 path changed.
- **Remedy**: Ensure cgroup v2 is enabled via `stat -fc %T /sys/fs/cgroup/` (must return `cgroup2fs`). The daemon automatically searches `/sys/fs/cgroup/system.slice/docker-<id>.scope`.

### Symptom: `iptables: No chain/target/match by that name`
- **Cause**: Kernel missing `xt_multiport` or iptables module not loaded.
- **Remedy**: Ensure `iptables` package is installed on the host and kernel module `iptable_filter` is loaded (`sudo modprobe iptable_filter`).

### Symptom: `Signature verification failed`
- **Cause**: Attestation file tampered with or public key does not match signing key.
- **Remedy**: The public/private keypair resides in `/home/ubuntu/pipejack-dev/services/custom-ci/` (`ed25519.pub`, `ed25519.key`). Do not delete or overwrite the private key during production operation.
