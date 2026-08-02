# Troubleshooting

This page collects the failures encountered while bringing Hermes Desktop up
on Android, plus fixes documented by the upstream projects. Commands that
depend on the final tested environment will be pinned after the working device
report is captured.

## Termux:X11 opens to a black screen

Make sure the X11 server and the Linux session use the same display number.
The common upstream example uses `:1`:

```bash
# In Termux
termux-x11 :1 &

# In the Linux environment
export DISPLAY=:1
```

If Xfce still renders a black screen, Termux:X11 documents a legacy drawing
mode:

```bash
termux-x11 :1 -legacy-drawing &
```

## Colors are incorrect

Some devices need Termux:X11's BGRA compatibility flag:

```bash
termux-x11 :1 -force-bgra &
```

## The interface is too small or too large

Set the server DPI at launch, then adjust Xfce's font DPI if necessary:

```bash
termux-x11 :1 -dpi 120 &
```

Treat `120` as a starting point. The right value depends on the phone's screen,
Android display scaling, and whether the phone is in portrait or landscape.

## Touch feels like a mouse, or dragging is difficult

Termux:X11 exposes two relevant input modes in its preferences:

- **Touchpad mode** moves a pointer and is usually easier for desktop controls.
- **Simulated touchscreen mode** sends direct touch positions; a long press can
  be used for drag-and-drop.

For Hermes Desktop, touchpad mode is generally the less surprising default.
Use Android's back gesture to show Termux:X11's preferences and keyboard
controls.

## Hermes disappeared after it was minimized

Hermes is a normal Linux desktop window inside the X11 session. It is not a
separate Android task. Restore it from the Xfce panel's window buttons or use
`Alt+Tab` inside Termux:X11.

The same applies to browser windows opened by Hermes: switch windows through
Xfce rather than Android's recent-apps screen.

## The browser runs, but no window is visible

First check whether the Chromium window is behind Hermes with Xfce's taskbar or
`Alt+Tab`. A headed browser also needs a reachable `DISPLAY` in the environment
where Hermes is running.

Hermes documents `--no-sandbox` as a compatibility option for constrained
Linux environments:

```bash
export AGENT_BROWSER_ARGS=--no-sandbox
```

Only use that flag in an environment you trust. Disabling Chromium's sandbox
reduces process isolation.

## `npm` reports an unsupported engine

Do not bypass the engine check until you know which Node and npm versions are
running:

```bash
node --version
npm --version
```

Hermes Desktop's requirements can change between releases. The final guide
will pin the exact known-working Hermes revision, Node release, and npm release
instead of relying on whatever happens to be newest on install day.

## The Electron sandbox refuses to start

Hermes Desktop has a Linux compatibility setting for environments where the
Electron sandbox cannot be configured:

```yaml
desktop:
  electron_flags:
    - --no-sandbox
```

This is a compatibility workaround, not a security improvement. The finished
launcher will use it only if the tested Android environment actually requires
it.

## Before reporting a problem

Run the diagnostics script from the repository and include its output:

```bash
bash scripts/doctor.sh
```

The script intentionally omits credentials, `.env` files, Hermes sessions, and
chat contents.
