#!/usr/bin/env bash
# Runs lockdown.sh and cleanup.sh against a fake `flatpak`. Touches nothing real.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/run" LOG="$tmp/calls.log"
mkdir -p "$HOME/.var/app/org.a.App/data/locked" "$XDG_RUNTIME_DIR/app/org.a.App/locked" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp/locked" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/xdg-run" "$tmp/bin"
touch "$HOME/.var/app/org.a.App/data/x" "$HOME/.var/app/org.a.App/data/locked/z" "$XDG_RUNTIME_DIR/app/org.a.App/y" "$XDG_RUNTIME_DIR/app/org.a.App/locked/w" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/.ref" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp/locked/t" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/xdg-run/s"
chmod 000 "$HOME/.var/app/org.a.App/data/locked" "$XDG_RUNTIME_DIR/app/org.a.App/locked" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp/locked"

cat > "$tmp/bin/flatpak" <<'EOS'
#!/bin/bash
echo "$*" >> "$LOG"
[[ -n "${FAKE_FAIL_ON:-}" && " $* " == *" $FAKE_FAIL_ON "* ]] && exit 1
case "$1" in
--version) echo "Flatpak ${FAKE_FLATPAK_VERSION:-1.17.0}" ;;
list) printf 'user\torg.a.App/x86_64/stable\nsystem\torg.a.App/x86_64/stable\nsystem (extra)\torg.b.App/x86_64/stable\n' ;;
info)
  if [[ "$*" == *--show-metadata* ]]; then printf '[Application]\nname=org.a.App\n[Session Bus Policy]\norg.m.Meta=talk\norg.n.None=none\n'
  else
    printf '[Session Bus Policy]\n# comment=ignored\norg.x.Y=talk\norg.kde.*=own\n'
    [[ -n "${FAKE_NO_SYSTEM:-}" ]] || printf '[System Bus Policy]\norg.z.W=talk\n'
    printf '[Policy Tracker3]\ndbus:org.t.M=a:b;c:d;!e:f;k=v;\n'
  fi ;;
ps) [[ -n "${FAKE_STUCK_PS:-}" ]] && echo 4242 ;;
documents) [[ "${2:-}" == "--columns=id" ]] && echo doc1 ;;
esac
exit 0
EOS
chmod +x "$tmp/bin/flatpak"; export PATH="$tmp/bin:$PATH"

fail=0
want() { grep -qxF -- "$1" "$LOG" || { echo "FAIL: missing: $1"; fail=1; }; }
want_app() { grep -F -- " $2 " "$LOG" | grep -q "^override --user .* $1\$" || { echo "FAIL: missing for $1: $2"; fail=1; }; }
deny() { ! grep -qxF -- "$1" "$LOG" || { echo "FAIL: unexpected: $1"; fail=1; }; }

: > "$LOG"; bash "$root/lockdown.sh" > /dev/null
want 'override --user --reset'
want 'list --app --columns=installation,ref'
want 'info --user --show-metadata org.a.App/x86_64/stable'
want 'info --user --show-permissions org.a.App/x86_64/stable'
want 'info --system --show-metadata org.a.App/x86_64/stable'
want 'info --system --show-permissions org.a.App/x86_64/stable'
want 'info --installation=extra --show-metadata org.b.App/x86_64/stable'
want 'info --installation=extra --show-permissions org.b.App/x86_64/stable'
want 'override --user --no-talk-name=org.m.Meta'
deny 'override --user --no-talk-name=org.n.None'
want 'override --user --nosocket=wayland'
want 'override --user --nodevice=dri'
want 'override --user --nofilesystem=host:reset'
want 'override --user --nofilesystem=host-root'
want 'override --user --no-talk-name=org.freedesktop.UPower'
# system bus names: per app only, never global (a global entry makes flatpak proxy the system bus for every app)
! grep -qE '^override --user --system-no-talk-name=[^ ]+$' "$LOG" || { echo "FAIL: global --system-no-talk-name written"; fail=1; }
for a in org.a.App org.b.App; do
    want_app "$a" '--system-no-talk-name=org.bluez.obex'
    want_app "$a" '--system-no-talk-name=org.freedesktop.PackageKit'
    want_app "$a" '--system-no-talk-name=org.z.W'
done
want 'override --user --no-talk-name=org.gnome.Mutter.RemoteDesktop'
want 'override --user --nofilesystem=~/.netrc'
want 'override --user --nofilesystem=~/.aws'
want 'override --user --nofilesystem=~/.config/gh'
want 'override --user --nofilesystem=xdg-run/systemd'
want 'override --user --nofilesystem=xdg-run/dbus-1'
want 'override --user --nofilesystem=xdg-run/bus'
want 'override --user --nofilesystem=xdg-run/wayland-0'
want 'override --user --nofilesystem=xdg-run/wayland-1'
want 'override --user --nofilesystem=xdg-run/ssh-agent'
want 'override --user --nofilesystem=xdg-run/openssh_agent'
want 'override --user --nofilesystem=xdg-config/hypr'
want 'override --user --nofilesystem=~/.bashrc.d'
want 'override --user --nofilesystem=~/.vscode'
want 'override --user --nofilesystem=~/.config/Code'
want 'override --user --nofilesystem=xdg-config/Code'
want 'override --user --nofilesystem=~/.config/VSCodium'
want 'override --user --nofilesystem=xdg-config/VSCodium'
want 'override --user --nofilesystem=~/.npm'
want 'override --user --nofilesystem=~/.yarn'
want 'override --user --nofilesystem=~/.local/share/pnpm'
want 'override --user --nofilesystem=xdg-data/pnpm'
want 'override --user --nofilesystem=~/.m2'
want 'override --user --nofilesystem=~/.gradle'
want 'override --user --nofilesystem=~/.config/pip'
want 'override --user --nofilesystem=xdg-config/pip'
want 'override --user --nofilesystem=~/.mozilla'
want 'override --user --nofilesystem=~/.config/google-chrome'
want 'override --user --nofilesystem=xdg-config/google-chrome'
want 'override --user --nofilesystem=~/.config/chromium'
want 'override --user --nofilesystem=xdg-config/chromium'
want 'override --user --nofilesystem=~/.config/BraveSoftware'
want 'override --user --nofilesystem=xdg-config/BraveSoftware'
deny 'override --user --nofilesystem=/run'   # reserved by flatpak, always a no-op
deny 'override --user --nofilesystem=xdg-run/.flatpak'   # collides with flatpak's own runtime-dir symlink
want 'override --user --nofilesystem=xdg-data/flatpak'
want 'override --user --no-talk-name=org.freedesktop.impl.portal.desktop.gnome'
want 'override --user --no-talk-name=org.x.Y'
want 'override --user --no-talk-name=org.kde.*'
deny 'override --user --no-talk-name=# comment'
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

# apps without a system bus policy get no system bus override at all
: > "$LOG"; FAKE_NO_SYSTEM=1 bash "$root/lockdown.sh" > /dev/null
! grep -q -- '--system-no-talk-name' "$LOG" || { echo "FAIL: system bus deny written for app without system policy"; fail=1; }
want 'override --user --no-talk-name=org.x.Y'

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
: > "$LOG"; ! FAKE_FAIL_ON='org.b.App/x86_64/stable' bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: failed info in subshell ignored"; fail=1; }
deny 'override --user --reset com.github.tchx84.Flatseal'

# cleanup must refuse to delete data if an instance is still running
: > "$LOG"; ! FAKE_STUCK_PS=1 bash "$root/cleanup.sh" > /dev/null 2>&1 < /dev/null || { echo "FAIL: stuck instance ignored"; fail=1; }
[ -f "$HOME/.var/app/org.a.App/data/x" ] || { echo "FAIL: data deleted while instance running"; fail=1; }

# cleanup must wipe data including chmod 000 directories and per-app runtime tmp/xdg-run
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
want 'document-unexport --doc-id doc1'
[ -z "$(ls -A "$HOME/.var/app")" ] || { echo "FAIL: ~/.var/app not empty"; fail=1; }
[ -z "$(ls -A "$XDG_RUNTIME_DIR/app")" ] || { echo "FAIL: runtime app dir not empty"; fail=1; }
[ ! -e "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp" ] || { echo "FAIL: .flatpak tmp not wiped"; fail=1; }
[ ! -e "$XDG_RUNTIME_DIR/.flatpak/org.a.App/xdg-run" ] || { echo "FAIL: .flatpak xdg-run not wiped"; fail=1; }
[ -f "$XDG_RUNTIME_DIR/.flatpak/org.a.App/.ref" ] || { echo "FAIL: .flatpak .ref lockfile removed"; fail=1; }

# cleanup must not follow a symlinked $XDG_RUNTIME_DIR/app
mkdir -p "$tmp/outside"; touch "$tmp/outside/keep"
rmdir "$XDG_RUNTIME_DIR/app"; ln -s "$tmp/outside" "$XDG_RUNTIME_DIR/app"
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
[ -f "$tmp/outside/keep" ] || { echo "FAIL: followed symlinked XDG_RUNTIME_DIR/app"; fail=1; }

[ $fail = 0 ] && echo "all tests passed"
exit $fail
