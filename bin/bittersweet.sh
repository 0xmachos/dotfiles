#!/bin/bash
# dotfiles/bin/bittersweet.sh

# bittersweet.sh
#	Configures macOS just the way I like it
# Tested on:
#	10.13

set -euo pipefail
# -e exit if any command returns non-zero status code
# -u prevent using undefined variables
# -o pipefail force pipelines to fail on first non-zero status code
function usage {
	echo -e "\nConfigures macOS just the way I like it 🤓\n"
	echo "Usage:"
	echo "	defaults	- Write new system and application default settings"
	echo "	vmware 		- Change VMWare defaultVMPath to $HOME/Virtual Machines" 
	

	echo -e "\n 	\033[0;31mhailmary\033[0m 	- Run every function in order listed above"

	exit 0
}


function defaults {

	echo "[🍺] Writing some system & application defaults"

    defaults write com.apple.TextEdit RichText -int 0
    # TextEdit: Use Plain Text Mode as Default
    # Default: com.apple.TextEdit RichText -int 1

	defaults write com.apple.mail minSizeKB 5000
	# Mail: If attatchment is over 5MB ask to send via Mail Drop
	# Default: com.apple.mail minSizeKB 20000

	defaults write com.apple.menuextra.battery ShowPercent -string "YES"
	# Menu Bar: Show battery percentage
	# Default: com.apple.menuextra.battery ShowPercent -string "NO"

	exit 0
}


function change_vmware_home {

	# Create new directory in $HOME
	# Set prefvmx.defaultVMPath to new directory in VMWare preferences file

	echo "[🍺] Setting VMWare VM Default Location"

	if mkdir $HOME/Virtual\ Machines ; then
		echo "[✅] Successfully created $HOME/Virtual Machines"
		
		if echo 'prefvmx.defaultVMPath = "'$HOME'/Virtual Machines/"' >> ~/Library/Preferences/VMWare\ Fusion/preferences ; then
			echo "[✅] Successfully changed prefvmx.defaultVMPath"
			exit 0
		else
			echo "[❌] Failed to change prefvmx.defaultVMPath to $HOME/Virtual Machines"
			exit 1
		fi

	else
		echo "[❌] Failed to create $HOME/Virtual Machines"
		exit 1
	fi
}


function install_file { 

	# install_file $dir $source $destination
	# Check if directory ($dir) exists if not create it
	# Check if cp -i suceeds, if file exists ask user whether to overwrite
	# TODO: Get $dir from $destination path     


	local dir=${1:-""}
	local source=${2:-""}
	local destination=${3:-""}

	if [ -d $dir ]; then
		echo "[🍺] '$destination' already exists"

		if cp -i "$source" "$destination" ; then
			echo "[✅] Successfully installed '$destination'"
		else
			echo "[❌] Failed to install '$destination'"
			exit 1
		fi

	else
		
		if mkdir $dir ; then
			echo "[✅] Successfully created $HOME/.ssh"
		
			if cp -i "$source" "$destination" ; then
				echo "[✅] Successfully installed '$destination'"
			else
				echo "[❌] Failed to install '$destination'"
				exit 1
			fi

		else
			echo "[❌] Failed to create '$dir'"
			exit 1	
		fi	
	fi

}
function main {
	local cmd=${1:-"usage"}

    if [[ $cmd == "defaults" ]]; then
        defaults

    elif [[ $cmd == "vmware" ]]; then
		change_vmware_home

    elif [[ $cmd == "hailmary" ]]; then
    # Execute all the functions
		# Order matters!
		# TODO: Manually adding new fucntions sucks
		echo -e "[🍺] \033[0;31mHailmary\033[0m engaged "

		#defaults
		#change_vmware_home

	else
		usage
	fi
}

main "$@"
