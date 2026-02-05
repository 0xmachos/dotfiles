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
# We need all of these to be exported first otherwise some commands will fail or behaviour unexpectedly
# See: b79b7968166df0238df8aa61e975b9bcecbabf06

### $PATH Exports ###

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Add Homebrew to PATH
fi


if [[ -x "$HOME/Library/Python/3.9/bin/virtualenv" ]]; then
  # Should the second check be "$HOME/Library/Python/*/bin/virtualenv" this will need manually 
  #   changed when python moves to version 4.x
  
  export PATH=$PATH:$HOME/Library/Python/3.9/bin
  # Required for virtualenv as installed by pip
  # pip3 show virtualenv
fi

if [[ -x "$HOME/.local/bin/claude" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi


### Enviroment Variable Exports ###

if [[ -x "/usr/local/bin/brew" ]]; then
  export HOMEBREW_BREWFILE=$HOME/Documents/Projects/dotfiles/.extra/Brewfile
  # Set location of Brewfile

  export BREW_VERIFY_ATTESTATIONS=true
  # https://blog.trailofbits.com/2023/11/06/adding-build-provenance-to-homebrew/
  # https://blog.trailofbits.com/2024/05/14/a-peek-into-build-provenance-for-homebrew/

  export HOMEBREW_DOWNLOAD_CONCURRENCY=auto
fi

if [[ -d "/Applications/Secretive.app" ]]; then
  export SSH_AUTH_SOCK=$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
fi

export IIOEnableOOP=YES
# Enabled the undocumeted ImageIO sandbox
# Tells ImageIO to parse images our of process in the ImageIOXPCService process instead 
# https://rtx.meta.security/mitigation/2023/09/11/Sandboxing-ImageIO-in-macOS.html



### Prompt ###
# shellcheck disable=SC2034
PROMPT=$'%F{blue}% %n%f 🐶 %B%~%b\n%(?.%F{green}√%f.%F{red}%?)%f %(!.#.$) '
# Example 
# 0xmachos 🐶 /System/Library/CoreServices
# √ $ 

# Explanation
# %F{blue}% %n%f
## Print username (%n) in blue
# %B%~%b
## Print pwd relative to $HOME (%~) in bold (%B)
## If last command exit 0 print √ in green else print exit code in red 
# %(!.#.$)
# If root print # else print $

# Git Integration
# https://git-scm.com/book/en/v2/Appendix-A:-Git-in-Other-Environments-Git-in-Zsh
# Moving to Zsh p139

setopt prompt_subst
# ENABLE: parameter expansion and command substitution in prompts

autoload -Uz vcs_info
precmd_functions+=(vcs_info)
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '(%b)'
# shellcheck disable=SC2034
RPROMPT=\$vcs_info_msg_0_


### Command/ Path Correction ###

setopt correct
# ENABLE: Command correction

setopt correct_all
# ENABLE: Argument correction

# shellcheck disable=SC2034
SPROMPT="Correct %F{red}%R%f to %F{green}%r%f [nyae]?"
# Correction prompt


### Behaviour ###
setopt autocd 
# ENABLE: Changes directory to path without needing cd

setopt glob_complete
# ENABLE: Hitting tab twice lists possible completions 

unsetopt case_glob
# DISABLE: Case sensitive globbing


### Completion ###

# Initialise zsh completion system 
#   https://github.com/zsh-users/zsh-completions
#   https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
#   Enables zsh-completions as installed by brew
#   If “zsh compinit: insecure directories” run 
#     chmod -R go-w "$(brew --prefix)/share"
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

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
  
  FPATH="$HOME/.functions/:$FPATH"
  # Add $HOME/.functions/ to FPATH

  # shellcheck disable=SC2086,SC2154,SC1087
  autoload -Uz $fpath[1]/*(.:t)
  # Lazy autoload every file in $HOME/.functions/*  as a function
  #   I've no idea what (.:t) does ¯\_(ツ)_/¯
  #   https://unix.stackexchange.com/a/526429
fi


### Aliases ###

# shellcheck disable=SC1091
source "$HOME/.aliases"


### History ###

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# Location of history file
# Use value of $ZDOTDIR if it has a value
# otherwise use value of $HOME

HISTSIZE=50000
# Lines remembered per session

# shellcheck disable=SC2034
SAVEHIST=100000
# Lines stored in history file

setopt EXTENDED_HISTORY
# Save command start time and duration

setopt SHARE_HISTORY
# Use single shared history file for all sessions

## Reducing Clutter 
setopt HIST_EXPIRE_DUPS_FIRST
# Expire duplicates first
setopt HIST_IGNORE_DUPS
# Do not store duplications
setopt HIST_FIND_NO_DUPS
# Ignore duplicates when searching
setopt HIST_REDUCE_BLANKS
# Remove blank lines
setopt HIST_IGNORE_SPACE
# Do not store command lines starting with a space


### Change into Inital Directory ###

if [[ -d "${INITIAL_DIR}" ]]; then
  # shellcheck disable=SC2164
  cd "${INITIAL_DIR}"
fi

