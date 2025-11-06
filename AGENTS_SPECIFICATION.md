AGENTS_SPECIFICATION.md

Project Name: CrackedVPN

Overview

CrackedVPN is a zero-cost, privacy-focused VPN system based on WireGuard that routes all traffic through the Tor network. It is designed for power users, privacy advocates, and developers who want maximum anonymity, cryptographic security, and geographic exit-node flexibility.

The system is entirely shell-based (CLI) and compatible with both macOS and Linux. It uses free-tier virtual private servers (e.g., Google Cloud Platform) as exit nodes, with one server deployed per country. Users can switch countries with a simple shell command. The client configuration is always generated and used locally — no persistent client records are stored in the repository.

This document describes the architecture, design decisions, and operational flow of the project in detail.

⸻

Architecture Summary

[User Device]
|
| (WireGuard tunnel)
|
[Virtual Private Server (Exit Node)]
|
| (All traffic routes through Tor)
|
[Internet]

⸻

Why This Stack Was Chosen

1. WireGuard as the VPN Protocol
   • Reasons:
   • Modern cryptography (Curve25519, ChaCha20)
   • Minimal codebase and attack surface
   • Extremely fast and reliable
   • Native kernel support in Linux

2. Tor Integration
   • Reasons:
   • Anonymizes all outgoing traffic beyond VPN
   • Protects against server compromise (second hop)
   • Makes endpoint correlation significantly harder
   • Enables VPN-over-Tor routing for maximum privacy

3. Google Cloud Platform (Free Tier VPS)
   • Reasons:
   • Reliable infrastructure
   • Generous free tier (1 e2-micro instance/month)
   • Easy firewall and SSH management
   • API access for future automation

4. Shell Script Control Interface
   • Reasons:
   • Lightweight and portable
   • Universally available on macOS and Linux
   • No GUI dependencies
   • Easy to automate and debug

⸻

Expected Workflow (When Done) 1. User clones the CrackedVPN repo locally 2. User runs cracked_vpn setcountry <country> to set the target country (loads local WireGuard client config that corresponds to the server) 3. User runs cracked_vpn start to begin the WireGuard tunnel from client side 4. All traffic is tunneled:
• Through the WireGuard interface
• Through the remote VPS
• Through Tor
• To the final destination on the internet 5. User can run cracked_vpn status to confirm their current IP, country, and tunnel state 6. User can run cracked_vpn end to close the tunnel

⸻

Security Features
• No logs stored on server (journald and UFW logging disabled)
• Only UDP port 51820 open
• DNS leak prevention (all traffic routed through VPN + Tor)
• IP leak prevention via strict AllowedIPs setting
• SSH login restricted to key-based auth only
• Root login disabled
• No client keys or data stored in the repo

⸻

Directory Structure (Simplified for Local Client Focus)

CrackedVPN/
├── scripts/ # Shell scripts (start, stop, deploy, etc.)
│ ├── start.sh
│ ├── end.sh
│ ├── setcountry.sh
│ ├── deploy_country.sh
│ ├── status.sh
│ └── tor_wrapper.sh
│
├── templates/ # Server WireGuard configs (NOT stored with sensitive data)
│ ├── wg0_us.conf
│ ├── wg0_de.conf
│ └── ...
│
├── tor/ # Tor configurations and wrapper
│ ├── torrc
│ └── torsocks_wrapper.sh
│
├── docs/ # Markdown docs
│ ├── README.md
│ ├── INSTALL.md
│ ├── PRIVACY_MODEL.md
│ └── SECURITY_CHECKLIST.md

⚠️ Client configuration is handled at runtime and exists only locally. No client .conf files are stored or versioned.

⸻

Exit Node Countries (Initial List)
• United States (us)
• Germany (de)
• Brazil (br)
• Singapore (sg)
• United Kingdom (uk)
• Japan (jp)
• Canada (ca)
• South Africa (za)
• Australia (au)
• France (fr)

Each has a pre-configured wg0\_<cc>.conf file in /templates/, used for server-side deployment.

⸻

Dependencies (Local)
• WireGuard tools (wg, wg-quick)
• torsocks
• bash (>= 4)

⸻

Dependencies (VPS)
• OS: Ubuntu 22.04 LTS (or Debian 11+)
• Installed:
• wireguard
• tor
• ufw
• iptables (or nftables)
• Configured:
• Enable IP forwarding
• Open UDP 51820
• SSH key-based login only

⸻

Long-Term Goals
• GUI client for macOS/Linux
• QR-code config import (for mobile WireGuard clients)
• Automated VPS rotation (monthly exit node refresh)
• Web dashboard (self-hosted) for non-technical users
• Multi-hop (VPN → VPN → Tor)

⸻

This file should be treated as the technical masterplan for CrackedVPN. It defines the why, what, and how — to ensure consistency and extensibility as the project grows.
