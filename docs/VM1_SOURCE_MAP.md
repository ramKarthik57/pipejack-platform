# VM-1 Source Map

This document maps all assets originating from **VM-1 (192.168.88.132)** to their canonical destinations in the unified PipeJack GitHub repository.

| Original VM-1 Path | Unified Repository Path | Role / Purpose | Classification |
| :--- | :--- | :--- | :--- |
| `/home/ubuntu/banking-api/` | `applications/banking-api/` | Java 17 Banking API & Account Services | APPLICATION |
| `/home/ubuntu/spring-calc/` | `applications/calculator-api/` | Scientific & Financial Expression Evaluator | APPLICATION |
| `/home/ubuntu/nodejs-app/` | `applications/nodejs-app/` | Node.js 18 Express Checkout & Payment API | APPLICATION |
| `/home/ubuntu/python-app/` | `applications/python-app/` | Python 3.12 Fraud Risk Inference Studio | APPLICATION |
| `/home/ubuntu/nodejs-malicious/` | `security-fixtures/nodejs-malicious/` | npm postinstall socket exfiltration attack | FIXTURE |
| `/home/ubuntu/python-malicious/` | `security-fixtures/python-malicious/` | setup.py background socket exfiltration attack | FIXTURE |
| `/home/ubuntu/vuln-app/` | `security-fixtures/vuln-app/` | Multi-language testbed application | FIXTURE |
| `/home/ubuntu/attacks/01-shell-exec/` | `attacks/01-shell-exec/` | Scenario 01: Unauthorized /bin/sh binary execution | ATTACK SCENARIO |
| `/home/ubuntu/attacks/02-http-exfil/` | `attacks/02-http-exfil/` | Scenario 02: Outbound HTTP exfiltration via curl | ATTACK SCENARIO |
| `/home/ubuntu/attacks/03-fs-tamper/` | `attacks/03-fs-tamper/` | Scenario 03: Source code tampering during compilation | ATTACK SCENARIO |
| `/home/ubuntu/attacks/04-base64-shell/` | `attacks/04-base64-shell/` | Scenario 04: Obfuscated Base64 shell invocation | ATTACK SCENARIO |
| `/home/ubuntu/attacks/05-multi-stage/` | `attacks/05-multi-stage/` | Scenario 05: Multi-stage staged compiler dropper | ATTACK SCENARIO |
| `/home/ubuntu/attacks/06-slow-exfil/` | `attacks/06-slow-exfil/` | Scenario 06: Low-frequency trickling exfiltration | ATTACK SCENARIO |
| `/home/ubuntu/attacks/07-anomaly/` | `attacks/07-anomaly/` | Scenario 07: Statistical process count anomaly | ATTACK SCENARIO |
| `/home/ubuntu/attacks/run-all.sh` | `attacks/run-all.sh` | Master adversarial test automation runner | BUILD SCRIPT |
| `/home/ubuntu/pipejack-upload.sh` | `scripts/pipejack-upload.sh` | Client multi-image upload utility | BUILD SCRIPT |
