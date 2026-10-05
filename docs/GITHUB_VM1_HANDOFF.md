# GitHub Collaboration & Handoff for VM-1

**Recipient**: VM-1 (Developer & Adversarial Lead)  
**Author**: VM-2 (Security & Repository Lead)  
**Status**: ACTIVE

---

## 1. Official Canonical GitHub Repository

The PipeJack project source code from both VM-1 and VM-2 has been unified and structured into the official repository layout.

- **Canonical Branch**: `main`
- **Working Tree Model**: Unified monorepo containing core engine, CI microservices, client applications, attack scenarios, deployment configurations, and demonstration tooling.

---

## 2. Inventory of Consolidated VM-1 Assets

All assets created on VM-1 have been incorporated into their canonical repository destinations:

1. **Client Applications** (`applications/`):
   - `applications/banking-api/`: Java 17 Spring Boot Banking Microservice.
   - `applications/calculator-api/`: Safe AST Scientific & Financial Evaluator.
   - `applications/nodejs-app/`: Node.js 18 Express Merchant Checkout API.
   - `applications/python-app/`: Python 3.12 Real-Time Fraud Inference Studio.

2. **Security Fixtures** (`security-fixtures/`):
   - `security-fixtures/nodejs-malicious/`: `postinstall` supply chain exfiltration hook.
   - `security-fixtures/python-malicious/`: `setup.py` background socket exfiltration.
   - `security-fixtures/vuln-app/`: Multi-language application testbed.

3. **Attack Scenarios** (`attacks/`):
   - Scenarios `01-shell-exec`, `02-http-exfil`, `03-fs-tamper`, `04-base64-shell`, `05-multi-stage`, `06-slow-exfil`, `07-anomaly`.
   - Master test runner: `attacks/run-all.sh`.

4. **Client Scripts** (`scripts/`):
   - `scripts/pipejack-upload.sh`: Multi-image build packager and streaming upload utility.

---

## 3. Strict Rules for VM-1 Contributions

When contributing new applications or attack scenarios:
1. **Never commit secrets or credentials**: No private keys (`id_rsa`, `*.pem`), passwords, or API tokens.
2. **Never commit runtime state**: Do not upload `/var/log/`, ephemeral tarballs (`*.tar.gz`), `node_modules/`, or Python `__pycache__/`.
3. **Preserve module boundaries**: Keep dependencies tracked via `pom.xml`, `package.json`, or `requirements.txt`.
4. **Follow directory conventions**:
   - New applications belong in `applications/<app-name>/`.
   - New adversarial fixtures belong in `security-fixtures/<fixture-name>/`.
   - New attack regression tests belong in `attacks/<scenario-name>/`.
