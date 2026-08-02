# Primary sources

Checked on 2026-08-02.

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
documents the `:1` display, Xfce startup, DPI controls, legacy drawing, BGRA,
touch gestures, and the command used to open the Android activity.

## X publishing constraints

- [How to create a thread](https://help.x.com/en/using-x/create-a-thread)
- [Post and media limits](https://help.x.com/en/using-x/how-to-post)
- [Image descriptions](https://help.x.com/en/using-x/add-image-descriptions)
