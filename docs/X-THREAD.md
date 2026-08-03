# X tutorial thread

Recommended format: a 14-post thread. The repository is the canonical manual;
the thread gives readers the exact setup, launch command, optional Android
control bridge, and real proof from the verified phone.

The direct-X11 launcher was manually verified on the Samsung SM-S931W / Galaxy
S25 running Android 16. A completely fresh-device installation still needs
independent community verification.

## Post 1 — result

> 1/14
>
> I got the real Hermes Desktop running locally on my Galaxy S25—then let that same Hermes instance operate Android through Wireless ADB.
>
> No PC. No remote desktop. No fake web UI.
>
> Here’s the exact setup 🧵
>
> https://github.com/Dadmin88/hermes-desktop-android

**Media:** Branded cover first; clean real Hermes screenshot second.

## Post 2 — what was verified

> 2/14
>
> Verified on SM-S931W / Galaxy S25, Android 16.
>
> Hermes Desktop is the actual Linux Electron app. It renders through Termux:X11 while Hermes runs inside Ubuntu 24.04 under PRoot.
>
> Android control is a separate, optional bridge.

**Media:** Real Hermes screenshot showing the app running on the phone.

## Post 3 — architecture

> 3/14
>
> The stack:
>
> Android → Termux → Termux:X11
>
> Termux → Ubuntu 24.04 PRoot → Hermes + Electron → X11
>
> Important discovery: the working phone does NOT need Xfce. Hermes launches directly into X11. Xfce remains optional for multi-window use.

## Post 4 — prerequisites

> 4/14
>
> First install two Android apps:
>
> 1. Termux from a current official source
> 2. Termux:X11 nightly
>
> X11 APK: https://github.com/termux/termux-x11/releases/tag/nightly
>
> You need the APK plus its companion Termux package. The installer handles the package.

**Media:** Real app-drawer or installation screenshot showing both apps.

## Post 5 — install

> 5/14
>
> Open Termux—not an Ubuntu prompt—and run:
>
> `curl -fsSL https://raw.githubusercontent.com/Dadmin88/hermes-desktop-android/main/scripts/install-termux.sh | bash`
>
> Keep Termux awake and foregrounded. The first source build is substantial and will take time.

**Media:** Terminal screenshot during installation or the successful completion.

## Post 6 — what the installer builds

> 6/14
>
> The script installs X11, audio, PRoot + Ubuntu, pins the tested Hermes revision, then builds Desktop in source mode:
>
> `hermes desktop --source --build-only`
>
> No private fork or Android-specific Hermes source patch was needed.

## Post 7 — configure a model

> 7/14
>
> Configure Hermes from Termux:
>
> `proot-distro login ubuntu --shared-tmp -- hermes model`
>
> Or run the full setup wizard:
>
> `proot-distro login ubuntu --shared-tmp -- hermes setup`
>
> The community repo never reads or copies your API keys.

## Post 8 — launch

> 8/14
>
> Normal launches are now one command from Termux:
>
> `hermes-android`
>
> It starts PulseAudio + Termux:X11, opens the X11 Android activity, enters Ubuntu with shared `/tmp`, and launches the source-built Hermes Electron app directly.

**Media:** Short screen recording from the command to the working Hermes UI.

## Post 9 — touch controls

> 9/14
>
> Best phone setup:
>
> • landscape orientation
> • Termux:X11 touchpad mode
> • tap = click
> • 2-finger tap = right click
> • 2-finger swipe = scroll
> • Android Back = keyboard
> • Android Recents = return to Termux:X11

**Media:** Termux:X11 input preferences or the working touch toolbar.

## Post 10 — optional Android control

> 10/14
>
> Desktop alone does not control Android apps.
>
> For that, enable Developer options → Wireless debugging on your OWN phone. This grants powerful ADB access, so disable it when finished and never expose it to an untrusted network.

## Post 11 — pair from Ubuntu

> 11/14
>
> Enter Ubuntu and install ADB:
>
> `proot-distro login ubuntu --shared-tmp`
> `apt-get update && apt-get install -y adb`
>
> Tap “Pair device with pairing code” on Android, then run:
>
> `adb pair PHONE_IP:PAIRING_PORT`

**Media:** Real pairing-success screenshot with the temporary code hidden.

## Post 12 — connect

> 12/14
>
> Close the pairing popup but leave Wireless debugging on. Use the IP + port on its MAIN screen:
>
> `adb connect PHONE_IP:CONNECTION_PORT`
> `adb devices`
>
> Pairing port ≠ connection port. The connection port may change after a reboot or toggle.

## Post 13 — prove native control

> 13/14
>
> Safe proof commands:
>
> `adb shell input keyevent KEYCODE_HOME`
> `adb shell am start -a android.settings.SETTINGS`
>
> Hermes used that bridge to inspect the UI, press system buttons, open Settings, and launch Brave on the SAME phone running Hermes Desktop.

**Media:** Real connected-success screenshot, then native Settings/Brave proof.

## Post 14 — status and invitation

> 14/14
>
> The direct launcher + same-phone ADB control work on my Galaxy S25. The repo packages the setup, diagnostics, and troubleshooting; fresh-device installs now need wider validation.
>
> Try it, open an issue with your model + doctor reports, and help make it boringly reliable.

## Media order

1. Post 1: generated branded cover + clean real Hermes screenshot.
2. Post 2: real Hermes-on-phone proof.
3. Post 4: Termux and Termux:X11 installation proof.
4. Post 5: successful installer/launcher terminal output.
5. Post 8: short launch screen recording if available.
6. Post 11: pairing-success screenshot with temporary code hidden.
7. Post 13: connected-success screenshot plus native Settings and Brave.

Generated artwork is used only for the cover. Every technical claim is paired
with real output or a real phone screenshot.

## Alt text

### Cover

Dark charcoal and gold cover graphic. A landscape Android phone displays a
desktop-style agent interface. Large text reads “Hermes Desktop on Android”
with the subtitle “Step-by-step community guide.”

### Hermes proof screenshot

Hermes Desktop's dark green interface running full-screen through Termux:X11 on
a Samsung Galaxy S25, with the Termux:X11 touch-control toolbar visible.

### Wireless ADB proof screenshot

Hermes Desktop reports a successful Wireless ADB connection to a Samsung Galaxy
S25 running Android 16 and lists completed native Android control tests.
