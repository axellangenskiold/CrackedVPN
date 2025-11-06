CrackedVPN Installation Guide
=============================

Prerequisites
-------------
- macOS or Linux with bash 5+
- WireGuard tools: `wg`, `wg-quick`
- `torsocks` and `curl`
- `sudo` access for bringing interfaces up/down

Steps
-----
1. Clone this repository anywhere on your system.
2. Add the repo directory to your `PATH` (or symlink `cracked` to a directory already on the PATH). Example:
   ```bash
   ln -sf "$PWD/cracked" /usr/local/bin/cracked
   ```
3. Ensure `scripts/` files are executable (`chmod +x scripts/*.sh`).
4. Edit `templates/wg0_local.conf` with your exit node’s public key, endpoint, and addresses.
5. (Optional) create additional templates (e.g., `wg0_us.conf`) following the same format.
6. Run `cracked setcountry local` to select the default template.
7. Start the VPN with `cracked start`.
8. Confirm connectivity with `cracked status`.
