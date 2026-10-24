#!/usr/bin/env zsh
# ~/.zshrc
# dotfiles/.zshrc
# http://zsh.sourceforge.net/Intro/intro_3.html

#  ---------------------------------------------------------------------------
#   Based on:
#     https://scriptingosx.com/2019/11/new-book-release-day-moving-to-zsh/ 
#  ---------------------------------------------------------------------------

# Convention(s)
# Enable:  setopt
# Disable: unsetopt


### Constants ####

INITIAL_DIR="${HOME}"


# $PATH & ENV exports MUST be at the top of .zshrc
# Later commands fail or misbehave if these are not exported first.
# See: b79b7968166df0238df8aa61e975b9bcecbabf06

### $PATH Exports ###

# -U on both names of each tied pair: zsh applies the flag only to the name
# that is assigned, and this file writes both the scalars and the arrays.
typeset -U PATH path FPATH fpath

# The PATH test checks position, not presence: a nested login shell's
# path_helper moves inherited Homebrew dirs behind /usr/bin.
if [[ -x "/opt/homebrew/bin/brew" && (
  "${HOMEBREW_PREFIX:-}" != "/opt/homebrew" ||
  "${HOMEBREW_CELLAR:-}" != "/opt/homebrew/Cellar" ||
  "${HOMEBREW_REPOSITORY:-}" != "/opt/homebrew" ||
  ${path[(ie)/opt/homebrew/bin]} -gt ${path[(ie)/usr/bin]}
) ]]; then
  # Static copy of `brew shellenv zsh` (Homebrew 2026-10): running brew here
  # costs a bash process tree on every new terminal. Re-diff after brew upgrades.
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  # shellcheck disable=SC2034
  fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
  export FPATH
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
  [ -z "${MANPATH-}" ] || { export MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"; export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"; }
  [[ ":${INFOPATH:-}:" == *":/opt/homebrew/share/info:"* ]] ||
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi



if [[ -x "$HOME/.local/bin/claude" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi


### Environment Variable Exports ###

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  export HOMEBREW_VERIFY_ATTESTATIONS=true
  # Requires `gh` (GitHub CLI) — Homebrew shells out to `gh attestation verify`
  # https://blog.trailofbits.com/2023/11/06/adding-build-provenance-to-homebrew/
  # https://blog.trailofbits.com/2024/05/14/a-peek-into-build-provenance-for-homebrew/

  export HOMEBREW_DOWNLOAD_CONCURRENCY=auto
  export HOMEBREW_NO_ENV_HINTS=1
fi

if [[ -d "/Applications/Secretive.app" ]]; then
  export SSH_AUTH_SOCK=$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
fi

# Telemetry opt-out. DO_NOT_TRACK is the cross-tool convention
# (consoledonottrack.com). Claude Code treats its presence (any value) as a
# signal that silently disables Remote Control; claude/settings.json counters
# with env.DO_NOT_TRACK: "0" for Claude Code alone. GH_TELEMETRY opts `gh` out.
export DO_NOT_TRACK=true
export GH_TELEMETRY=false

# Claude Code temp files go under ~/Library/Caches, not /tmp (cleared on
# reboot); bin/scratch-sweep removes entries idle 14 days. Set here, not in
# claude/settings.json: that value is a literal path and $HOME varies.
export CLAUDE_CODE_TMPDIR="${HOME}/Library/Caches/tint"

# Undocumented ImageIO out-of-process parsing (ImageIOXPCService sandbox).
# Value must be 1, not YES: ImageIO uses atoi(), atoi("YES") is 0.
export IIOEnableOOP=1
# Terminal-launched processes only; GUI apps get it from
# LaunchAgents/com.0xmachos.imageio-oop.plist (launchctl setenv at login).
# Current session: launchctl setenv IIOEnableOOP 1
# https://rtx.meta.security/mitigation/2023/09/11/Sandboxing-ImageIO-in-macOS.html



### Prompt ###
# shellcheck disable=SC2034
PROMPT=$'%F{blue}% %n%f 🐶 %B%~%b\n%(?.%F{green}√%f.%F{red}%?)%f %(!.#.$) '
# Example
# 0xmachos 🐶 /System/Library/CoreServices
# √ $

# Line 2: √ in green if the last command exited 0, else the exit code in red;
# # for root, $ otherwise.

# Git Integration
# https://git-scm.com/book/en/v2/Appendix-A:-Git-in-Other-Environments-Git-in-Zsh
# Moving to Zsh p139

setopt prompt_subst
# Expansion in prompts (RPROMPT reads _git_prompt)

# Branch from HEAD in pure zsh, no process: vcs_info ran git before every
# prompt, about 75 ms in a repo (measured 2026-10-22). A linked worktree or
# submodule has a .git file naming its git dir. Detached HEAD shows 7 hex.
function _git_prompt_branch {
  _git_prompt=''
  local dir="${PWD}" gitdir head
  while true; do
    if [[ -d "${dir}/.git" ]]; then
      gitdir="${dir}/.git"
      break
    elif [[ -f "${dir}/.git" ]]; then
      read -r head < "${dir}/.git" || return 0
      [[ "${head}" == 'gitdir: '* ]] || return 0
      gitdir="${head#gitdir: }"
      [[ "${gitdir}" == /* ]] || gitdir="${dir}/${gitdir}"
      break
    fi
    [[ "${dir}" == / ]] && return 0
    dir="${dir:h}"
  done
  read -r head < "${gitdir}/HEAD" 2>/dev/null || return 0
  if [[ "${head}" == 'ref: refs/heads/'* ]]; then
    _git_prompt="(${head#ref: refs/heads/})"
  else
    _git_prompt="(${head[1,7]})"
  fi
}
precmd_functions+=(_git_prompt_branch)
# shellcheck disable=SC2034
RPROMPT=\$_git_prompt


### Command/ Path Correction ###

setopt correct
# Command correction

setopt correct_all
# Argument correction

# shellcheck disable=SC2034
CORRECT_IGNORE_FILE='.*'
# Never offer a dotfile as an argument correction (claude -> .claude in ~)

# shellcheck disable=SC2034
SPROMPT="Correct %F{red}%R%f to %F{green}%r%f [nyae]?"


### Behaviour ###
setopt autocd 
# cd without typing cd

setopt glob_complete
# Tab twice lists completions

unsetopt case_glob
# Case-insensitive globbing


### Completion ###

# Initialise zsh completion system
#   https://github.com/zsh-users/zsh-completions
#   https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
#   Enables zsh-completions as installed by brew
#   If “zsh compinit: insecure directories” run
#     chmod -R go-w “$(brew --prefix)/share”
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  FPATH="${HOMEBREW_PREFIX}/share/zsh-completions:$FPATH"
fi

# User functions — must be in FPATH before compinit
if [[ -d "$HOME/.functions" ]]; then
  FPATH="$HOME/.functions/:$FPATH"
fi

# User completions — compinit scans for #compdef headers to register them
if [[ -d "$HOME/.completions" ]]; then
  FPATH="$HOME/.completions/:$FPATH"
fi

# Docker CLI completions (added by Docker Desktop)
if [[ -d "$HOME/.docker/completions" ]]; then
  FPATH="$HOME/.docker/completions:$FPATH"
fi

# compinit -C skips the security audit and the scan for new completion files
# (about 31 ms down to 11 ms per start, measured 2026-10-22). The full
# compinit runs when the dump is missing or older than an $fpath directory: a
# directory's mtime moves when a completion file is added or removed. The old
# dump goes first, so the full run always writes a new one.
autoload -Uz compinit
function _compinit_cached {
  local dump="${ZDOTDIR:-$HOME}/.zcompdump" dir
  local -a dump_mtime dir_mtime
  zmodload -F zsh/stat b:zstat
  zmodload -F zsh/files b:zf_rm
  if zstat -A dump_mtime +mtime -- "${dump}" 2>/dev/null; then
    for dir in "${fpath[@]}"; do
      zstat -A dir_mtime +mtime -- "${dir}" 2>/dev/null || continue
      if (( dir_mtime[1] > dump_mtime[1] )); then
        zf_rm -f -- "${dump}"
        compinit -d "${dump}"
        return
      fi
    done
    compinit -C -d "${dump}"
  else
    compinit -d "${dump}"
  fi
}
_compinit_cached
unfunction _compinit_cached

# Case insensitive path-completion
zstyle ':completion:*' matcher-list 'm:
  {[:lower:][:upper:]}={[:upper:]
  [:lower:]}' 'm:{[:lower:][:upper:]}
  ={[:upper:][:lower:]} l:|=* r:|=*' 'm:
  {[:lower:][:upper:]}={[:upper:][:lower:]} 
  l:|=* r:|=*' 'm:{[:lower:][:upper:]}
  ={[:upper:][:lower:]} l:|=* r:|=*'

# Partial completion suggestions
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix


### Functions ###

if [[ -d "$HOME/.functions" ]]; then
  # shellcheck disable=SC2086,SC1087
  autoload -Uz "$HOME/.functions/"*(.:t)
  # Lazy autoload of every file as a function; (.:t) = regular files, basename
  #   https://unix.stackexchange.com/a/526429
fi


### Aliases ###

# shellcheck disable=SC1091
source "$HOME/.aliases"

# Bare `log` is zsh's login-watch builtin. A function outranks a builtin, so
# `log show …` reaches the unified log here and in the Claude Code Bash tool
# (its shell snapshot carries functions). Scripts and `ssh host log …` do not
# source this file: write /usr/bin/log there.
function log { /usr/bin/log "$@"; }


### History ###

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# $ZDOTDIR if set, else $HOME

HISTSIZE=50000
# Lines per session

# shellcheck disable=SC2034
SAVEHIST=100000
# Lines in the file

setopt EXTENDED_HISTORY
# Start time and duration

setopt SHARE_HISTORY
# One history file shared by all sessions

## Reducing Clutter 
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
# Do not store command lines starting with a space


### Change into Initial Directory ###

# In a herdr pane, new_cwd = "follow" starts the shell in the source pane's
# directory. Keep that for a new tab or split; a new space (its only pane)
# still starts in INITIAL_DIR.
_initial_dir_cd=1
if [[ -n "${HERDR_ENV:-}" && -n "${HERDR_WORKSPACE_ID:-}" ]]; then
  # alarm caps the call at 1 s so a hung herdr server cannot stall the shell.
  _herdr_ws="$(/usr/bin/perl -e 'alarm 1; exec @ARGV' "${HERDR_BIN_PATH:-herdr}" workspace get "${HERDR_WORKSPACE_ID}" 2>/dev/null)" || _herdr_ws=''
  [[ "${_herdr_ws}" == *'"pane_count":1,'* ]] || _initial_dir_cd=0
  unset _herdr_ws
fi
if [[ -d "${INITIAL_DIR}" && ${_initial_dir_cd} -eq 1 ]]; then
  # shellcheck disable=SC2164
  cd "${INITIAL_DIR}"
fi
unset _initial_dir_cd

# herdr fires no event on cd: ask the shell-tab plugin to rename the tab after
# each one (.functions/herdr_tab_chpwd). Registered after the initial cd.
chpwd_functions+=(herdr_tab_chpwd)
