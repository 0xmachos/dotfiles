# MDM Profiles (`.mobileconfig`)

* Initially based on "[Enable automatic macOS and App Store updates on macOS Catalina with a profile](https://derflounder.wordpress.com/2019/10/10/enable-automatic-macos-and-app-store-updates-on-macos-catalina-with-a-profile/)" by [Rich Trouton](https://github.com/rtrouton)
* Install logic based on "[Semi-automating profile installation in Big Sur](https://www.alansiu.net/2021/01/06/semi-automating-profile-installation-in-big-sur/)" by [aysiu](https://github.com/aysiu)
	* See: function [`open_system_preferences_mdm_profile`](https://github.com/0xmachos/dotfiles/blob/ad4adc5da7ec6b39af4d6d0ba8ba0356b1022946/bittersweet#L1009-L1025) in [`bittersweet`](https://github.com/0xmachos/dotfiles/blob/master/bittersweet)


# Documentation
* [TopLevel](https://developer.apple.com/documentation/devicemanagement/toplevel)
  * The top-level payload properties for configuring all profiles
* [CommonPayloadKeys](https://developer.apple.com/documentation/devicemanagement/commonpayloadkeys)
  * The payload properties that are common across all profiles
* [Profile-Specific Payload Keys](https://developer.apple.com/documentation/devicemanagement/profile-specific_payload_keys)

## ManagedPreferences (`mcx_preference_settings`)

* https://community.jamf.com/t5/jamf-pro/what-is-quot-the-key-to-include-is-forced-quot/m-p/287247#M257118


# Current Profiles

## `machos.dotfiles.security`

Configures settings related to security. 

### Payloads
* [`com.apple.security.firewall`](https://developer.apple.com/documentation/devicemanagement/firewall)
  * Enable firewall and enable brief level logging 
* [`com.apple.screensaver`](https://developer.apple.com/documentation/devicemanagement/screensaver)
  * Enable ask for password after 5 seconds 
* [`com.apple.systempolicy.control`](https://developer.apple.com/documentation/devicemanagement/systempolicycontrol)
  * Enable Gatekeeper and allow apps from Identified Developers 
* `com.apple.Terminal`
  * Enable Terminal Secure Keyboard Entry
* `com.apple.Safari`
  * Disable Safari Auto Open "Safe" Downloads 

## `machos.dotfiles.menubar.clock`

Configures settings related to the Menu Bar clock.

### Payload

This payload uses ManagedPreferences (`mcx_preference_settings`).

* `com.apple.menuextra.clock`
  * `IsAnalog`
    * `false`
  * `ShowDate`
    * `true`
  * `ShowDayOfWeek`
    * `true`
  * `ShowSeconds`
    * `false`
  * `FlashDateSeparators`
    * `false`
  * `ShowAMPM`
    * `false`
  * `DateFormat`
    * `EEE d MMM  HH:mm`
    * e.g. Sun 28 Apr 21:55

### Research

* `Show24Hour`
  * Does not work when set in `com.apple.menuextra.clock` domain
  * Where, if at all, can it be set?

## `machos.dotfiles.behaviour`

Configures settings related to behaviour.

### Research

#### Trackpad

* Domains
  * `com.apple.AppleMultitouchTrackpad`
  * `com.apple.driver.AppleBluetoothMultitouch.trackpad`
* `bittersweet` still sets `TrackpadThreeFingerDrag` and `Clicking` with `defaults write`.
  No source found shows a profile setting them, so they stay there.

### Payloads

This payload uses ManagedPreferences (`mcx_preference_settings`), `Forced`.

* `com.apple.finder`
  * `FXRemoveOldTrashItems` = `true` (empty the Trash after 30 days)


## `machos.dotfiles.textedit`

Configures TextEdit. TextEdit is sandboxed, so `defaults write` fails unless the
calling app has Full Disk Access. This profile sets the values through the
managed preferences layer instead, with no container access.

### Payload

This payload uses ManagedPreferences (`mcx_preference_settings`), `Forced`.
It holds one preference domain. A `com.apple.ManagedClient.preferences` payload
with several domains applies only one of them.

* `com.apple.TextEdit`
  * `RichText` = `false` (Plain Text mode for new documents)
  * `TabWidth` = `4`

`bittersweet mdmprofile` opens every `profiles/*.mobileconfig` file, so a new
profile needs no other wiring.


## `machos.dotfiles.apps`

Configures sandboxed apps (Mail and Keka). `defaults write` fails on these
unless the calling app has Full Disk Access, so the values come from managed
preferences.

### Payloads

Each payload uses ManagedPreferences (`mcx_preference_settings`), `Forced`, and
holds one preference domain.

* `com.apple.mail`
  * `PreferPlainText` = `true`
* `com.aone.keka`
  * `SUAutomaticallyUpdate` = `false` (Homebrew updates the app)
  * `RemoveIncompleteExtraction`, `ApplyQuarantineAfterExtraction`,
    `ZipUsingAES`, `ExcludeMacForks`, `VerifyCompression`, `Encryption` = `true`

`Forced` locks these values in the app's own settings window.


# Removed and not to be added

See [`to-be-managed.md`](to-be-managed.md) for settings removed from these
profiles because macOS 27 deprecated or stopped honouring the payload.


# Linting

```
plutil -lint *.mobileconfig 
```
