# To be managed

Settings removed from the profiles because macOS 27 deprecated or stopped
honouring the way they were set. Each entry names the replacement and what it
needs. Re-add a setting only through the replacement.

Source: Apple, "What's new for enterprise in macOS Golden Gate 27"
(support.apple.com/en-us/148830), "WWDC26 device management updates"
(support.apple.com/guide/deployment/depd638aa061) and the `SoftwareUpdate`
payload page (developer.apple.com/documentation/devicemanagement/softwareupdate).
Read 2026-10-13.

## Automatic software updates

Removed from `machos.dotfiles.security` on 2026-10-13: the whole
`com.apple.SoftwareUpdate` payload (`com.machos.dotfiles.SoftwareUpdate`).

| Key | Value we set |
| --- | --- |
| `AutomaticCheckEnabled` | `true` |
| `AutomaticDownload` | `true` |
| `AutomaticallyInstallMacOSUpdates` | `true` |
| `AutomaticallyInstallAppUpdates` | `true` |
| `ConfigDataInstall` | `true` |
| `CriticalUpdateInstall` | `true` |
| `AllowPreReleaseInstallation` | `false` |
| `restrict-software-update-require-admin-to-install` | `false` |

* Apple marks the payload deprecated from macOS 26.0.
* Apple states that legacy software update management no longer functions in
  any 27.0 operating system. The list names commands, queries, recommended
  cadence settings and restrictions such as deferrals. It does not name these
  keys one by one, so whether each key still takes effect on 27 is not proven.
* Replacement: the Software Update settings declarative configuration.
  A declaration needs a device management service. A profile installed by hand
  cannot deliver it.
* Set these in System Settings > General > Software Update.

## Do not add: deprecated in macOS 27

None of these is in use here. Do not add them.

| Payload or key | Replacement |
| --- | --- |
| `com.apple.AssetCache.managed` | `com.apple.configuration.content-cache.settings` |
| `com.apple.applicationaccess.new` (app launch rules) | `com.apple.configuration.app.settings` |
| Accessibility key in `com.apple.TCC.configuration-profile-policy` (removed in 27) | `Privacy` key in `com.apple.configuration.app.settings` |
| Other keys in `com.apple.TCC.configuration-profile-policy` | `Privacy` key in `com.apple.configuration.app.settings` |

The replacements need a supervised Mac and a device management service.
