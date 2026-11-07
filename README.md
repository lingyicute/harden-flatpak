# harden-flatpak

Two scripts to harden the flatpak.

lockdown script configures Flatpak to automatically reject most permissions, which may break functionality for many Flatpaks. It provides options to proceed with the configuration and grants specific permissions as needed.

```console
$ bash lockdown.sh   # default-deny user-level overrides; re-run after installing apps
$ bash cleanup.sh    # kill Flatpaks, unexport documents, wipe ~/.var/app/*, $XDG_RUNTIME_DIR/app/*, $XDG_RUNTIME_DIR/.flatpak/*/{tmp,xdg-run} and /dev/shm/flatpak-*
```

Both scripts are deliberately tiny so that they can be audited at a glance. 

> [!important]
> 
> Scripts never ask for confirmation: running the script is the confirmation. `cleanup.sh` deletes data immediately.

## What `lockdown.sh` does

- Starts by resetting the user-level global override and Flatseal's override (`flatpak override --user --reset`, no confirmation, no backup), so the result does not depend on earlier runs. Per-app overrides of other apps are left alone.
- Denies every Flatpak permission type (`--unshare`, `--nosocket`, `--nodevice`, `--disallow`, `--nousb=all`, `--remove-policy`), including `wayland` and `dri`, for all apps. Nothing is persisted (`--persist` is never granted).
- Denies all filesystem access (`host:reset`, `home`, `host`, `host-os`, `host-etc`) plus a list of sandbox-escape and credential paths (`~/.config/systemd`, `~/.local/share/dbus-1/services`, `~/.ssh`, `~/.gnupg`, `~/.password-store`, `xdg-data/flatpak/overrides`, editor/package-manager configs, browser profiles, ...). `host:reset` already drops every grant from manifests and system overrides, so the entries only matter for directories: an existing directory in the list is masked with a tmpfs if you later grant `--filesystem=home` or `host` (or a parent directory) to one app. Files, sockets and `/mnt`, `/media`, `/run/media`, `/home` cannot be masked that way and are not listed (see Limits).
- Denies a static list of session D-Bus names, including the concrete portal backends (`org.freedesktop.impl.portal.desktop.*`, `...Secret`, `...PermissionStore`) and the Flatpak/systemd escape names. The static list of system bus names is denied per app, only for installed apps that already declare a system bus policy: one global `--system-no-talk-name` entry would make Flatpak start a system bus proxy for every app.
- Reads the manifest and the merged permissions (`flatpak info --show-metadata` and `--show-permissions`) of the apps installed right now, in every installation, and denies every session/system bus name and subsystem policy they declare.
- Re-grants only what Flatseal needs to work (see [docs/flatseal-grants.md](docs/flatseal-grants.md)).

`--no-talk-name=foo.*` is **not** a glob in Flatpak. It only cancels an entry that is literally named `foo.*`. So the static list can never be complete; re-run `lockdown.sh` after installing apps.

To undo: `flatpak override --user --reset` (and `flatpak override --user --reset com.github.tchx84.Flatseal`). To inspect: `flatpak override --user --show`.

## Limits of Flatpak under a high-threat model

- **A filtered session bus and the AT-SPI bus are still mounted.** `--nosocket=session-bus` only removes the unfiltered bus. `flatpak run` still mounts a filtered proxy that always allows `org.freedesktop.portal.*` (including sub-sandbox `Spawn()`) and an accessibility bus proxy. For complete bus isolation, run the app with `flatpak run --sandbox`. `--no-session-bus --no-a11y-bus` drops only those two; an app that declares any system bus policy (a deny entry counts) still gets a filtered system bus proxy, and `flatpak run` has no option to drop it.
- **`~/.var/app/$APP_ID` is always writable and survives between runs.** Flatpak has no `--nopersist` override, and `persistent=` directories declared in a manifest cannot be revoked. That is what `cleanup.sh` is for; `flatpak run --sandbox` gives a throwaway sandbox.
- **Do not grant `--filesystem=home` or `host` to untrusted apps.** Flatpak masks a path only with a tmpfs over a directory that exists at launch. Files (`~/.bashrc`, `~/.profile`, `~/.zshrc`, `~/.netrc`, ...) and sockets (`xdg-run/bus`, `xdg-run/wayland-0`, ...) are never masked, so with `home` an app can read and append to your shell init files. `host` also exposes `/mnt`, `/media`, `/run/media` and `/home` (they cannot be masked: a grant wins over a mask on the same path). `/run`, `/var`, `/root` and `/boot` are not shared by `host`. Grant narrow directories or use portals.
- **Per-app overrides win over the global one.** Anything you granted to a single app earlier (for example with Flatseal) still applies after `lockdown.sh`. Check with `ls ~/.local/share/flatpak/overrides`.
- **Portal decisions are not cleaned.** Camera, location, notification, etc. decisions live in `$XDG_DATA_HOME/flatpak/db/`. `cleanup.sh` shows them but does not delete them. Use `flatpak permissions`, `flatpak permission-remove` or `flatpak permission-reset APP_ID`.
- **Wayland isolation needs `wp-security-context-v1`** in your compositor.

## Tests

`bash tests/test.sh` runs both scripts against a fake `flatpak` and checks the generated commands. It touches nothing real. It also checks that `host-root` is only sent on flatpak >= 1.17, that a too-old flatpak changes nothing, and that a failing deny aborts before any grant.

## 🗂️ License

harden-flatpak is released under the GNU General Public License v3.0 (GPLv3).

Copyright (C) 2024-2026 lingyicute.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see https://www.gnu.org/licenses.
