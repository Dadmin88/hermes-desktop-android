# Changelog

All notable changes to this project are documented here.

## v0.1.1 — 2026-08-03

Second-device compatibility release.

### Fixed

- Install Electron runtime packages `libnspr4`, `libnss3`, and `libgl1` in the
  Ubuntu PRoot guest before first launch.
- Report all required Electron runtime packages in the layer-aware doctor.

### Verification boundary

The full install and real Hermes Desktop GUI were manually verified on a second
physical device: Samsung Galaxy Tab S6 Lite (`SM-P620`), Android 16 / API 36,
with Ubuntu 26.04 LTS under PRoot Distro. The first launch exposed the missing
runtime packages fixed by this release. This remains a two-device compatibility
result, not a claim of broad Android support.

## v0.1.0 — 2026-08-03

First versioned public release of the Android compatibility workflow.

### Included

- Two-stage Termux host and Ubuntu PRoot installer
- Termux:X11 direct display mode with standalone `xfwm4`
- Source-built Hermes Desktop launcher pinned to the verified Hermes revision
  `c2ff2e8b17f5dd0460aa020aaa21deb59d7fe15f`
- Layer-aware diagnostics and troubleshooting documentation
- Transactional launcher downloads and failure-preservation tests
- Checksum-verified release assets whose nested project downloads pin the exact
  release commit SHA
- GitHub Actions ShellCheck and regression-test workflow
- Structured Android device compatibility report

### Verification boundary

The runtime workflow was manually verified on a Samsung Galaxy S25 running
Android 16. This release does not claim broad Android compatibility or an
independent clean-device reproduction.
