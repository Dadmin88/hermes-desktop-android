# How the Android stack works

Hermes Desktop is an Electron application. Android does not run that Linux
binary as a native APK, so the working setup supplies each desktop assumption
at a separate layer.

```mermaid
flowchart TB
    A["Android phone"] --> B["Termux host"]
    B --> C["Termux:X11 + Xfce"]
    B --> D["Ubuntu PRoot guest"]
    D --> E["Hermes backend"]
    D --> F["Hermes Desktop / Electron"]
    F --> C
    E <--> F
```

## Layer ownership

| Layer | Owns |
|---|---|
| Android | App lifecycle, touch input, hardware, Android permissions |
| Termux | X11 server companion, Xfce, PulseAudio, PRoot launcher |
| Ubuntu PRoot | glibc Linux environment, Hermes, Node, Electron dependencies |
| Hermes Desktop | Electron renderer, local backend, projects, sessions, tools |

Xfce is intentionally Termux-native in the verified stack. The Ubuntu doctor
correctly reports no guest `xfce4` package because Ubuntu contributes the app,
not the desktop shell.

## Source-mode Desktop

`hermes desktop --source --build-only` creates the renderer and Electron main
bundle under `apps/desktop/dist`. The launcher then calls the workspace Electron
binary directly with the Hermes desktop directory as its app target.

This is why a correct working report can show:

- a source build present;
- a workspace Electron runtime present; and
- a packaged `apps/desktop/release` build absent.

## Consequences

- The interface is the real Hermes Desktop UI.
- Hermes data and configuration stay in the Ubuntu Hermes installation.
- Linux browser windows appear beside Hermes through the same X11 display.
- Android sees Termux:X11 as the visible Android app; individual Linux windows
  do not appear as separate Android recent-app cards.
- Android still isolates Termux from other Android apps and privileged system
  APIs. Device control requires a separate, explicitly permissioned bridge.

## Security boundary

The Ubuntu PRoot guest runs as root for convenience, while Android still
sandboxes Termux as an unprivileged Android application. Electron and the local
browser require `--no-sandbox` in that guest. Losing Chromium's own sandbox is a
real reduction in defense-in-depth even though Android and Termux boundaries
remain. Run only trusted code and browse with appropriate caution.
