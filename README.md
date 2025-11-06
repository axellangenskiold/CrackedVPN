CrackedVPN
==========

CrackedVPN is a local-first WireGuard + Tor launcher. It generates client keys at runtime, uses country-specific server templates, and never stores long-term secrets. Once a session is up it persists independently of the terminal session, and only `cracked end` tears it down.

Features
--------
- One CLI: run `cracked start`, `cracked end`, `cracked setcountry <key>`, `cracked status`, `cracked help`.
- Ephemeral configs: client keypair and WireGuard config are generated on every start.
- Local templates: server stubs live under `templates/` (no client data committed).
- Tor-by-default: tunnels route through Tor for exit anonymity.
- Status monitoring: check interface state, direct IP, and Tor IP anytime.

Quick Start
-----------
1. Follow the steps in `INSTALL.md`.
2. Select a template: `cracked setcountry local`.
3. Launch: `cracked start`.
4. Verify: `cracked status`.
5. Stop: `cracked end`.

Security Posture
----------------
See `PRIVACY_MODEL.md` and `SECURITY_CHECKLIST.md` (to be filled in) for detailed assumptions and hardening guidance.
