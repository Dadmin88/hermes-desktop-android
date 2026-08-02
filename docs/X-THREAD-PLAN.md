# X thread plan

The repository is the canonical instruction manual. The X thread is the guided
tour that proves the result, explains the architecture, and sends readers to
the versioned commands.

## Recommended format

Use a thread instead of one long post. Each technical phase gets one post and
one matching screenshot, while corrections can be made by updating the repo
without invalidating the entire thread.

## Sequence

1. **Result first** — real video or screenshot of Hermes Desktop running on the
   Galaxy S25; state clearly that this is the Linux Electron app, not an APK.
2. **Architecture** — Android → Termux → Linux environment → Termux:X11 →
   Hermes Desktop.
3. **Install Android prerequisites** — Termux source, Termux:X11 APK, battery and
   notification permissions that were actually required.
4. **Prepare Termux** — repositories and packages, exactly as tested.
5. **Create the Linux environment** — distribution, architecture, shared temp,
   and display setup, exactly as tested.
6. **Install the compatible runtime** — pinned Node, npm, Python, and system
   libraries.
7. **Install/build Hermes** — pinned upstream revision and commands.
8. **Launch it** — one repeatable launcher command or script from this repo.
9. **Make it usable on a phone** — landscape orientation, DPI, touchpad mode,
   Xfce panel/window switching, and keyboard.
10. **Visible browser** — headed Chromium setup and the security tradeoff if
    `--no-sandbox` is required.
11. **Failures and fixes** — engine mismatch, odd desktop UI, drag behavior,
    minimized windows, and hidden browser windows.
12. **Fork and reproduce** — repo link, tested versions, diagnostics command,
    and a request for device reports or pull requests.

## Required proof media

- A short screen recording opening Hermes and completing one small task
- A clean final Hermes Desktop screenshot
- A screenshot with Hermes and the visible browser window
- The original npm engine error, if still available
- Optional photo of the phone to make the Android hardware unmistakable

Generated artwork should be used only as the thread cover. Technical steps
should use real screenshots so readers can compare their setup with the tested
device.

## Cover alt text

Dark charcoal and gold cover graphic. A landscape Android phone displays a
desktop-style Hermes interface. Large text reads “Hermes Desktop on Android”
with the subtitle “Step-by-step community guide.”
