# Troubleshooting

Start with the two layer-aware reports in the [README](../README.md#diagnostics).
Termux and Ubuntu have separate package databases; a package visible in one
layer tells you nothing about the other.

## `Termux package check: run doctor from the Termux host`

This is expected when the doctor runs inside Ubuntu. Exit the PRoot shell and
run the same doctor command directly in Termux to inspect `termux-x11-nightly`,
`proot-distro`, `pulseaudio`, and `xfce`.

## `/dev/fd/63: No such file or directory`

The initial doctor used Bash process substitution, which depends on `/dev/fd`.
Some PRoot environments do not expose it. The current script uses a plain PID
loop and does not depend on `/dev/fd`.

## `Desktop package build: <missing>`

That alone is not an error. This project uses the source-mode build. A working
report should show both:

```text
Desktop source build   .../apps/desktop/dist/index.html
Workspace Electron     .../node_modules/electron/dist/electron
```

Rebuild missing source artifacts inside Ubuntu:

```bash
hermes desktop --source --build-only \
  --hermes-root /usr/local/lib/hermes-agent
```

## Termux:X11 opens to a black screen

Confirm the X11 server and guest use the same display number. This project uses
`:1`. Always enter Ubuntu with shared temporary storage:

```bash
termux-x11 :1 &
proot-distro login ubuntu --shared-tmp
```

Some devices need Termux:X11's legacy drawing mode:

```bash
HERMES_X11_EXTRA_ARGS=-legacy-drawing hermes-android
```

Logs:

```bash
cat "$TMPDIR/hermes-termux-x11.log"
```

The `hermes-android` launcher does not start Xfce automatically, even when Xfce
is installed. This prevents a broken optional desktop session from blocking
Hermes direct mode.

## Colors are incorrect

Try the documented BGRA compatibility flag:

```bash
HERMES_X11_EXTRA_ARGS=-force-bgra hermes-android
```

Both compatibility flags can be combined:

```bash
HERMES_X11_EXTRA_ARGS="-legacy-drawing -force-bgra" hermes-android
```

## The interface is too small or too large

The launcher defaults to 120 DPI. Override it per launch:

```bash
HERMES_X11_DPI=144 hermes-android
```

You can also adjust font DPI in Xfce's Appearance settings.

## Touch feels like a mouse, or dragging is difficult

Termux:X11 has two input modes:

- **Touchpad mode:** move a pointer; usually best for Hermes Desktop.
- **Simulated touchscreen mode:** direct touch positions; long-press and move to
  drag.

In touchpad mode: tap clicks, two-finger tap right-clicks, and two-finger swipe
scrolls. Press Android Back to toggle the on-screen keyboard.

## Hermes disappeared after it was minimized

Hermes is a Linux window inside the Termux:X11 Android activity. In verified
direct mode, restore **Termux:X11** from Android Recents. If the Electron process
was closed, return to Termux and run `hermes-android` again.

With optional Xfce installed, use its panel or `Alt+Tab` for Linux windows.

## Hermes says a browser opened, but no browser is visible

The launcher enables headed mode and sets the root-compatible Chromium flags
automatically:

```bash
AGENT_BROWSER_HEADED=1
AGENT_BROWSER_ARGS=--no-sandbox,--disable-dev-shm-usage
```

Run the Ubuntu doctor and look for an `agent-browser` command or cached Chromium
runtime. A global `chromium` executable is not required; agent-browser may use a
downloaded Playwright browser.

Direct mode has no Linux window switcher. Install optional Xfce if you need to
manage Hermes and a headed Linux browser as separate windows. A native Android
browser launched through Wireless ADB is different and appears in Android
Recents; see [Wireless ADB](WIRELESS-ADB.md).

## Electron refuses to run as root

The guest runs as root, so the launcher calls workspace Electron with
`--no-sandbox`. Do not replace the project launcher with a bare `electron .`
command unless you add the same compatibility flag.

This weakens Electron/Chromium process isolation. It is not a security feature.

## `npm` reports `EBADENGINE`

The verified Hermes revision requires Node `>=22.22.0` and an npm version that
is not in the excluded 11.10–11.16 range. The working phone used:

```text
Node  v22.23.1
npm   10.9.8
```

Check the active Ubuntu runtime:

```bash
node --version
npm --version
```

Use the pinned installer instead of bypassing `engine-strict`.

## `Python: <missing>` but `hermes version` reports Python 3.11

This is expected with the managed root installation. A global `python` command
is not required; the Hermes launcher uses its managed Python environment.

## `package-lock.json` is dirty

`npm ci` or the Desktop build may produce lockfile churn in the checkout. The
working phone showed only:

```text
M package-lock.json
```

Do not discard it blindly if you intentionally edited package manifests. If
`package.json` files are clean and this is only generated churn, compare it
before restoring:

```bash
git -C /usr/local/lib/hermes-agent diff --stat
git -C /usr/local/lib/hermes-agent diff -- package-lock.json
```

## Audio is unavailable

The host launcher starts Termux PulseAudio and exposes a loopback-only native
protocol module. Confirm both processes from Termux:

```bash
pgrep -a pulseaudio
pactl list short modules | grep module-native-protocol-tcp
```

Inside Ubuntu, confirm:

```bash
printf '%s\n' "$PULSE_SERVER"
```

It should print `127.0.0.1`.

## Android kills or slows the session

Keep Termux and Termux:X11 exempt from aggressive battery optimization while
testing. The upstream Termux:X11 project also documents a `sharedUid` APK that
can reduce background CPU throttling, but it has strict APK signing/source
requirements. Follow upstream instructions rather than mixing APK builds.

## Before opening an issue

Include:

1. Phone model and Android version.
2. The doctor output from the Termux host.
3. The doctor output from the Ubuntu guest.
4. Whether this was a fresh install or an existing Hermes setup.
5. The relevant X11/Xfce or Hermes Desktop log—not credentials or `.env` files.
