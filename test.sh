#!/usr/bin/env bash
# dotfiles/bin/test.sh

# test.sh
# 	Find shell scripts then run shellcheck 
# 	Adapted from jessfraz/dotfiles/bin/test.sh
# 	https://github.com/jessfraz/dotfiles/blob/master/test.sh

set -euo pipefail

ERRORS=()

FAIL="\\033[1;31mFAIL\\033[0m"
PASS="\\033[1;32mPASS\\033[0m"

for f in $(find . -type f -not -iwholename '*.git*' | sort -u); do
	# Find all regular files in source directory
	# Ignore any git related files
	# Filter out duplicate entries 
	if file "${f}" | grep --quiet shell; then
		# If file type is shell script
		{
			shellcheck "${f}" && echo -e "[${PASS}] Sucessfully linted ${f}"
			# Run shellcheck 
		} || {
			# If shellcheck finds errors add them tp errors array
			ERRORS+=("${f}")
		}
	fi
done


if [ ${#ERRORS[@]} -eq 0 ]; then
	echo -e "[${PASS}] No errors, hooray"
else
	echo -e "[${FAIL}] These files failed shellcheck: ${ERRORS[*]}"
	exit 1
fi
