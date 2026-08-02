# X tutorial thread

Recommended format: a thread, not one long post. The repository is the
canonical manual; the thread gives readers the working mental model, exact
entry commands, and visual proof.

Do not publish until the final launch wrapper has been run once on the working
phone. The manual stack is proven; the one-command automation is newly packaged.

## Post 1 — result

> 1/13
>
> I got the real Hermes Desktop running on my Galaxy S25—with Xfce, touch controls, and a visible headed browser.
>
> Not an APK. Not remote desktop. The Linux Electron app bridged onto Android.
>
> Guide + scripts: https://github.com/Dadmin88/hermes-desktop-android

**Media:** Use the branded cover first. Add the cleanest real Hermes screenshot
as the second image if available.

## Post 2 — architecture

> 2/13
>
> The stack:
>
> Android
>
> → Termux
>
> → Termux:X11 + native Xfce
>
> → Ubuntu 24.04 under PRoot
>
> → Hermes Agent + Electron
>
> Xfce stays in Termux. Hermes runs inside Ubuntu and renders onto the same `:1` X11 display.

**Media:** Architecture graphic or a labeled screenshot of the Xfce desktop.

## Post 3 — prerequisites

> 3/13
>
> First, install both Android apps:
>
> 1. Termux
>
> 2. Termux:X11 nightly
>
> X11 APK: https://github.com/termux/termux-x11/releases/tag/nightly
>
> You need the Android APK *and* its companion Termux package. The installer handles the companion package.

**Media:** Real Android app-drawer screenshot showing Termux and Termux:X11.

## Post 4 — install

> 4/13
>
> Open Termux—not an Ubuntu prompt—and run:
>
> `curl -fsSL https://raw.githubusercontent.com/Dadmin88/hermes-desktop-android/main/scripts/install-termux.sh | bash`
>
> It sets up X11, Xfce, audio, Ubuntu, Hermes, and the launchers. The first build takes a while.

**Media:** Terminal screenshot during the successful install/build.

## Post 5 — reproducible Hermes build

> 5/13
>
> The script pins the tested Hermes revision and builds Desktop in source mode:
>
> `hermes desktop --source --build-only`
>
> Important discovery: no private fork or Android-specific Hermes source patch was needed. The Android compatibility belongs in the launcher layer.

## Post 6 — configure Hermes

> 6/13
>
> Configure your model from Termux:
>
> `proot-distro login ubuntu --shared-tmp -- hermes model`
>
> Or run the full wizard:
>
> `proot-distro login ubuntu --shared-tmp -- hermes setup`
>
> The repo never reads or copies your Hermes keys.

## Post 7 — launch

> 7/13
>
> Normal launches are one command:
>
> `hermes-android`
>
> It starts audio + X11, opens Termux:X11, starts Xfce, enters Ubuntu with shared `/tmp`, then launches the real Hermes Electron UI.

**Media:** Short real screen recording: run the command, switch into X11, show
Hermes ready.

## Post 8 — why source mode

> 8/13
>
> Why source mode?
>
> The working phone has the Desktop renderer and workspace Electron, but no packaged AppImage/deb under `apps/desktop/release`.
>
> That’s intentional. Packaging adds another failure-prone layer and buys us nothing on the phone.

## Post 9 — touch controls

> 9/13
>
> Best phone settings:
>
> • landscape orientation
>
> • Termux:X11 touchpad mode
>
> • tap = click
>
> • 2-finger tap = right click
>
> • 2-finger swipe = scroll
>
> • Android Back = keyboard
>
> • Xfce panel / Alt+Tab = switch Linux windows

**Media:** Screenshot of the Termux:X11 input preference screen.

## Post 10 — visible browser

> 10/13
>
> For a visible local browser, the launcher enables headed mode and the root-compatible Chromium flags.
>
> If Hermes says “browser opened” but you can’t see it, use the Xfce taskbar or Alt+Tab. It’s a Linux window—not a separate Android recent-app card.

**Media:** Real screenshot showing Hermes and the browser as separate Xfce
windows.

## Post 11 — device-specific fixes

> 11/13
>
> Device-specific fixes are built in:
>
> `HERMES_X11_DPI=144 hermes-android`
>
> `HERMES_X11_EXTRA_ARGS=-legacy-drawing hermes-android`
>
> For swapped colors, use `-force-bgra`. Full troubleshooting is in the repo.

## Post 12 — verify both layers

> 12/13
>
> The doctor now understands both environments.
>
> Run it in Termux and Ubuntu. It reports host X11/packages and guest Hermes/Electron—without reading keys, `.env`, sessions, or chats.
>
> Commands: https://github.com/Dadmin88/hermes-desktop-android#diagnostics

## Post 13 — honest status and invitation

> 13/13
>
> The manual stack works on my Galaxy S25. The repo packages it into tested scripts; fresh-device installs now need wider validation.
>
> If you reproduce it, open an issue with your phone model + both doctor reports. Let’s make this boringly reliable.

## Media checklist

- Branded cover: `assets/social/hermes-desktop-on-android-cover.png`
- Clean Hermes Desktop screenshot
- Termux + Termux:X11 app screenshot
- Successful install/build screenshot
- Short launch screen recording
- Termux:X11 input preferences screenshot
- Hermes + visible browser screenshot

Generated artwork should be used only for the cover. Technical proof should be
real so readers can compare their setup with the tested device.

## Cover alt text

Dark charcoal and gold cover graphic. A landscape Android phone displays a
desktop-style Hermes interface. Large text reads “Hermes Desktop on Android”
with the subtitle “Step-by-step community guide.”
