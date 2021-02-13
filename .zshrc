# ~/.zshrc
# dotfiles/.zshrc

#  ---------------------------------------------------------------------------
#   Based on:
#     https://scriptingosx.com/2019/11/new-book-release-day-moving-to-zsh/ 
#  ---------------------------------------------------------------------------

# Convention(s)
# Enable:  setopt
# Disable: unsetopt


### Constants ####

readonly OS=$(uname -s)
readonly INITIAL_DIR="${HOME}/Documents/Projects"


### Prompt ###
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
RPROMPT=\$vcs_info_msg_0_


### Command/ Path Correction ###

setopt correct
# ENABLE: Command correction

setopt correct_all
# ENABLE: Argument correction

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
#   Enables zsh-completions as installed by brew
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

FPATH="$HOME/.functions/:$FPATH"
# Add $HOME/.functions/ to FPATH

autoload -Uz $fpath[1]/*(.:t)
# Lazy autoload every file in $HOME/.functions/*  as a function
#   I've no idea what (.:t) does ¯\_(ツ)_/¯
#   https://unix.stackexchange.com/a/526429


### Aliases ###

source "$HOME/.aliases"


### History ###

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# Location of history file
# Use value of $ZDOTDIR if it has a value
# otherwise use value of $HOME

HISTSIZE=50000
# Lines remembered per session

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


if [ -d "${INITIAL_DIR}" ]; then
  cd "${INITIAL_DIR}"
fi

