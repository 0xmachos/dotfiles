#!/usr/bin/env bash
# ~/.bash_profile

#  ---------------------------------------------------------------------------
# Based on:
#   https://gist.github.com/natelandau/10654137
#   https://github.com/jessfraz/dotfiles/blob/master/.bash_profile
#  ---------------------------------------------------------------------------

OS=$(uname -s)

#   ---------------------------
#   ENVIRONMENT CONFIGURATION
#   ---------------------------

if [[ -d "${HOME}/Documents/Projects" ]]; then
  # shellcheck disable=SC2164
  cd "${HOME}/Documents/Projects"
  # Start each terminal session in this directory
fi  


if [[ "${OS}" == "Darwin" ]]; then
  # brew-file wrapper for brew
  if [ -f "$(brew --prefix)/etc/brew-wrap" ];then
    # shellcheck disable=SC1090
    source "$(brew --prefix)/etc/brew-wrap"
  fi
fi


#   ---------------------------
#   LOAD DOTFILES 
#   ---------------------------

for file in ~/.{bash_prompt,aliases,extra,exports}; do
  
  if [[ -r "${file}" ]] && [[ -f "${file}" ]]; then
    # shellcheck disable=SC1090
    source "${file}"
  fi

done


#   ---------------------------
#   SCRIPTS TO RUN 
#   ---------------------------

if [[ -x "/usr/local/bin/pihole_stats" ]]; then 
  /usr/local/bin/pihole_stats
fi

