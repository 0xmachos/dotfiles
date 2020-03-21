# ~/.zshrc
# dotfiles/.zshrc

#  ---------------------------------------------------------------------------
#   Based on:
#     https://scriptingosx.com/2019/11/new-book-release-day-moving-to-zsh/ 
#  ---------------------------------------------------------------------------

# Convention(s)
# Enable:  setopt
# Disable: unsetopt

setopt autocd 
# ENABLE: Changes directory to path without needing cd

setopt glob_complete
# ENABLE: Hitting tab twice lists possible completions 

setopt correct
setopt correct_all
# ENABLE: Command correction

SPROMPT="Correct %F{red}%R%f to %F{green}%r%f [nyae]?" 
# SET_VAR: Custom command correction prompt 

setopt +o case_glob
# DISABLE: Case sensitive globbing

### History ###

HISTFILE=${ZDOTDIR:-HOME}/.zsh_history
# Location of history file
# Use value of $ZDOTDIR if it has a value
# otherwise use value of $HOME
HISTSIZE=50000
# Lines remembered per session
SAVEHIST=50000
# Lines stored in history file

## Reducing Clutter 
setopt HIST_EXPIRE_DUPS_FIRST
# Expire duplicates first
setopt HIST_IGNORE_DUPS
# Do not store duplications
setop HIST_FIND_NO_DUPS
# Ignore duplicates when searching
setopt HIST_REDUCE_BLANKS
# Remove blank lines
setopt HIST_IGNORE_SPACE
# Do not store command lines starting with a space

### END History ###

