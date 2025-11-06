CrackedVPN Privacy Model
========================

Principles
----------
- **Local-first**: all control logic and key generation happen on the user’s machine.
- **Ephemeral state**: WireGuard keys and configs are generated in-memory and stored only in `.runtime/` for the life of a session.
- **Template-only repo**: checked-in files contain no client-identifying data; templates reference server-side stubs only.
- **Tor enforced**: exit traffic traverses Tor even when using your own VPS, reducing correlation risk.
- **Manual teardown**: tunnels stay up until `cracked end` runs, avoiding accidental leaks when a terminal closes.

Threat Assumptions
------------------
- The user controls both local machine and exit node.
- Exit node may be compromised post-deployment, so Tor is assumed to mitigate exit visibility.
- Local machine is trusted during session bootstrapping (no malware intercepting keys).
- Network observers can see WireGuard traffic but not decrypted payloads once the tunnel is up.

Controls
--------
- Runtime key generation via `wg genkey`/`wg pubkey` per session.
- Session metadata limited to `.runtime/session.env`, cleaned by `cracked end`.
- Tor wrapper available for auxiliary commands to enforce consistent routing.
- `cracked status` exposes current IPs and handshake timestamps for manual verification.
