# Primary sources

Checked on 2026-08-03.

## Hermes Agent

- [Official Android/Termux guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/getting-started/termux.md)
- [Official installation guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/getting-started/installation.md)
- [Official Desktop guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/desktop.md)
- [Official browser automation guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/browser.md)
- [Known-working source revision](https://github.com/NousResearch/hermes-agent/commit/c2ff2e8b17f5dd0460aa020aaa21deb59d7fe15f)
- [Hermes Agent repository](https://github.com/NousResearch/hermes-agent)

Hermes officially documents its Android CLI path. The source revision above
contains no Android-specific Desktop patch; this repository supplies the X11,
PRoot, launch, and diagnostics layer around upstream Hermes.

## Termux and PRoot

- [Termux application](https://github.com/termux/termux-app)
- [Termux:X11 setup](https://github.com/termux/termux-x11)
- [Termux:X11 nightly APKs](https://github.com/termux/termux-x11/releases/tag/nightly)
- [PRoot Distro](https://github.com/termux/proot-distro)

Termux:X11 upstream requires both the Android APK and companion Termux package.
Its PRoot instructions require `proot-distro login ... --shared-tmp`. It also
documents the `:1` display, Xfce components, DPI controls, legacy drawing,
BGRA, touch gestures, and the command used to open the Android activity. This
project starts only `xfwm4`, not a full Xfce desktop session.

## Android Wireless ADB

- [Android Debug Bridge](https://developer.android.com/tools/adb)
- [Run apps on a hardware device](https://developer.android.com/studio/run/device)
- [Configure on-device developer options](https://developer.android.com/studio/debug/dev-options)

Android documents pairing-code Wireless debugging on Android 11 and newer. The
temporary pairing port and normal connection port are separate values. This
repository treats ADB as an optional, explicitly authorized bridge rather than
part of the Hermes Desktop display stack.
