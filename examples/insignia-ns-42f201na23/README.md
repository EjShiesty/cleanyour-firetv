# Conservative Insignia F20 Fire TV setup

This records one tested **NS-42F201NA23** (internal `AFTALMO`) on **Fire OS 7.7.1.7 (PS7717/5741)**. It kept Netflix, Apple TV, Disney+, YouTube, Prime Video, Alexa, phone casting, AirPlay, Live TV, HDMI, Appstore, and updates. Seven promotional or analytics packages were disabled. My Home opened after a reboot using the Fire OS accessibility redirect. The stock Amazon launcher remained enabled. Playback, picture, volume, and the physical Home button were confirmed on the TV. Amazon Home flashes briefly before My Home. HDMI and casting were not physically retested.

This is a device report, not a universal Fire TV list. Recheck the installed package, firmware, permissions, and owner's feature choices on **each** TV. The broader `amazon-fire-tv-aftalmo` list and `firetv/install.sh` would disable or install things that were intentionally kept here. Do not run them to reproduce this setup.

## Windows setup

Use PowerShell 7, official Android Platform Tools, JDK 17, Android SDK platform 34 and build-tools 34.0.0. Put `adb` on `PATH` (or use its full path in every command and pass `-AdbPath` to the baseline script). Set `JAVA_HOME` to the JDK 17 directory and `ANDROID_HOME` to the SDK directory before building. Replace the placeholder with only the TV you own or are authorized to manage. Turn on ADB Debugging on that TV and approve the computer prompt.

```powershell
$target = '<TV_IP>:5555'
adb connect $target
adb -s $target shell getprop ro.product.oemmodel
adb -s $target shell getprop ro.build.version.name
```

Verify `INSIGNIA_NS-42F201NA23` and `Fire OS 7.7.1.7 (PS7717/5741)` for this exact profile. On another model or build, create a separate profile after inspecting it. Do not carry this list across blindly.

Before changes, capture a private baseline. The command below fails if the connected TV's identity differs. Its `backup/` output is Git ignored and can contain account, network, and device details; never commit it.

```powershell
& .\tools\collect-baseline.ps1 -Device $target `
  -ExpectedModel 'INSIGNIA_NS-42F201NA23' `
  -ExpectedBuild 'Fire OS 7.7.1.7 (PS7717/5741)'
```

The repo's Windows disable and restore tools use a Python virtual environment. Set it up once:

```powershell
python -m venv tools\venv
& .\tools\venv\Scripts\python.exe -m pip install -r tools\requirements.txt
```

Review the seven lines in [debloat.txt](debloat.txt) against `adb shell pm list packages`, `adb shell dumpsys package <package>`, and your preferences. In particular, preserve any package requesting `android.permission.TV_INPUT_HARDWARE`, and leave the stock Home and firmware update paths enabled. Apply **one package at a time** with the existing recovery tool, checking Home, Wi-Fi, settings, and streaming between changes:

```powershell
$list = 'examples\insignia-ns-42f201na23\debloat.txt'
& .\tools\disable.ps1 -TvHost '<TV_IP>' -OnlyPackage 'com.amazon.sneakpeek' $list
```

Repeat with only the other packages you have actually reviewed. `tools/disable.ps1` saves the pre-change states through `tools/recovery.py` before touching the TV. Keep its recovery record under your user profile (`.cleanyourtv/`) and the same list path for restoration. Confirm each package in `adb -s $target shell pm list packages -d`. If a change causes trouble, re-enable that package immediately with `adb -s $target shell pm enable --user 0 <package>` and stop the batch.

## My Home and theme

The launcher configuration in this branch has this owner's five-app dock and a full-card YouTube TV banner. Missing dock apps are skipped. Build and install only the launcher; the full Fire TV installer also installs Cinejoy and applies a much broader debloat list.

```powershell
Push-Location launcher
.\gradlew.bat --no-daemon testReleaseUnitTest lintRelease assembleRelease
Pop-Location
adb -s $target install -r launcher\app\build\outputs\apk\release\app-release.apk
adb -s $target shell am start -W -n com.gathin.tvhome/.MainActivity
```

Try remote navigation and app launches before enabling Home redirect. Apply the included static wallpaper and dock theme (the launcher retains its normal focus animation):

```powershell
& .\tools\theme.ps1 -TvHost '<TV_IP>' 'examples\insignia-ns-42f201na23\theme'
```

On the tested TV, no accessibility service was enabled beforehand. After confirming that with `adb -s $target shell settings get secure enabled_accessibility_services`, the supported redirect was enabled with:

```powershell
adb -s $target shell pm grant com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS
adb -s $target shell settings put secure enabled_accessibility_services com.gathin.tvhome/.HomeRedirectService
adb -s $target shell settings put secure accessibility_enabled 1
```

The grant enables My Home's on-TV **Use Amazon Home Screen** switch. On a TV with existing accessibility services, preserve them and enable this service through the TV's Accessibility settings or merge the service list deliberately; the `settings put` line above would replace it. The redirect is experimental outside this verified firmware. The original Amazon Home must stay enabled. Test Home from inside an app and after a reboot. If it fails, turn the redirect off and use Amazon Home.

Optional AdGuard Private DNS was compatible with the tested TV and streaming apps. Record the original `global/private_dns_mode` and `global/private_dns_specifier` values first. This TV had neither set:

```powershell
adb -s $target shell settings put global private_dns_specifier dns.adguard-dns.com
adb -s $target shell settings put global private_dns_mode hostname
```

Check `dumpsys connectivity` for a validated connection and test playback. Domain-based filtering cannot remove every ad, including ads embedded in the video service's own delivery path.

## Recovery and finishing

On the TV, hold OK on My Home's Settings pill and choose **Use Amazon Home Screen** for a quick return. For package restoration, keep the same `debloat.txt` path and recovery record, then use `tools/restore.ps1 -TvHost '<TV_IP>' -Stock com.amazon.tv.launcher $list`. **Check that the recovery record exists first**: the generic restore tool otherwise falls back to enabling the whole list and resetting settings to defaults. The tested TV's original Private DNS entries and enabled accessibility service list were absent, and `accessibility_enabled` was `0`. These commands restore those exact original settings; use the saved values on a different TV:

```powershell
adb -s $target shell settings delete secure enabled_accessibility_services
adb -s $target shell settings put secure accessibility_enabled 0
adb -s $target shell settings delete global private_dns_mode
adb -s $target shell settings delete global private_dns_specifier
adb -s $target shell pm revoke com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS
# Optional, only if removing My Home entirely:
adb -s $target shell pm uninstall com.gathin.tvhome
```

The private per-device restore script made during this session remains outside Git.

Reboot, check Home, Wi-Fi, settings, Appstore, playback, and any TV features the owner uses. Turn off ADB Debugging when finished. `python -I tools/adb-closed.py <TV_IP>` should report that port 5555 **refused** the connection; a timeout alone does not prove the TV is still reachable.

On the tested TV, `/data` available space was 817,868 KiB before and 862,500 KiB at the final capture. The 44,632 KiB difference is a point-in-time measure and may include normal cache churn. No user app or app data was removed.
