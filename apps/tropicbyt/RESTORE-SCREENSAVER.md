# Restore Google TV Screensaver (sabrina)

Undo notes for pointing the Chromecast's screensaver at a custom app.
**If anything goes wrong, run the restore command below.**

## Device

| | |
|---|---|
| Device | Chromecast with Google TV 4K (`sabrina`) |
| Product | `sabrina_prod_stable` |
| Android | 14 (API 34) |
| ADB transport | Wireless (ADB-TLS / mDNS) |

## Restore command

Puts the stock Google Ambient Mode screensaver back:

```
adb shell settings put secure screensaver_components com.google.android.apps.tv.dreamx/.service.Backdrop
```

Verify it took:

```
adb shell settings get secure screensaver_components
```

Expected output:

```
com.google.android.apps.tv.dreamx/.service.Backdrop
```

## Original values (captured 2026-07-19, before any changes)

| Setting | Namespace | Original value |
|---|---|---|
| `screensaver_components` | secure | `com.google.android.apps.tv.dreamx/.service.Backdrop` |
| `screensaver_default_component` | secure | `com.google.android.apps.tv.dreamx/.service.Backdrop` |
| `screensaver_enabled` | secure | `1` |
| `screensaver_activate_on_sleep` | secure | `1` |
| `screensaver_activate_on_dock` | secure | `1` |
| `screen_off_timeout` | system | `600000` (10 min) |

Only `screensaver_components` needs changing for a custom screensaver.
Leave the others alone — `screensaver_default_component` is the system's own
record of stock and is useful as a reference.

## Full reset (restores every value above)

```
adb shell settings put secure screensaver_components com.google.android.apps.tv.dreamx/.service.Backdrop
adb shell settings put secure screensaver_default_component com.google.android.apps.tv.dreamx/.service.Backdrop
adb shell settings put secure screensaver_enabled 1
adb shell settings put secure screensaver_activate_on_sleep 1
adb shell settings put secure screensaver_activate_on_dock 1
adb shell settings put system screen_off_timeout 600000
```

## If ADB won't connect

ADB is the only reliable way to change this back, so if the connection drops:

1. **Re-enable wireless debugging** on the device — Settings > System >
   Developer options. Developer options survive reboots, so this is normally
   just a re-pair. Then `adb connect <ip>:<port>`.
2. **Try the Screensaver settings UI** — picking a Google ambient option will
   likely rewrite `screensaver_components` back to Backdrop. Probable, not
   guaranteed on Android 14. Bonus escape hatch, not the plan.
3. **Factory reset** — always works, minor hassle on a dongle.

## Current state (changed 2026-07-19)

`screensaver_components` is now:

```
com.tropicbyt.screensaver/.TropicBytDream
```

Built from `androidtv/` (`.\build.ps1 -Install`). The 4K loop is bundled in the
APK, so it needs no USB drive, network share, or internet.

**Restore the stock value BEFORE uninstalling the app** — uninstalling while it
is still the selected screensaver leaves the setting pointing at a component
that no longer exists, which means no screensaver at all:

```
adb shell settings put secure screensaver_components com.google.android.apps.tv.dreamx/.service.Backdrop
adb uninstall com.tropicbyt.screensaver
```

## Timing

| | |
|---|---|
| Screensaver starts | 10 min idle (`system/screen_off_timeout` = 600000) |
| Device sleeps | 20 min idle (`secure/sleep_timeout` = 1200000) |

Apps playing video hold a wake lock, so the screensaver will not start while
something like YouTube is in the foreground. Return to the home screen to test.

`cmd dreams start-dreaming` would force it immediately but requires root, which
a retail Chromecast does not have.

## Notes

- Google TV on Android 12+ has no UI to select a third-party screensaver, which
  is why this is set over ADB. The underlying DreamService mechanism is intact
  and unmodified.
- This changes one string in the settings DB. No root, no bootloader unlock, no
  system partition changes. Worst case is a screensaver that fails to start.
- A wrong component name fails silently — always run the `get` check after a
  `put`.
- Find a newly installed app's dream component with:
  `adb shell dumpsys package <package.name> | grep -i dream`
