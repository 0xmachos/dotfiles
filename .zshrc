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

unsetopt case_glob
# DISABLE: Case sensitive globbing


### Command/ Path Correction ###

setopt correct
# ENABLE: Command correction

setopt correct_all
# ENABLE: Argument correction

SPROMPT="Correct %F{red}%R%f to %F{green}%r%f [nyae]?"
# Correction prompt

### END Correction ###


### History ###

HISTFILE=${ZDOTDIR:-HOME}/.zsh_history
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

### END History ###

