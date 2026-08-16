# History

Completed work whose *record* is worth keeping but whose *knowledge* lives
elsewhere. One entry per change, newest first. Explanatory content belongs in
`internals/<topic>.md`, `CLAUDE.md`, or `README.md` — this file is the bare
"this happened, on this date" ledger that `TODOs.md` must not accumulate.

`TODOs.md` holds only open items.

## 2026-08-16 — Remove the research-vault (`danger`) tooling

Built for one malware RE project and never used since, so the whole client
side removed. Repo side: `bin/danger`, `LaunchAgents/com.0xmachos.vault-guard.plist`,
and `.completions/_danger` — all three were *untracked* private per-clone
files (`.extra_gitexclude`), so their exclude lines were dropped from
`.extra_gitexclude` + `.git/info/exclude` too; plus the
`danger-verify`/`vault-guard` subcommands (`install_danger_verify`/
`install_vault_guard`, their hailmary calls, both `launchagent_plists`
entries), the `danger` `bin_files` entry, both `tests/linkage` rows,
completions regenerated. `bin/danger` was `rm`'d rather than trashed (found
to be untracked only afterwards) — surviving copies: the server Mac's clone
until the next out-of-band push (rsync `--delete`) and Time Machine. Live
side: both vault-guard LaunchAgents (the repo label and an older per-user
one) booted out and their plists trashed, the vault SMB Keychain credential
deleted, and the `~/Documents/Projects/danger-verify` source repo trashed
(history pushed to GitHub; uncommitted refactor preserved in the Trash).
`/usr/local/bin/danger` + `/usr/local/bin/danger-verify` removed by hand
with `sudo rm`. Server-side setup (Vault volume, SMB share, `researchers`
group) untouched. Retired knowledge: `internals/danger-vault.md`.

## 2026-08-16 — Bootstrap `claude/` on the MacBook; init global CLAUDE.md

`claude/` created in the repo (skeleton `skills/`, `rules/`, `hosts/`,
`output-styles/`); the live `~/.claude/settings.json` moved in and symlinked
back by `bittersweet dotfiles`. `claude/global-claude.md` written fresh as a
minimal machine-verified seed and deployed as `~/.claude/CLAUDE.md` (repo-first
config rule, trash-over-rm, 1Password wrapper injection, machine notes).
`install_dotfiles` gained function-scoped `null_glob` so empty
`claude/skills/`/`rules/` no longer aborts the deploy under `set -e` (`setopt`
rather than `(N)` qualifiers — shellcheck's bash parser cannot parse those).
11 `claude_files` items (hooks, statuslines, `session-host-context`,
`hosts/*.md`) and the 4 `.codex/` files remain absent on this machine pending
out-of-band sync. The hook suites (`rm-redirect`, `npm-attest`,
`ssh-redirect`, `git-sign`, `container-tmp`, `gh-publish`, `hook-links`)
gained absent-hook skip guards the same day — before them, a missing hook
aborted the whole `./test` run mid-suite with no summary.

## 2026-08-16 — Remove `bin/codex-skills-from-rules`

The Codex↔Claude alignment bridge (generated `~/.agents/skills/` pointer
skills at `~/.claude/rules/*.md`) removed: repo script trashed (was
untracked), `bin_files` entry in `bittersweet` and `bin_scripts` row in
`tests/linkage` dropped, deployed `/usr/local/bin/codex-skills-from-rules`
symlink deleted. Codex now loads only `AGENTS.md`; nothing keeps it aligned
with Claude rules by tooling. Knowledge: `internals/codex-cli.md` → "Skills,
and why they are thin" (marked retired).

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
