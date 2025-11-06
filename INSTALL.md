# CrackedVPN Installation Guide

## Prerequisites

- macOS or Linux with bash 5+
- WireGuard tools: `wg`, `wg-quick`
- `torsocks` and `curl`
- `sudo` access for bringing interfaces up/down

## Steps

1. Clone this repository anywhere on your system.
2. Add the repo directory to your `PATH` (or symlink `cracked` to a directory already on the PATH). Example:
   ```bash
   ln -sf "$PWD/cracked" /usr/local/bin/cracked
   ```
3. Ensure `scripts/` files are executable (`chmod +x scripts/*.sh add_to_path.sh cracked`).
4. Add the repo to your `PATH` by running `./add_to_path.sh` from the repo root.
5. Copy the example template and edit it with your exit node details:
   ```bash
   cp templates/wg0_local.example templates/wg0_local.conf
   $EDITOR templates/wg0_local.conf
   ```
6. (Optional) create additional templates (e.g., copy the example to `wg0_us.conf`) following the same format.
7. Run `cracked setcountry local` to validate/select the template.
8. Start the VPN with `cracked start`.
9. Confirm connectivity with `cracked status`.
