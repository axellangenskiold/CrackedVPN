CrackedVPN Security Checklist
=============================

Local Host
----------
- [ ] Install WireGuard (`wg`, `wg-quick`) from trusted sources.
- [ ] Install Tor (`torsocks`) and ensure the daemon is up-to-date.
- [ ] Keep OS fully patched; enable disk encryption and secure boot.
- [ ] Limit repository permissions (chmod 700) when storing sensitive templates.

Templates
---------
- [ ] Never commit real client keys or IPs to `templates/`.
- [ ] Rotate exit node keys regularly; update template placeholders accordingly.
- [ ] Validate each template with `cracked setcountry <key>` before use.

Runtime
-------
- [ ] Ensure `.runtime/` is owned by the invoking user and chmod 700.
- [ ] Monitor `wg show` output for unexpected peers.
- [ ] Use `cracked status` to confirm Tor IP differs from your ISP IP.
- [ ] Always terminate sessions via `cracked end` once finished.

Exit Node
---------
- [ ] Limit exposed ports to UDP 51820 (WireGuard).
- [ ] Force Tor routing for all outbound traffic.
- [ ] Use infrastructure-as-code or scripts to rebuild clean nodes when rotating countries.
