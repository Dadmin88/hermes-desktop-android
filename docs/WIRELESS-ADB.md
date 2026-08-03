# Optional Wireless ADB bridge

Hermes Desktop and Android control are separate. Termux:X11 displays the Linux
Electron app; Wireless ADB gives an explicitly authorized process inside Ubuntu
access to Android's debugging interface.

The bridge was verified on a Samsung SM-S931W / Galaxy S25 running Android 16.
Android 11 or newer is required for pairing-code Wireless debugging.

> [!WARNING]
> ADB can inspect the screen, launch apps, enter text, install software, and
> change device state. Use this only on a phone you own and trust. Keep Wireless
> debugging disabled when you do not need it, and do not expose ADB to an
> untrusted network.

## 1. Enable Wireless debugging

On the phone:

1. Open **Settings → About phone → Software information**.
2. Tap **Build number** seven times and authenticate to enable Developer
   options.
3. Open **Settings → Developer options**. On some Android builds this is under
   **System**.
4. Enable **Wireless debugging** and approve the network prompt.

Keep this screen open. Android displays the phone's current **IP address &
port**. That is the connection endpoint used after pairing.

## 2. Install ADB inside Ubuntu

From Termux, enter the same Ubuntu guest that runs Hermes:

```bash
proot-distro login ubuntu --shared-tmp
```

Then install ADB:

```bash
apt-get update
apt-get install -y adb
adb version
```

## 3. Pair once

On the Wireless debugging screen, tap **Pair device with pairing code**. Android
shows a temporary pairing code plus a pairing IP address and port.

Inside Ubuntu, run:

```bash
adb pair PHONE_IP:PAIRING_PORT
```

Enter the six-digit code when prompted. A successful response says the device
was paired. The authorization normally survives later reconnects.

Do not confuse the temporary pairing port with the normal connection port.
They are usually different.

## 4. Connect

Close the pairing-code popup but leave Wireless debugging enabled. Read the
main screen's **IP address & port**, then run:

```bash
adb connect PHONE_IP:CONNECTION_PORT
adb devices
```

The device should appear with state `device`. If several devices are listed,
target this one explicitly with `adb -s PHONE_IP:CONNECTION_PORT ...`.

The connection port can change after a reboot, Wi-Fi change, or toggling
Wireless debugging. Pairing usually remains saved, so reconnect with the new
main-screen port before trying another pairing code.

## 5. Prove the connection safely

These read-only commands confirm the target:

```bash
adb shell getprop ro.product.manufacturer
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell wm size
```

Then test visible native-Android control:

```bash
# Return to the Android home screen.
adb shell input keyevent KEYCODE_HOME

# Open Android Settings.
adb shell am start -a android.settings.SETTINGS

# Launch Brave without relying on a version-specific activity name.
adb shell monkey -p com.brave.browser \
  -c android.intent.category.LAUNCHER 1
```

Hermes can run these same commands through its terminal tool after you tell it
which connected device it may operate. Ask it to stop before passwords,
payments, account changes, permission dialogs, or other sensitive actions
unless you are actively reviewing and approving each step.

## 6. Useful inspection commands

```bash
# Save the current Android screenshot inside Ubuntu.
adb exec-out screencap -p > phone-screen.png

# Dump and read the current Android accessibility/UI hierarchy.
adb shell uiautomator dump /sdcard/window.xml
adb shell cat /sdcard/window.xml > window.xml

# Basic input primitives.
adb shell input tap X Y
adb shell input swipe X1 Y1 X2 Y2 300
adb shell input text 'hello%sworld'
adb shell input keyevent KEYCODE_BACK
```

Coordinates depend on the phone's current resolution and rotation. Inspect a
fresh screenshot or UI dump before sending coordinate-based input.

## Disconnect

```bash
adb disconnect PHONE_IP:CONNECTION_PORT
adb kill-server
```

Then disable **Wireless debugging** in Android Developer options when you no
longer need the bridge.

## Troubleshooting

- `failed to connect`: use the main Wireless debugging connection port, not the
  temporary pairing port.
- `unauthorized`: remove the saved pairing in Android and pair again.
- Connection disappears after reboot: reopen Wireless debugging and connect to
  the newly displayed port.
- More than one device: pass `-s PHONE_IP:CONNECTION_PORT` to every ADB command.
- Hermes is still open but Android replaced it with Settings or Brave: restore
  the Termux:X11 Android activity from Recents.

Android's official ADB documentation is linked from [Sources](SOURCES.md).
