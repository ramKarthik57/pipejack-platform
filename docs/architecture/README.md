# PipeJack Architecture Documentation

This directory contains the authoritative technical architecture specifications and design documentation for the PipeJack Zero-Trust CI/CD Security Platform.

- **[System Architecture Specification](PIPEJACK_ARCHITECTURE.md)**: Comprehensive deep dive into the multi-sensor detection engine, cgroup process differ, Merkle tree filesystem baselining, network egress containment, policy decision point (PDP), and Ed25519 cryptographic attestation ledger.
- **[System Topology Diagram](../assets/system-topology.svg)**: Two-VM physical and network integration topology.
- **[Build Security Lifecycle](../assets/multi-sensor-lifecycle.svg)**: Step-by-step invariant enforcement from ingestion to attestation.
- **[Attestation Ledger Chain](../assets/attestation-chain.svg)**: Merkle-linked Ed25519 provenance ledger structure.
