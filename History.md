# History

Completed work whose *record* is worth keeping but whose *knowledge* lives
elsewhere. One entry per change, newest first. Explanatory content belongs in
`internals/<topic>.md`, `CLAUDE.md`, or `README.md` — this file is the bare
"this happened, on this date" ledger that `TODOs.md` must not accumulate.

`TODOs.md` holds only open items.

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
