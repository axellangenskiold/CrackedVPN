AGENTS.md

CrackedVPN – Agents and Responsibilities (Local-Only Architecture)

This document defines the agents (components) within CrackedVPN’s local-first privacy model. Each agent is self-contained, script-driven, and does not rely on external infrastructure. There is no client data stored and no long-term state — all configuration and keys are generated at runtime.

⸻

🧑‍💻 Agent: Local User Machine (macOS/Linux)

Description:

Your local system acts as both the client and controller. No external server is required by default.

Responsibilities:
• Runs all CrackedVPN scripts
• Generates WireGuard keys in memory at runtime
• Connects to exit node (local or VPS)
• Routes traffic through WireGuard → Tor → Internet

Required Tools:
• bash
• wg, wg-quick
• torsocks
• curl (for IP/status checks)

Scripts:

scripts/start.sh # Starts local WireGuard tunnel
scripts/end.sh # Tears down tunnel and removes keys
scripts/setcountry.sh # Sets the target exit node (default: local)
scripts/status.sh # Shows current tunnel + Tor + IP status
scripts/tor_wrapper.sh # Optional: wraps arbitrary commands in Tor

⸻

🌍 Agent: Exit Node (Remote or Local)

Description:

A WireGuard + Tor-enabled server under your control. Can be a:
• Remote VPS (GCP, Fly.io, etc.) for country-specific exits
• Local machine (default), using your ISP IP and Tor

Responsibilities:
• Accept inbound WireGuard connections
• Forward traffic through Tor
• Expose only UDP port 51820

Notes:
• You provision the VPS
• Use deploy_country.sh script if you want to automate setup (not required)
• Always access remote VPS via torsocks ssh if privacy is critical

⸻

📄 Agent: WireGuard Config Templates

Description:

Minimal country-based templates stored in /templates/. These contain server-side stubs only. No client info or keys are present.

Used By:
• setcountry.sh to load config stub
• start.sh to generate full WireGuard config at runtime

Sample Template: templates/wg0_us.conf

[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>

# Client section generated dynamically in start.sh

⸻

🧬 Agent: Runtime Key Generator

Description:

Generates a WireGuard client key pair in memory every time start.sh runs. Nothing is stored. Keys are removed on stop.

Responsibilities:
• wg genkey → private key
• wg pubkey → public key
• Inject client key into wg0.conf on-the-fly
• Secure memory-only operation

⸻

🧅 Agent: Tor Integration (Always-On)

Description:

Tor is enabled by default and wraps all internet-bound traffic from the exit node.

Responsibilities:
• Ensures anonymity of outgoing traffic
• Masks your IP even if the VPS is compromised
• Supports SOCKS proxy (127.0.0.1:9050)
• Wraps outgoing tools (like curl) with torsocks

Scripts:

scripts/tor_wrapper.sh # Wraps apps in Tor routing

⸻

🧪 Agent: Status Monitor

Description:

Real-time view of VPN + Tor state. Verifies that WireGuard is active, IP has changed, and Tor is reachable.

Output:
• WireGuard tunnel status
• External IP address
• Country of IP (optional)
• Tor circuit confirmation

⸻

🧰 Agent: Developer Tools and Documentation

Description:

No user data is stored in the repo. All developer-facing utilities and docs are safe to clone and share.

Files:

docs/README.md
INSTALL.md
PRIVACY_MODEL.md
SECURITY_CHECKLIST.md

Optional Extensions:
• deploy_country.sh: Automates VPS provisioning (optional)
• wipe.sh: Script to destroy exit node after use

⸻

🚫 Deprecated Agents
• clients/ directory: Removed. No client configs are stored.
• configgen.sh: Removed. All configs are ephemeral and generated in start.sh.

⸻

🔄 Exit Modes Supported

cracked_vpn setcountry local # Use current IP + Tor (default)
cracked_vpn setcountry us # Use remote VPS in US (if manually deployed)

CrackedVPN is a runtime-only, shell-native, privacy-hardened system that assumes no storage, no trust, and no persistence by default.
