#!/usr/bin/env bash
# Runs lockdown.sh and cleanup.sh against a fake `flatpak`. Touches nothing real.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/run" LOG="$tmp/calls.log"
mkdir -p "$HOME/.var/app/org.a.App/data/locked" "$XDG_RUNTIME_DIR/app/org.a.App/locked" "$tmp/bin"
touch "$HOME/.var/app/org.a.App/data/x" "$HOME/.var/app/org.a.App/data/locked/z" "$XDG_RUNTIME_DIR/app/org.a.App/y" "$XDG_RUNTIME_DIR/app/org.a.App/locked/w"
chmod 000 "$HOME/.var/app/org.a.App/data/locked" "$XDG_RUNTIME_DIR/app/org.a.App/locked"

cat > "$tmp/bin/flatpak" <<'EOS'
#!/bin/bash
echo "$*" >> "$LOG"
[[ -n "${FAKE_FAIL_ON:-}" && " $* " == *" $FAKE_FAIL_ON "* ]] && exit 1
case "$1" in
--version) echo "Flatpak ${FAKE_FLATPAK_VERSION:-1.17.0}" ;;
list) printf 'org.a.App\norg.b.App\n' ;;
info) printf '[Session Bus Policy]\n# comment=ignored\norg.x.Y=talk\norg.kde.*=own\n[System Bus Policy]\norg.z.W=talk\n[Policy Tracker3]\ndbus:org.t.M=a:b;c:d;!e:f;k=v;\n' ;;
ps) [[ -n "${FAKE_STUCK_PS:-}" ]] && echo 4242 ;;
documents) [[ "${2:-}" == "--columns=id" ]] && echo doc1 ;;
esac
exit 0
EOS
chmod +x "$tmp/bin/flatpak"; export PATH="$tmp/bin:$PATH"

fail=0
want() { grep -qxF -- "$1" "$LOG" || { echo "FAIL: missing: $1"; fail=1; }; }
deny() { ! grep -qxF -- "$1" "$LOG" || { echo "FAIL: unexpected: $1"; fail=1; }; }

: > "$LOG"; bash "$root/lockdown.sh" > /dev/null
want 'override --user --reset'
want 'list --app --columns=ref'
want 'info --show-permissions org.a.App'
want 'override --user --nosocket=wayland'
want 'override --user --nodevice=dri'
want 'override --user --nofilesystem=host:reset'
want 'override --user --nofilesystem=host-root'
want 'override --user --no-talk-name=org.freedesktop.UPower'
want 'override --user --system-no-talk-name=org.bluez.obex'
want 'override --user --system-no-talk-name=org.freedesktop.PackageKit'
want 'override --user --no-talk-name=org.gnome.Mutter.RemoteDesktop'
want 'override --user --nofilesystem=~/.netrc'
want 'override --user --nofilesystem=~/.aws'
want 'override --user --nofilesystem=~/.config/gh'
want 'override --user --nofilesystem=xdg-run/systemd'
want 'override --user --nofilesystem=xdg-run/dbus-1'
want 'override --user --nofilesystem=xdg-config/hypr'
want 'override --user --nofilesystem=~/.bashrc.d'
deny 'override --user --nofilesystem=xdg-run/.flatpak'   # collides with flatpak's own runtime-dir symlink
want 'override --user --nofilesystem=xdg-data/flatpak'
want 'override --user --no-talk-name=org.freedesktop.impl.portal.desktop.gnome'
want 'override --user --no-talk-name=org.x.Y'
want 'override --user --no-talk-name=org.kde.*'
deny 'override --user --no-talk-name=# comment'
want 'override --user --system-no-talk-name=org.z.W'
want 'override --user --remove-policy=Tracker3.dbus:org.t.M=a:b'
want 'override --user --remove-policy=Tracker3.dbus:org.t.M=c:d'
want 'override --user --remove-policy=Tracker3.dbus:org.t.M=k=v'
deny 'override --user --remove-policy=Tracker3.dbus:org.t.M=!e:f'
want 'override --user --reset com.github.tchx84.Flatseal'
want 'override --user --socket=wayland com.github.tchx84.Flatseal'
want 'override --user --talk-name=org.freedesktop.impl.portal.PermissionStore com.github.tchx84.Flatseal'
deny 'override --user --socket=wayland'
deny 'override --user --persist=.'
deny 'override --user --talk-name=org.gnome.Software com.github.tchx84.Flatseal'

# flatpak 1.16 rejects host-root: must not be sent
: > "$LOG"; FAKE_FLATPAK_VERSION=1.16.0 bash "$root/lockdown.sh" > /dev/null
deny 'override --user --nofilesystem=host-root'
want 'override --user --nofilesystem=host:reset'

# flatpak too old or malformed version: abort and change nothing
: > "$LOG"; ! FAKE_FLATPAK_VERSION=1.14.0 bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: old flatpak accepted"; fail=1; }
! grep -q '^override' "$LOG" || { echo "FAIL: old flatpak: override was called"; fail=1; }
: > "$LOG"; ! FAKE_FLATPAK_VERSION=unknown bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: non-numeric flatpak version accepted"; fail=1; }
! grep -q '^override' "$LOG" || { echo "FAIL: non-numeric flatpak version: override was called"; fail=1; }
: > "$LOG"; ! FAKE_FLATPAK_VERSION=1.20.abc bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: trailing-alpha flatpak version accepted"; fail=1; }
! grep -q '^override' "$LOG" || { echo "FAIL: trailing-alpha flatpak version: override was called"; fail=1; }

# a failing deny or failing info in subshell must abort before any grant (set -e, no partial re-grant)
: > "$LOG"; ! FAKE_FAIL_ON='--nodevice=dri' bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: failed deny ignored"; fail=1; }
deny 'override --user --reset com.github.tchx84.Flatseal'
deny 'override --user --talk-name=org.freedesktop.impl.portal.PermissionStore com.github.tchx84.Flatseal'
: > "$LOG"; ! FAKE_FAIL_ON='org.a.App' bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: failed info in subshell ignored"; fail=1; }
deny 'override --user --reset com.github.tchx84.Flatseal'

# cleanup must refuse to delete data if an instance is still running
: > "$LOG"; ! FAKE_STUCK_PS=1 bash "$root/cleanup.sh" > /dev/null 2>&1 < /dev/null || { echo "FAIL: stuck instance ignored"; fail=1; }
[ -f "$HOME/.var/app/org.a.App/data/x" ] || { echo "FAIL: data deleted while instance running"; fail=1; }

# cleanup must wipe data including chmod 000 subdirectories
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
want 'document-unexport --doc-id doc1'
[ -z "$(ls -A "$HOME/.var/app")" ] || { echo "FAIL: ~/.var/app not empty"; fail=1; }
[ -z "$(ls -A "$XDG_RUNTIME_DIR/app")" ] || { echo "FAIL: runtime app dir not empty"; fail=1; }

# cleanup must not follow a symlinked $XDG_RUNTIME_DIR/app
mkdir -p "$tmp/outside"; touch "$tmp/outside/keep"
rmdir "$XDG_RUNTIME_DIR/app"; ln -s "$tmp/outside" "$XDG_RUNTIME_DIR/app"
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
[ -f "$tmp/outside/keep" ] || { echo "FAIL: followed symlinked XDG_RUNTIME_DIR/app"; fail=1; }

[ $fail = 0 ] && echo "all tests passed"
exit $fail
