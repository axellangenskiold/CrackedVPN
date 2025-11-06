Developer Notes
===============

Structure
---------
- `cracked`: top-level CLI dispatcher callable from anywhere once on `PATH`.
- `scripts/`: implementation of each subcommand (start, end, setcountry, status, tor_wrapper).
- `.runtime/`: ephemeral state (selected country, session metadata, generated configs).
- `templates/`: WireGuard server stubs (no client secrets).

Workflow
--------
1. `cracked setcountry <key>` writes `.runtime/country`.
2. `cracked start` loads the template, generates keys, writes a transient config under `.runtime/`, and calls `wg-quick up`. Session metadata goes to `.runtime/session.env`.
3. `cracked status` reads `.runtime/country`, inspects `wg`, and performs IP checks.
4. `cracked end` reads `.runtime/session.env`, calls `wg-quick down`, and wipes transient files.

Testing/Linting (TODO)
----------------------
- Add shellcheck targets and smoke tests covering each subcommand.
