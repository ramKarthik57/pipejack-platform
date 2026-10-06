# Repository Layout & Architecture

The PipeJack repository is structured into clear, decoupled functional domains:

- **`core/`**: Houses the PipeJack core security daemon (`pipejackd`), the multi-sensor detection engines (`proctree`, `fschecker`, `netmon`, `egressfw`, `anomaly`), the Policy Decision Point (`pdp`), and supporting vendored eBPF libraries.
- **`services/`**: Contains the CI orchestration server (`custom-ci`), handling HTTP requests, Docker container isolation, cgroup v2 discovery, and cryptographic Ed25519 attestation generation.
- **`applications/`**: Contains the reference client microservices developed on VM-1 (Java Banking API, Safe AST Calculator, Node.js Payment Service, Python Analytics Engine).
- **`security-fixtures/`**: Contains reproducible adversarial package fixtures simulating real-world supply chain attack vectors (`postinstall` hooks, `setup.py` trojans, and vulnerable dependencies).
- **`attacks/`**: Contains the 7 standalone attack scenarios (01 through 07) used for automated adversarial regression testing.
- **`demo/`**: Contains the Demonstration Console (`server.py` and generative UI frontend) providing real-time visibility into CI builds, security sensor telemetry, and attestation ledgers.
- **`deployment/`**: Contains all infrastructure-as-code assets including pinned Dockerfiles, systemd service units, runtime environment templates, and zero-trust security policies.
- **`scripts/`**: Contains operational helper scripts, including the multi-image build upload tool (`pipejack-upload.sh`).
- **`docs/`**: Complete engineering reports, adversarial regression audits, multi-VM synchronization baselines, and operational runbooks.
