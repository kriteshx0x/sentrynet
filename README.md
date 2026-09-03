# SentryNet

A modular security testing framework built for authorized, ethical security assessment — personal lab VMs, CTFs, intentionally vulnerable applications, or systems with explicit written permission to test.

> **Scope statement:** SentryNet is intended exclusively for use in isolated, authorized lab environments. It is **not** intended for use against systems you do not own or do not have explicit permission to test. Several modules (network DoS/MITM simulation, credential brute-forcing, payload generation) are real, working offensive tools — they are gated behind explicit confirmation prompts, but that gate is a safeguard against *accidental* misuse, not a substitute for using this responsibly.

## Architecture

```
sentrynet/
├── sentrynet.sh          # Interactive controller — category → module menu
├── modules/
│   ├── common.sh          # Shared helpers sourced by every module
│   ├── web/                # Web application assessment (target prompted)
│   ├── network/             # Network-layer assessment (target prompted)
│   ├── win/                 # Windows lab attack chain (recon → brute → shell → post-ex)
│   ├── social/               # Social engineering awareness labs
│   └── iot/                   # IoT device assessment (target prompted)
└── logs/                  # Timestamped output from every module run (gitignored)
```

Every module is independently executable (`./modules/web/01_recon.sh`) **and** callable from the main menu (`./sentrynet.sh`). All web/network/iot/win-recon modules share a common pattern from `modules/common.sh`:

- **Target validation** — rejects malformed IPs/hostnames before anything runs
- **Explicit authorization confirmation** — a hard "type yes" gate before any active test
- **Dependency checking** — fails cleanly with an install hint instead of a raw shell error if a tool is missing
- **Standardized logging** — every run is timestamped and saved under `logs/`
- **Timeout wrapping** — long-running scans can't hang indefinitely

No hardcoded targets, no hardcoded credentials, no silent failures.

## Safety model

Every module is labeled by risk level, both in its own header comment and in this README:

| Label | Meaning |
|---|---|
| **SAFE / PASSIVE** | Read-only observation — no traffic sent that could affect the target's normal operation |
| **CONTROLLED / ACTIVE** | Sends real requests/probes to the target (scans, test payloads, login attempts) but is detection/evidence-focused, not destructive |
| **DISRUPTIVE / LAB ONLY** | Has a real, intended effect on the target or network (load generation, ARP spoofing, packet capture) — restricted to isolated lab segments, gated behind extra confirmation |

## Modules

**Web Application** (target prompted at runtime): reconnaissance, port scanning, vulnerability scanning, XSS detection, SQL injection detection, authentication testing, session security testing, API testing. Modeled loosely on OWASP WSTG and OWASP API Security categories. Findings are evidence/candidates for manual verification, not automated exploitation.

**Network** (target prompted): reconnaissance, port scanning, plus four lab-only modules (DoS load demo — capped duration/rate, ARP/MITM demo, ARP observation, DNS enumeration incl. zone-transfer check, eavesdropping capture with cleartext-protocol flagging).

**Windows** (`win/`): a linear lab attack chain against a Windows VM — reconnaissance → RDP brute-force → Metasploit reverse shell → Mimikatz credential-dumping guidance. Built and tested against an isolated VMware host-only lab network.

**Social Engineering**: phishing-awareness template generator (writes a local training template, does not send mail to real addresses), a defensive URL-deception analyzer, and a local-only watering-hole demo server.

**IoT** (target prompted): reconnaissance, port scanning (TCP+UDP), service enumeration (MQTT/RTSP/SNMP), and a small known-default-credential/TLS-availability check.

## Usage

```bash
git clone git@github.com:kriteshx0x/sentrynet.git
cd sentrynet
chmod +x sentrynet.sh modules/*.sh modules/*/*.sh
./sentrynet.sh
```

Or run any module standalone:
```bash
./modules/web/01_recon.sh
```

## Requirements

Core: `bash`, `nmap`, `curl`, `dig`. Module-specific (checked automatically, install hints shown if missing): `hydra`, `msfvenom`/`msfconsole`, `nikto`, `tcpdump`, `arpspoof` (dsniff), `arp-scan`, `hping3`, `whatweb`, `nuclei`, `sqlmap`, `snmpwalk`. Most are Kali Linux defaults.

## Roadmap

**Done:** directory structure and controller, all web/network/win/social/iot modules with target validation, authorization gating, dependency checks, and logging.

**Planned:** a Python layer for result parsing/normalization and orchestration, an automated "Full Web Assessment" pipeline chaining the web modules end-to-end, and general polish across error handling and documentation.

## Disclaimer

This tool is provided for educational and authorized security-testing purposes only. The author is not responsible for misuse or damage caused by this tool. Always obtain explicit written authorization before testing any system you do not own.
