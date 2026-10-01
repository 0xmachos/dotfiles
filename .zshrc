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

INITIAL_DIR="${HOME}/Documents/Projects"


# $PATH & ENV exports MUST be at the top of .zshrc
# Later commands fail or misbehave if these are not exported first.
# See: b79b7968166df0238df8aa61e975b9bcecbabf06

### $PATH Exports ###

if [[ -x "/opt/homebrew/bin/brew" && (
  "${HOMEBREW_PREFIX:-}" != "/opt/homebrew" ||
  "${HOMEBREW_CELLAR:-}" != "/opt/homebrew/Cellar" ||
  "${HOMEBREW_REPOSITORY:-}" != "/opt/homebrew" ||
  ":${PATH}:" != *":/opt/homebrew/bin:"*
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
export CLAUDE_CODE_TMPDIR="${HOME}/Library/Caches/claude-tmp"

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
# Expansion in prompts (RPROMPT reads vcs_info_msg_0_)

autoload -Uz vcs_info
precmd_functions+=(vcs_info)
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '(%b)'
# shellcheck disable=SC2034
RPROMPT=\$vcs_info_msg_0_


### Command/ Path Correction ###

setopt correct
# Command correction

setopt correct_all
# Argument correction

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

autoload -Uz compinit
compinit

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

if [[ -d "${INITIAL_DIR}" ]]; then
  # shellcheck disable=SC2164
  cd "${INITIAL_DIR}"
fi
