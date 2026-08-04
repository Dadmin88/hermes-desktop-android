# Maintenance, upgrades, and removal

This guide separates the three durable layers used by the project:

1. **Termux host:** packages plus `$PREFIX/bin/hermes-android` and
   `$PREFIX/bin/hermes-ubuntu`.
2. **Ubuntu PRoot guest:** Hermes source under
   `/usr/local/lib/hermes-agent` and guest launchers under `/usr/local/bin`.
3. **Hermes user data:** configuration, credentials, sessions, and other state
   under `/root/.hermes` in the Ubuntu guest.

The installers do not intentionally remove `/root/.hermes`. Review every backup
and removal command before running it.

## Back up Hermes user data

From the Termux host, create an archive in Termux's shared temporary directory:

```bash
backup="hermes-config-$(date +%Y%m%d-%H%M%S).tar.gz"
proot-distro login ubuntu --shared-tmp -- \
  tar -C /root -czf "/tmp/$backup" .hermes
printf 'Backup: %s/%s\n' "$PREFIX/tmp" "$backup"
```

Copy that archive off the phone before removing the Ubuntu guest. It contains
private configuration and may contain credentials or session data; do not post
it in an issue or chat.

To restore into a new Ubuntu guest, place the archive in `$PREFIX/tmp`, review
its contents, and then extract it:

```bash
tar -tzf "$PREFIX/tmp/BACKUP_FILE.tar.gz"
proot-distro login ubuntu --shared-tmp -- \
  tar -C /root -xzf /tmp/BACKUP_FILE.tar.gz
```

## Refresh launchers without rebuilding Hermes

This updates only the host and guest launch wrappers for release `v0.1.2`. It
does not reinstall packages, change the Hermes checkout, or rebuild Desktop.
Run it from the Termux host:

```bash
release=v0.1.2
curl -fSLO "https://github.com/Dadmin88/hermes-desktop-android/releases/download/$release/install-launchers.sh"
curl -fSLO "https://github.com/Dadmin88/hermes-desktop-android/releases/download/$release/install-launchers.sh.sha256"
sha256sum --check install-launchers.sh.sha256
bash install-launchers.sh
rm -f install-launchers.sh install-launchers.sh.sha256
```

The installer stages complete downloads before replacing launchers. If a
download or guest stage fails, existing launchers remain in place.

## Reinstall the current release

First back up `/root/.hermes`, then download and verify the release installer as
described in the main README. Re-running `v0.1.2` is safe when the existing
Hermes checkout is clean and already points at the verified pinned revision.

The installer deliberately refuses to replace an existing checkout at another
revision. Do not bypass that check by deleting directories blindly.

## Upgrade to a future project release

Read the future release notes first. If the release keeps the same Hermes pin,
re-run its verified installer.

If the release changes the Hermes pin:

1. Back up `/root/.hermes`.
2. Enter Ubuntu with `hermes-ubuntu`.
3. Inspect the checkout:

   ```bash
   git -C /usr/local/lib/hermes-agent status --short
   git -C /usr/local/lib/hermes-agent rev-parse HEAD
   ```

4. Preserve any deliberate source changes outside the checkout.
5. Rename the old source tree instead of deleting it:

   ```bash
   mv /usr/local/lib/hermes-agent \
     "/usr/local/lib/hermes-agent.backup.$(date +%Y%m%d-%H%M%S)"
   ```

6. Exit to Termux and run the new release's checksum-verified installer.
7. Verify `hermes-android`, both doctor reports, and model configuration before
   removing the backup source tree.

Hermes user data lives outside the source checkout, but a backup is still
required before any upgrade.

## Recover from an interrupted install

- Re-run the same release installer after confirming network access and free
  storage.
- Download failures do not replace installed launchers.
- A failed Ubuntu stage does not replace the Termux launchers.
- A different existing Hermes checkout causes a fail-closed error; inspect it
  instead of forcing replacement.
- Keep Termux in the foreground during the source build so Android does not
  suspend it.

Run the layer-aware doctor from Termux and Ubuntu before changing anything else.
See [Troubleshooting](TROUBLESHOOTING.md).

## Remove only the project launchers

From Termux:

```bash
rm -f "$PREFIX/bin/hermes-android" "$PREFIX/bin/hermes-ubuntu"
proot-distro login ubuntu --shared-tmp -- \
  rm -f /usr/local/bin/hermes-android-desktop \
        /usr/local/bin/hermes-android-session
```

This leaves Hermes source, Hermes user data, Ubuntu, Termux:X11, PulseAudio, and
`xfwm4` installed.

## Remove the Hermes source build but preserve user data

Back up `/root/.hermes` first. Then enter Ubuntu and remove only the source tree:

```bash
rm -rf /usr/local/lib/hermes-agent
```

This does not remove `/root/.hermes`. Do not run a broad command against
`/usr/local/lib` or `/root`.

## Remove the entire Ubuntu guest

> [!CAUTION]
> `proot-distro remove ubuntu` deletes the complete Ubuntu guest, including
> `/root/.hermes`, unless you copied the backup outside the guest first.

From Termux, after verifying the backup exists under `$PREFIX/tmp` or off-device:

```bash
proot-distro remove ubuntu
```

Termux packages are shared with other Termux workflows. Remove
`termux-x11-nightly`, `pulseaudio`, `xfwm4`, or `proot-distro` only if no other
Termux project uses them.
