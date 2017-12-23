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
	echo "	checkefi 		- Check integrity of the x86 flash chip firmware."
	echo "	defaults		- Write new system and application default settings"
	echo "	vmware 			- Change VMWare defaultVMPath to '${HOME}/Virtual Machines'"
	echo "	gpgtools 		- Install GPGTools"
	echo "	sublimetext 	- Install Sublime Text"
	echo "	tower 			- Install Tower"
	echo "	brew 			- Install Homebrew, Homebrew-file and export HOMEBREW_BREWFILE" 
	echo "	brewfile {Brewfile}	- Install Homebrew packages from Brewfile"

	echo -e "\n 	\033[0;31mhailmary\033[0m 	- Run every function in order listed above"

	exit 0
}


function write_defaults {

	echo "[🍺] Writing system & application defaults"

	defaults write com.apple.TextEdit RichText -int 0
	# TextEdit: Use Plain Text Mode as Default
	# Default: com.apple.TextEdit RichText -int 1

	defaults write com.apple.mail minSizeKB 5000
	# Mail: If attatchment is over 5MB ask to send via Mail Drop
	# Default: com.apple.mail minSizeKB 20000

	defaults write com.apple.menuextra.battery ShowPercent -string "YES"
	# Menu Bar: Show battery percentage
	# Default: com.apple.menuextra.battery ShowPercent -string "NO"

	defaults write -g NSNavPanelExpandedStateForSaveMode -bool true && \
	defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true
	# Save Panel: Show expanded version 
	# Default: defaults write -g NSNavPanelExpandedStateForSaveMode -bool false && \
	# defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool false

	defaults write com.apple.finder ShowStatusBar -bool true
	# Finder: Show the status bar
	# Default: defaults write com.apple.finder ShowStatusBar -bool false

	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	# Trackpad: Enable three finger drag
	# Default: defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

	defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
	# Trackpad: Enable tap to click
	# Default: defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false

	sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
	# Guest User: Disable
	# Default: sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool true

	defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  HH:mm"
	# Clock: Set format to Sun 26 Nov 16:00 

	defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
	# Spotlight: Disable suggestions in Lookup
	# Default: defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool false

	defaults write com.apple.Terminal SecureKeyboardEntry -bool true
	# Terminal: Enable Secure Keyboard Entry
	# Deafult: defaults write com.apple.Terminal SecureKeyboardEntry -bool false

	sudo defaults write /Library/Preferences/com.apple.alf globalstate -bool true
	# Firewall: Enable
	# Default: sudo defaults write /Library/Preferences/com.apple.alf globalstate -bool falee

}


function check_efi_integrity {

	if /usr/libexec/firmwarecheckers/eficheck/eficheck --integrity-check ; then 
		echo "[✅] Successfully verified EFI firmware integrity"
	else
		echo "[❌] Failed to verify EFI firmware integrity"
		exit 1
	fi
}


function install_gpgtools {
	
	if ! [ -x "$(command -v gpg2)" ]; then
		
		echo "[🍺] Installing GPGTools (GPG Suite)"

		# shellcheck disable=SC2155
		local latest_version="$(curl -s "https://gpgtools.org/releases/gpgsuite/release-notes.html" \
								| grep -m 1 'class="version"' \
								| awk -F '"' '{print $(NF-1)}')"
		# Get the latest version string
		# Query the id field from the latest div class="version"
		local dmg_name="GPG_Suite-${latest_version}.dmg"
		local dmg_download_path="${HOME}/Downloads/${dmg_name}" 
		# shellcheck disable=SC2155
		local dmg_sha256="$(curl -s "https://gpgtools.org" \
							| grep -m 1 "SHA256" \
							| perl -nle "print $& if m{(?<=class='tooltiptext'>).*(?=</span></span>)}")"
		# Get the SHA256 hash of the latest DMG
		local dmg_mount_point="/Volumes/GPG Suite/" 

		echo "[🍺] Downloading ${dmg_name}"
		if curl -o "${dmg_download_path}" "https://releases.gpgtools.org/${dmg_name}" ; then 
		# Download 
			echo "[✅] Successfully downloaded ${dmg_name}"
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

		echo "[🍺] Attempting to validate the signature on the package"
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
		echo "[🍺] $(gpg2 --version | head -n 1) already installed"
	fi
}


function install_sublime_text {

	if [ ! -d "/Applications/Sublime Text.app" ]; then

		echo "[🍺] Installing Sublime Text"

		local latest_build	
		latest_build="$(curl -s https://www.sublimetext.com/3 \
								| grep "Version:" \
								| awk '{print ($4+0)}')"
		# Get the latest build string
		# grep "Version:" \ : <p class="latest"><i>Version:</i> Build 3143</p>
		# awk '{print $4}' : 3143</p>
		# awk '{print ($4+0)}' : 3143
		# ($4+0) converts captured string to numeric
		local dmg_name="Sublime Text Build ${latest_build}.dmg"
		local dmg_download_path="${HOME}/Downloads/${dmg_name}"
		local dmg_mount_point="/Volumes/Sublime Text" 

		echo "[🍺] Downloading ${dmg_name}"
		if curl -o "${dmg_download_path}" "https://download.sublimetext.com/Sublime%20Text%20Build%20${latest_build}.dmg" ; then 
		# Download 
			echo "[✅] Successfully downloaded ${dmg_name}"
		else
			echo "[❌] Failed to download ${dmg_name}"
			exit 1
		fi

		echo "[🍺] Attempting to mount ${dmg_download_path}"
		if hdiutil attach -quiet "${dmg_download_path}" ; then
		# Attempt to mount the DMG 
			echo "[✅] Successfully mounted ${dmg_name}"
		else
			echo "[❌] Failed to mount ${dmg_name}"
			exit 1
		fi	

		echo "[🍺] Attempting to validated the signature on Sublime Text.app"
		if pkgutil --check-signature "${dmg_mount_point}/Sublime Text.app" ; then
		# Check Sublime Text.app is correctly sogned
			echo "[✅] Successfully validated the signature on Sublime Text.app"
		else
			echo "[❌] Failed to validate the signature on Sublime Text.app"
			exit 1
		fi

		echo "[🍺] Attempting to copy Sublime Text.app into /Applications"
		if cp -Ri "${dmg_mount_point}/Sublime Text.app" "/Applications" ; then
		# Attempt to copy Sublime Text.app into /Applications 
			echo "[✅] Successfully installed Sublime Text"
		else
			echo "[❌] Failed to install Sublime Text"
			exit 1
		fi

		## Install config files
		echo "[🍺] Installing Sublime Text config files"
		if mkdir -p "$HOME/Library/Application Support/Sublime Text 3/Packages/" ; then
			echo "[✅] Successfully created ~/Library/Application Support/Sublime Text 3/Packages/"
		else
			echo "[❌] Failed to create ~/Library/Application Support/Sublime Text 3/Packages/"
			exit 1
		fi 

		if cp -r "../Sublime Text 3/Packages/User" "$HOME/Library/Application Support/Sublime Text 3/Packages" ; then
			echo "[✅] Successfully installed Sublime Text config files"
		else
			echo "[❌] Failed to install Sublime Text config files"
			exit 1
		fi

		## Cleanup 
		echo "[🍺] Unmounting ${dmg_mount_point}"
		hdiutil detach -quiet "${dmg_mount_point}"
		# Unmount the DMG
	
		echo "[🍺] Deleting ${dmg_download_path}"
		rm "${dmg_download_path}"
		# Delete the DMG

	else 
		echo "[🍺] Sublime Text already installed"
	fi
}

function install_tower {

	if [ ! -d "/Applications/Tower.app" ]; then
		
		echo "[🍺] Installing Tower"

		local url="https://updates.fournova.com/tower2-mac/stable/releases/latest/download"
		local zip_name
		zip_name="$(curl -s -I "${url}" \
							| grep "Location:" \
							| awk -F / '{print $7}' \
							| tr -d '\r')"
		# Get the ZIP file name from the Location HTTP header
		# curl: -s Silent mode
		# 		-I Fetch headers only
		# awk: 	-F Define input field seperator as "/"
		# tr: 	-d Delete "\r" (carriage return)
		local zip_download_path="${HOME}/Downloads/${zip_name}" 

		echo "[🍺] Downloading ${zip_name}"
		if curl -L -o "${zip_download_path}" "${url}" ; then 
		# Download 
			echo "[✅] Successfully downloaded ${zip_name}"
		else
			echo "[❌] Failed to download ${zip_name}"
			exit 1
		fi

		echo "[🍺] Attempting to unzip ${zip_name}"
		if unzip -qa "${zip_download_path}" -d "${HOME}/Downloads"; then
		# Attempt to unzip the download
			echo "[✅] Successfully unzipped ${zip_name}"
		else
			echo "[❌] Failed to unzip ${zip_name}"
			exit 1
		fi	

		echo "[🍺] Attempting to validated the signature on Sublime Text.app"
		if pkgutil --check-signature "${HOME}/Downloads/Tower.app" ; then
		# Check Tower.app is correctly sogned
			echo "[✅] Successfully validated the signature on Tower.app"
		else
			echo "[❌] Failed to validate the signature on Tower.app"
			exit 1
		fi

		echo "[🍺] Attempting to copy Tower.app into /Applications"
		if mv -i "${HOME}/Downloads/Tower.app" "/Applications" ; then
		# Attempt to copy Tower.app into /Applications 
			echo "[✅] Successfully installed Tower"
		else
			echo "[❌] Failed to install Tower"
			exit 1
		fi

		# Cleanup 
		echo "[🍺] Deleting ${zip_download_path}"
		rm -r "${zip_download_path}"
		echo "[🍺] Deleting ${HOME}/Downloads/__MACOSX"
		rm -r "${HOME}/Downloads/__MACOSX"
		# Delete the downloaded ZIP file, the reosurce fork file
	else 
		echo "[🍺] Tower already installed"
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

	elif [[ "${cmd}" == "gpgtools" ]]; then 
		install_gpgtools

	elif [[ "${cmd}" == "sublimetext" ]]; then
		install_sublime_text 

	elif [[ "${cmd}" == "tower" ]]; then
		install_tower

	elif [[ "${cmd}" == "vmware" ]]; then
		change_vmware_home

	elif [[ "${cmd}" == "brew" ]]; then
		install_brew

	elif [[ "${cmd}" == "brewfile" ]]; then
		install_brewfile "${homebrew_brewfile}"

	elif [[ "${cmd}" == "eficheck" ]]; then
		check_efi_integrity

	elif [[ "${cmd}" == "hailmary" ]]; then
		# Execute all the functions
		# Order matters!
		# TODO: Manually adding new functions sucks 
		echo -e "[🍺] \033[0;31mHailmary\033[0m engaged"

		check_efi_integrity
		write_defaults
		install_gpgtools
		install_sublime_text
		install_tower
		change_vmware_home
		install_brew
		install_brewfile "${homebrew_brewfile}"

	else
		usage
	fi
}

main "$@"