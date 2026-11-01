#!/usr/bin/env bash
# Runs lockdown.sh and cleanup.sh against a fake `flatpak`. Touches nothing real.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/run" LOG="$tmp/calls.log"
mkdir -p "$HOME/.var/app/org.a.App/data" "$XDG_RUNTIME_DIR/app/org.a.App" "$tmp/bin"
touch "$HOME/.var/app/org.a.App/data/x" "$XDG_RUNTIME_DIR/app/org.a.App/y"

cat > "$tmp/bin/flatpak" <<'EOS'
#!/bin/bash
echo "$*" >> "$LOG"
case "$1" in
list) echo org.a.App ;;
info) printf '[Session Bus Policy]\norg.x.Y=talk\norg.kde.*=own\n[System Bus Policy]\norg.z.W=talk\n[Policy Tracker3]\ndbus:org.t.M=a:b;c:d;!e:f;\n' ;;
esac
exit 0
EOS
chmod +x "$tmp/bin/flatpak"; export PATH="$tmp/bin:$PATH"

fail=0
want() { grep -qxF -- "$1" "$LOG" || { echo "FAIL: missing: $1"; fail=1; }; }
deny() { ! grep -qxF -- "$1" "$LOG" || { echo "FAIL: unexpected: $1"; fail=1; }; }

: > "$LOG"; bash "$root/lockdown.sh" > /dev/null
want 'override --user --nosocket=wayland'
want 'override --user --nodevice=dri'
want 'override --user --nofilesystem=host:reset'
want 'override --user --nofilesystem=~/.netrc'
want 'override --user --no-talk-name=org.freedesktop.impl.portal.desktop.gnome'
want 'override --user --no-talk-name=org.x.Y'
want 'override --user --no-talk-name=org.kde.*'
want 'override --user --system-no-talk-name=org.z.W'
want 'override --user --remove-policy=Tracker3.dbus:org.t.M=a:b'
want 'override --user --remove-policy=Tracker3.dbus:org.t.M=c:d'
deny 'override --user --remove-policy=Tracker3.dbus:org.t.M=!e:f'
want 'override --user --socket=wayland com.github.tchx84.Flatseal'
want 'override --user --talk-name=org.freedesktop.impl.portal.PermissionStore com.github.tchx84.Flatseal'
deny 'override --user --socket=wayland'
deny 'override --user --persist=.'
deny 'override --user --talk-name=org.gnome.Software com.github.tchx84.Flatseal'

: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
[ -z "$(ls -A "$HOME/.var/app")" ] || { echo "FAIL: ~/.var/app not empty"; fail=1; }
[ -z "$(ls -A "$XDG_RUNTIME_DIR/app")" ] || { echo "FAIL: runtime app dir not empty"; fail=1; }

[ $fail = 0 ] && echo "all tests passed"
exit $fail
