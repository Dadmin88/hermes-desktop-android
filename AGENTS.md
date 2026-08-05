# Repository guidance

This repository owns the Android compatibility layer for running Hermes Desktop through Termux, Termux:X11, and an Ubuntu PRoot guest. It is not an official Nous Research Android port.

## Project boundary

- Keep Android-specific launchers, installers, diagnostics, documentation, and tests in this repository.
- Do not open upstream PRs against `NousResearch/hermes-agent` for this compatibility workflow unless the repository owner explicitly changes that policy.
- Do not require Android-specific patches to the pinned Hermes source checkout when the compatibility layer can solve the issue externally.

## Runtime layers

Treat these as separate environments:

1. **Termux host:** installs Android-side packages, starts PulseAudio and Termux:X11, and runs `hermes-android` or `hermes-ubuntu`.
2. **Ubuntu PRoot guest:** owns `/usr/local/lib/hermes-agent`, Linux Node.js/npm, the Desktop source build, workspace Electron, and `hermes-android-session`.
3. **Termux:X11:** displays the Linux GUI; it is not the shell where dependencies are built.

Never run `hermes desktop --source --build-only`, `npm ci`, or other Desktop workspace dependency installation directly in Termux. Android-native dependency detection can make `node-pty` attempt an unsupported NDK rebuild. Build Desktop only inside the Ubuntu PRoot guest.

## Missing Electron runtime recovery

From the Termux host:

```bash
hermes-ubuntu
hermes desktop --source --build-only --force-build \
  --hermes-root /usr/local/lib/hermes-agent
exit
hermes-android
```

The build command must execute inside Ubuntu. The final launcher command must execute back in Termux.

## Change discipline

- Preserve the pinned Hermes commit and immutable release-script behavior.
- Keep host and guest instructions visibly labeled in scripts, errors, tests, and documentation.
- Do not suggest a bare guest-only command in an error that returns users to the Termux prompt; include the layer transition.
- Keep credentials, Hermes user data, sessions, and configuration outside release artifacts and diagnostics.

## Validation

Run the repository check bundle after behavior or documentation changes:

```bash
bash tests/run.sh
```

For layer-boundary changes, also confirm that dry-run output and launcher error messages tell users exactly which shell should execute each command.
