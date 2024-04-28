# MDM Profiles (`.mobileconfig`)

* Initially based on "[Enable automatic macOS and App Store updates on macOS Catalina with a profile](https://derflounder.wordpress.com/2019/10/10/enable-automatic-macos-and-app-store-updates-on-macos-catalina-with-a-profile/)" by [Rich Trouton](https://github.com/rtrouton)
* Install logic based on "[Semi-automating profile installation in Big Sur](https://www.alansiu.net/2021/01/06/semi-automating-profile-installation-in-big-sur/)" by [aysiu](https://github.com/aysiu)
	* See: function [`open_system_prefernces_mdm_profile`](https://github.com/0xmachos/dotfiles/blob/ad4adc5da7ec6b39af4d6d0ba8ba0356b1022946/bittersweet#L1009-L1025) in [`bittersweet`](https://github.com/0xmachos/dotfiles/blob/master/bittersweet)

# Documentation
* [TopLevel](https://developer.apple.com/documentation/devicemanagement/toplevel)
  * The top-level payload properties for configuring all profiles
* [CommonPayloadKeys](https://developer.apple.com/documentation/devicemanagement/commonpayloadkeys)
  * The payload properties that are common across all profiles
* [Profile-Specific Payload Keys](https://developer.apple.com/documentation/devicemanagement/profile-specific_payload_keys)

# Current Profiles

## `machos.dotfiles.security`

Configures settings related to security. 

### Payloads
* [`com.apple.SoftwareUpdate`](https://developer.apple.com/documentation/devicemanagement/softwareupdate)
  * Enable all automatic updates
  * Disable beta installation
  * Allow Normal users to install updates
* [`com.apple.security.firewall`](https://developer.apple.com/documentation/devicemanagement/firewall)
  * Enable firewall and enable brief level logging 
* [`com.apple.screensaver`](https://developer.apple.com/documentation/devicemanagement/screensaver)
  * Enable ask for password after 5 seconds 
* [`com.apple.systempolicy.control`](https://developer.apple.com/documentation/devicemanagement/systempolicycontrol)
  * Enable Gatekeeper and allow apps from Identified Developers 
* `com.apple.terminal`
  * Enable Terminal Secure Keyboard Entry
* `com.apple.Safari`
  * Disable Safari Auto Open "Safe" Downloads 

## `machos.dotfiles.menubar.clock`

Configures settings related to the Menu Bar clock.

### Payload

This payload uses ManagedPreferences (`mcx_preference_settings`).

* `com.apple.menuextra.clock`
  * `IsAnalog`
    * 
  * `ShowDate`
    * 
  * `ShowDayOfWeek`
    * 
  * `ShowSeconds`
    * 
  * `FlashDateSeparators`
    * 
  * `ShowAMPM`
    * 
  * `DateFormat`
    * `EEE d MMM  HH:mm`
    * e.g. Sun 28 Apr 21:55

### Research

* `Show24Hour`
  * Does not work when set in `com.apple.menuextra.clock` domain
  * Where, if at all, can it be set?

## `machos.dotfiles.behaviour`

Configures settings related to behaviour.

### Payloads
* `com.apple.AppleMultitouchTrackpad`
  * Enable Three Finger Drag


