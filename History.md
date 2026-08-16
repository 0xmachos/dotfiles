# History

Completed work whose *record* is worth keeping but whose *knowledge* lives
elsewhere. One entry per change, newest first. Explanatory content belongs in
`internals/<topic>.md`, `CLAUDE.md`, or `README.md` — this file is the bare
"this happened, on this date" ledger that `TODOs.md` must not accumulate.

`TODOs.md` holds only open items.

## 2026-08-16 — Uninstall Santa; remove its repo tooling

Santa 2026.3 (NPS) uninstalled from the MacBook via the official sequence
(`Santa --unload-system-extension`, then app/launchd plists/`/var/db/santa`
removal — a bare `sudo rm` of the app bundle is denied by santad's tamper
protection). Repo side removed: `profiles/santa-faa-policy.plist`,
`profiles/com.0xmachos.santa.mobileconfig`, `tests/santa-faa`,
`tests/santa-profile`, the `santa-faa`/`dcg-sync` subcommands
(`install_santa_faa`/`sync_dcg_cdhash`/`_read_dcg_cdhash_from_plist`), the
`dcg-sync` call in `.functions/jump`, and `bin/agent-reset`'s FAA
AuditOnly-flip machinery. dcg itself stays — only its CDHash pinning existed
for Santa. Retired knowledge: `internals/santa.md`.

## 2026-08-08 — Require signed commits server-side on `0xmachos/dotfiles`

GitHub repository ruleset `require-signed-commits` (id `20588962`) created:
`target=branch`, `enforcement=active`, condition `~DEFAULT_BRANCH`, rules
`[required_signatures]`, `bypass_actors=[]`, `current_user_can_bypass=never`.
Chosen over classic branch protection so it adds only the signature
requirement and leaves direct pushes and force-push to `main` alone.

Prompted by the 2026-08-08 dual review of the git-signing tooling: the client
`pre-push` gate is bypassable by construction (`--no-verify`,
`GIT_SIGN_SKIP=1`, or any repo-local `core.hooksPath`), so it is defence in
depth rather than the enforcement boundary. Covers this repo only.

Behaviour and the recovery path when signing breaks: `internals/hooks.md` →
Global pre-push signature gate → "The server-side backstop".
