#!/usr/bin/env bash
# ~/.bash_profile

#  ---------------------------------------------------------------------------
#   Based on:
#   https://gist.github.com/natelandau/10654137
#   https://github.com/jessfraz/dotfiles/blob/master/.bash_profile
#  ---------------------------------------------------------------------------

OS=$(uname -s)

#   ---------------------------
#   ENVIRONMENT CONFIGURATION
#   ---------------------------

readonly INITIAL_DIR="${HOME}/Documents/Projects"

if [[ -d "${INITIAL_DIR}" ]]; then
  # shellcheck disable=SC2164
  cd "${INITIAL_DIR}"
  # Start each terminal session in this directory
fi  


if [[ "${OS}" == "Darwin" ]]; then
  if [ -x "$(command -v brew)" ]; then
    
    # brew-file wrapper for brew
    if [ -f "$(brew --prefix)/etc/brew-wrap" ];then
      # shellcheck disable=SC1090
      source "$(brew --prefix)/etc/brew-wrap"
    fi

    # brew shell completion
    # https://docs.brew.sh/Shell-Completion
    # shellcheck disable=SC2231
    for completion_file in $(brew --prefix)/etc/bash_completion.d/*; do
      # shellcheck disable=SC1090
      source "$completion_file"
    done
    
  fi
fi


#   ---------------------------
#   LOAD DOTFILES 
#   ---------------------------

for file in ~/.{bash_prompt,aliases,.extra/,exports,functions}; do
  
  if [[ -r "${file}" ]] && [[ -f "${file}" ]]; then
    # shellcheck disable=SC1090
    source "${file}"
  fi

done


#   ---------------------------
#   SCRIPTS TO RUN 
#   ---------------------------

