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
	echo "	defaults		- Write new system and application default settings"
	echo "	vmware 			- Change VMWare defaultVMPath to '${HOME}/Virtual Machines'"
	echo "	gpgtools 		- Install GPGTools"
	echo "	brew 			- Install Homebrew, Homebrew-file and export HOMEBREW_BREWFILE" 
	echo "	brewfile {Brewfile}	- Install Homebrew packages from Brewfile"

	echo -e "\n 	\033[0;31mhailmary\033[0m 	- Run every function in order listed above"

	exit 0
}


function write_defaults {

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

}


function install_gpgtools {
	
	if ! [ -x "$(command -v gpg2)" ]; then
		
		echo "[🍺] Installing GPGTools (GPG Suite)"

		# shellcheck disable=SC2155
		local latest_gpgtools_version=$(curl -s "https://gpgtools.org/releases/gpgsuite/release-notes.html" \
										| grep -m 1 "data-version=" \
										| awk -F \" '{print $(NF-1)}')
		# Get the latest version string
		# Not sure if this method will survive an update to the site
		local dmg_name="GPG_Suite-${latest_gpgtools_version}.dmg"
		local dmg_download_path="${HOME}/Downloads/${dmg_name}" 
		# shellcheck disable=SC2155
		local dmg_sha256="$(curl -s "https://gpgtools.org" \
							| grep -m 1 "SHA256" \
							| awk '{print $6}' \
							| cut -c 21-84)"
		# Get the SHA256 hash of the latest DMG
		# HACK: 
		# Need better method to extract the hash than cuting the charcter positions
		# Almost certinly won't survive an update to the site 
		local dmg_mount_point="/Volumes/GPG Suite/" 

		echo "[🍺] Downloading ${dmg_name}"
		if curl -o "${dmg_download_path}" "https://releases.gpgtools.org/${dmg_name}" ; then 
			# Download 
			echo "[✅] Successfully downladed ${dmg_name}"
		else
			echo "[❌] Failed to download ${dmg_name}"
			exit 1
		fi

		echo "${dmg_sha256}  ${dmg_name}" > "${dmg_download_path}.sha256"
		# Construct a correctly formatted SHA256 checksum line
		# 01705da33b9dadaf5282d28f9ef58f2eb7cd8ff6f19b4ade78861bf87668a061  GPG_Suite-2017.1.dmg

		(
			# Execute in a subshell so the working directory is not permanantly changed
			cd "${HOME}/Downloads"

			if shasum -a 256 -c "${dmg_download_path}.sha256" ; then 
			# Attempt to validate the DMGs SHA256 hash
				echo "[✅] Successfully validated ${dmg_name} SHA256 hash"
			else
				echo "[❌] Failed to validate ${dmg_name} SHA256 hash"
				exit 1
			fi

		)

		echo "[🍺] Attempting to mount ${dmg_download_path}"
		if hdiutil attach -quiet "${dmg_download_path}" ; then
		# Attempt to mount the DMG 
			echo "[✅] Successfully mounted ${dmg_name}"
		else
			echo "[❌] Failed to mount ${dmg_name}"
			exit 1
		fi	

		if pkgutil --check-signature "${dmg_mount_point}/Install.pkg" ; then
		# Check PKG is correctly sogned
			echo "[✅] Successfully validated the signature on the package"
		else
			echo "[❌] Failed to validate the signature on the package"
			exit 1
		fi

		
		echo "[⚠️ ] Password required for installer"
		if sudo installer -pkg "${dmg_mount_point}/Install.pkg" -target "/" ; then
			# Install
			echo "[✅] Successfully installed GPGTools"
		else
			echo "[❌] Failed to install GPGTools"
			exit 1
		fi

		# Cleanup 
		echo "[🍺] Unmounting ${dmg_mount_point}"
		hdiutil detach -quiet "${dmg_mount_point}"
		# Unmount the DMG
		
		echo "[🍺] Deleting ${dmg_download_path}"
		rm "${dmg_download_path}"
		# Delete the DMG
		
		echo "[🍺] Deleting ${dmg_download_path}.sha256"
		rm "${dmg_download_path}.sha256"
		# Delete the SHA256 file 

	else
		echo "[🍺] $(gpg --version | head -n 1) already installed"
	fi
}


function change_vmware_home {

	# Create new directory $HOME/Virtual Machines
	# Set prefvmx.defaultVMPath to $HOME/Virtual Machines in ~/Library/Preferences/VMWare Fusion/preferences
	# TODO: Allow user to pass their own path for prefvmx_defaultVMPath  

	local vmware_preferences_file="${HOME}/Library/Preferences/VMware Fusion/preferences"
	local vmware_preferences_directory="${HOME}/Library/Preferences/VMware Fusion"
	local prefvmx_defaultVMPath="${HOME}/VMware Fusion"

	if [ ! -d "${vmware_preferences_directory}" ]; then
		# Check if VMWare Fusion is installed
		echo "[❌] VMWare Fusion is not installed"
	else
		
		if grep -q prefvmx.defaultVMPath "${vmware_preferences_file}" ; then
			# Check if prefvmx.defaultVMPath is already set
			echo "[❌] prefvmx.defaultVMPath is already set"
			exit 1
		else
			echo "[🍺] Setting VMWare prefvmx.defaultVMPath to '${prefvmx_defaultVMPath}'"

			if mkdir -p "${prefvmx_defaultVMPath}" ; then
				# Attempt to create the directory for VM storage 
				echo "[✅] Successfully created '${prefvmx_defaultVMPath}'"
				
				if echo "prefvmx.defaultVMPath = ${prefvmx_defaultVMPath}" >> "${vmware_preferences_file}" ; then
					echo "[✅] Successfully set prefvmx.defaultVMPath"
				else
					echo "[❌] Failed to set prefvmx.defaultVMPath to '${prefvmx_defaultVMPath}'"
					exit 1
				fi

			else
				echo "[❌] Failed to create '${prefvmx_defaultVMPath}'"
				exit 1
			fi
		fi
	fi	
}


function install_brew {

	# Install Homebrew and Homebrew-file
	
	if ! [ -x "$(command -v brew)" ]; then

		echo "[🍺] Installing Homebrew"
		echo -e "[⚠️ ] \033[0;31mStick around\033[0m - Requires you to press RETURN and input your password"
		sleep 5
	   	
	   	if /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" ; then
	   		echo "[✅] Successfully installed Homebrew 🍻"
	   	else
	   		echo "[❌] Failed to install Homebrew 😢"
	   		exit 1
	   	fi    

  	else
  		
  		brew update
     	brew upgrade
     	brew cleanup
    fi

   	echo "[🍺] Installing Homebrew-file"

   	if ! [ -x "$(command -v brew-file)" ]; then

   		if brew install rcmdnk/file/brew-file ; then
   			echo "[✅] Successfully installed Homebrew-file"
   		else
   			echo "[❌] Failed to install Homebrew-file"
   			exit 1
   		fi
   	else
   		echo "[🍺] Homebrew-file already installed"
   	fi 

}


function install_brewfile {

	# Install Homebrew packages from dotfiles/Brewfile
	# Will install programs from the Mac AppStore if user is logged in
	
	export HOMEBREW_BREWFILE="${homebrew_brewfile}"
	echo "[🍺] Exported HOMEBREW_BREWFILE=${homebrew_brewfile}"

   	echo "[🍺] Installing Homebrew packages from Brewfile"
   	echo "[⚠️ ] Password required for brew file install"

   	if brew file install ; then 
   		echo "[✅] Successfully installed packages from Brewfile"
	else
		echo "[❌] Failed to install packages from Brewfile"
		exit 1
	fi
}


function main {

	local cmd=${1:-"usage"}
	local homebrew_brewfile=${2:-${HOME}/Documents/Projects/dotfiles/Brewfile}

	if [[ "${cmd}" == "defaults" ]]; then
		write_defaults

	elif [[ "${cmd}" == "vmware" ]]; then
		change_vmware_home

	elif [[ "${cmd}" == "brew" ]]; then
		install_brew

	elif [[ "${cmd}" == "brewfile" ]]; then
		install_brewfile "${homebrew_brewfile}"

	elif [[ "${cmd}" == "gpgtools" ]]; then 
		install_gpgtools

	elif [[ "${cmd}" == "hailmary" ]]; then
		# Execute all the functions
		# Order matters!
		# TODO: Manually adding new fucntions sucks
		echo -e "[🍺] \033[0;31mHailmary\033[0m engaged"

		write_defaults
		install_gpgtools
		change_vmware_home
		install_brew
		install_brewfile "${homebrew_brewfile}"

	else
		usage
	fi
}

main "$@"