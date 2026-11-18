#!/usr/bin/env bash
# Runs lockdown.sh and cleanup.sh against a fake `flatpak`. Touches nothing real.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
# Never inspect or write overrides in an installation inherited from the caller.
unset FLATPAK_USER_DIR XDG_DATA_HOME
export HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/run" LOG="$tmp/calls.log" CLEANUP_SHM_DIR="$tmp/shm"
mkdir -p "$HOME/.var/app/org.a.App/data/locked" "$XDG_RUNTIME_DIR/app/org.a.App/locked" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp/locked" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/xdg-run" "$tmp/bin"
touch "$HOME/.var/app/org.a.App/data/x" "$HOME/.var/app/org.a.App/data/locked/z" "$XDG_RUNTIME_DIR/app/org.a.App/y" "$XDG_RUNTIME_DIR/app/org.a.App/locked/w" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/.ref" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp/locked/t" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/xdg-run/s"
mkdir -p "$tmp/shm/flatpak-org.a.App-AbCdEf/locked" "$tmp/shm/other-dir" "$tmp/shm-target"; touch "$tmp/shm/flatpak-org.a.App-AbCdEf/v" "$tmp/shm/flatpak-org.a.App-AbCdEf/locked/u" "$tmp/shm/other-dir/keep" "$tmp/shm-target/keep"; ln -s "$tmp/shm-target" "$tmp/shm/flatpak-link"
mkdir -p "$tmp/shm/flatpak-backups" "$tmp/shm/flatpak-org.a.App-archive"
ln -s "$tmp/shm/flatpak-org.a.App-AbCdEf" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/dev-shm"
mkdir -p "$XDG_RUNTIME_DIR/.flatpak/org.a.App/metadata"
chmod 0500 "$XDG_RUNTIME_DIR/.flatpak/org.a.App/metadata"
chmod 000 "$tmp/shm/flatpak-org.a.App-AbCdEf/locked" "$HOME/.var/app/org.a.App/data/locked" "$XDG_RUNTIME_DIR/app/org.a.App/locked" "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp/locked"

cat > "$tmp/bin/flatpak" <<'EOS'
#!/bin/bash
echo "$*" >> "$LOG"
[[ -n "${FAKE_FAIL_ON:-}" && " $* " == *" $FAKE_FAIL_ON "* ]] && exit 1
case "$1" in
--version) echo "Flatpak ${FAKE_FLATPAK_VERSION:-1.17.0}" ;;
list) printf 'user\torg.a.App/x86_64/stable\nsystem\torg.a.App/x86_64/stable\nsystem (extra)\torg.b.App/x86_64/stable\n'
      [[ -z "${FAKE_LIST_FLATSEAL:-}" ]] || printf 'user\tcom.github.tchx84.Flatseal/x86_64/stable\n' ;;
info)
  if [[ "$*" == *--show-metadata* ]]; then printf '[Application]\r\nname=org.a.App\r\n[Session Bus Policy] \r\norg.m.Meta=talk\r\norg.c.Crlf = talk\r\norg.n.None = none\r\n'
  else
    printf '[Session Bus Policy]\n# comment=ignored\norg.x.Y=talk\norg.kde.*=own\n'
    [[ -n "${FAKE_NO_SYSTEM:-}" ]] || printf '[System Bus Policy]\norg.z.W=talk\n'
    printf '[Policy Tracker3]\ndbus:org.t.M=a:b;c:d;!e:f;k=v;\n'
  fi ;;
override)
    # Stand in for Flatpak's keyfile writer in the temporary installation.
    if [[ "$2" == --user && -n "${FLATPAK_USER_DIR:-}" && "$3" != --show ]]; then
      name=${!#}; [[ "$name" != --* ]] || name=global
      mkdir -p "$FLATPAK_USER_DIR/overrides" || exit 1
      printf '%s\n' "$@" > "$FLATPAK_USER_DIR/overrides/$name" || exit 1
    fi
    if [[ -n "${FAKE_SYSTEM_LAYER:-}" && "$3" == --show && "$2" == --system ]]; then
      if [[ $# == 3 ]]; then printf '[Session Bus Policy]\norg.example.SiteSession=talk\n'
      else printf '[System Bus Policy]\norg.example.SiteSystem=talk\n[Policy Tracker3]\ndbus:org.example.Miner=tracker:Audio;\n'; fi
    fi ;;
ps) [[ -n "${FAKE_STUCK_PS:-}" ]] && printf '4242\t99\n'
    [[ -n "${FAKE_PS_UNTIL:-}" && $(date +%s) -lt $FAKE_PS_UNTIL ]] && printf '4343\t99\n'
    if [[ -n "${FAKE_PS_STARTUP:-}" && ! -f "$FAKE_PS_STARTUP.dead" ]]; then
      if [[ ! -f "$FAKE_PS_STARTUP.s1" ]]; then : > "$FAKE_PS_STARTUP.s1"; printf '4444\t0\n'
      else printf '4444\t88\n'; fi
    fi ;;
kill)
    if [[ -n "${FAKE_PS_STARTUP:-}" && "${2:-}" == "4444" ]]; then
      if [[ ! -f "$FAKE_PS_STARTUP.k1" ]]; then : > "$FAKE_PS_STARTUP.k1"; exit 0; fi
      if [[ ! -f "$FAKE_PS_STARTUP.k2" ]]; then : > "$FAKE_PS_STARTUP.k2"; exit 1; fi
      : > "$FAKE_PS_STARTUP.dead"
    fi ;;
documents) [[ "${2:-}" == "--columns=id" ]] && printf '%s\n' "${FAKE_DOC_IDS-doc1}" ;;
esac
exit 0
EOS
chmod +x "$tmp/bin/flatpak"; export PATH="$tmp/bin:$PATH"

fail=0
want() { grep -qxF -- "$1" "$LOG" || { echo "FAIL: missing: $1"; fail=1; }; }
deny() { ! grep -qxF -- "$1" "$LOG" || { echo "FAIL: unexpected: $1"; fail=1; }; }
has_global() { awk -v f="$1" '/^override --user --/ && $0 != "override --user --reset" && $NF ~ /^--/ { if (index(" " $0 " ", " " f " ")) ok=1 } END { exit !ok }' "$LOG"; }
want_global() { has_global "$1" || { echo "FAIL: missing global: $1"; fail=1; }; }
deny_global() { ! has_global "$1" || { echo "FAIL: unexpected global: $1"; fail=1; }; }
has_app() { awk -v a="$1" -v f="$2" '/^override --user / && $NF == a { if (index(" " $0 " ", " " f " ")) ok=1 } END { exit !ok }' "$LOG"; }
want_app() { has_app "$1" "$2" || { echo "FAIL: missing for $1: $2"; fail=1; }; }
deny_app() { ! has_app "$1" "$2" || { echo "FAIL: unexpected for $1: $2"; fail=1; }; }

: > "$LOG"; bash "$root/lockdown.sh" > /dev/null
deny 'override --user --reset'
want 'list --app --columns=installation,ref'
want 'info --user --show-metadata org.a.App/x86_64/stable'
want 'info --user --show-permissions org.a.App/x86_64/stable'
want 'info --system --show-metadata org.a.App/x86_64/stable'
want 'info --system --show-permissions org.a.App/x86_64/stable'
want 'info --installation=extra --show-metadata org.b.App/x86_64/stable'
want 'info --installation=extra --show-permissions org.b.App/x86_64/stable'
# global overrides are batched into a single replacement, with host:reset before path masks
[ "$(awk '/^override --user --/ && $0 != "override --user --reset" && $NF ~ /^--/{c++} END{print c+0}' "$LOG")" -eq 1 ] || { echo "FAIL: global overrides not batched into one call"; fail=1; }
awk '/^override --user --/ && $0 != "override --user --reset" && $NF ~ /^--/ { a=index(" "$0" "," --nofilesystem=host:reset "); b=index(" "$0" "," --nofilesystem=~/.ssh "); if (a>0 && b>a) ok=1 } END{exit !ok}' "$LOG" || { echo "FAIL: host:reset must precede path masks"; fail=1; }
want_global '--no-talk-name=org.m.Meta'
want_global '--no-talk-name=org.c.Crlf'
deny_global '--no-talk-name=org.n.None'
want_global '--nosocket=wayland'
want_global '--nodevice=dri'
want_global '--nofilesystem=host:reset'
want_global '--nofilesystem=host-root'
want_global '--no-talk-name=org.freedesktop.UPower'
# system bus names: per app only, never global, deduplicated across user+system installations
! awk '/^override --user --/ && $NF ~ /^--/ && /--system-no-talk-name=/{f=1} END{exit !f}' "$LOG" || { echo "FAIL: global --system-no-talk-name written"; fail=1; }
[ "$(grep -c '^override --user .* org\.a\.App$' "$LOG")" -eq 1 ] || { echo "FAIL: duplicate system bus override for org.a.App"; fail=1; }
for a in org.a.App org.b.App; do
    want_app "$a" '--system-no-talk-name=org.bluez.obex'
    want_app "$a" '--system-no-talk-name=org.freedesktop.PackageKit'
    want_app "$a" '--system-no-talk-name=org.z.W'
done
want_global '--no-talk-name=org.gnome.Mutter.RemoteDesktop'
want_global '--nofilesystem=~/.aws'
want_global '--nofilesystem=~/.config/gh'
want_global '--nofilesystem=xdg-run/systemd'
want_global '--nofilesystem=xdg-run/dbus-1'
want_global '--nofilesystem=xdg-config/hypr'
want_global '--nofilesystem=~/.bashrc.d'
want_global '--nofilesystem=~/.vscode'
want_global '--nofilesystem=~/.config/Code'
want_global '--nofilesystem=xdg-config/Code'
want_global '--nofilesystem=~/.config/VSCodium'
want_global '--nofilesystem=xdg-config/VSCodium'
want_global '--nofilesystem=~/.npm'
want_global '--nofilesystem=~/.yarn'
want_global '--nofilesystem=~/.local/share/pnpm'
want_global '--nofilesystem=xdg-data/pnpm'
want_global '--nofilesystem=~/.m2'
want_global '--nofilesystem=~/.gradle'
want_global '--nofilesystem=~/.config/pip'
want_global '--nofilesystem=xdg-config/pip'
want_global '--nofilesystem=~/.mozilla'
want_global '--nofilesystem=~/.config/google-chrome'
want_global '--nofilesystem=xdg-config/google-chrome'
want_global '--nofilesystem=~/.config/chromium'
want_global '--nofilesystem=xdg-config/chromium'
want_global '--nofilesystem=~/.config/BraveSoftware'
want_global '--nofilesystem=xdg-config/BraveSoftware'
# files, sockets and top-level dirs can never be masked: not listed
for x in '~/.bashrc' '~/.profile' '~/.netrc' xdg-config/kdeglobals xdg-run/bus xdg-run/wayland-0 xdg-run/wayland-1 xdg-run/ssh-agent xdg-run/openssh_agent xdg-run/pipewire-0 /run/docker.sock xdg-run/docker.sock /run/podman /run/libvirt /home /var/home /media /run/media /mnt /var /root /boot; do
    deny_global "--nofilesystem=$x"
done
deny_global '--nofilesystem=/run'   # reserved by flatpak, always a no-op
deny_global '--nofilesystem=xdg-run/.flatpak'   # collides with flatpak's own runtime-dir symlink
want_global '--nofilesystem=xdg-data/flatpak'
want_global '--no-talk-name=org.freedesktop.impl.portal.desktop.gnome'
want_global '--no-talk-name=org.x.Y'
want_global '--no-talk-name=org.kde.*'
! grep -q -- '--no-talk-name=# comment' "$LOG" || { echo "FAIL: comment parsed as bus name"; fail=1; }
want_global '--remove-policy=Tracker3.dbus:org.t.M=a:b'
want_global '--remove-policy=Tracker3.dbus:org.t.M=c:d'
want_global '--remove-policy=Tracker3.dbus:org.t.M=k=v'
deny_global '--remove-policy=Tracker3.dbus:org.t.M=!e:f'
deny 'override --user --reset com.github.tchx84.Flatseal'
[ "$(awk '/^override --user / && $NF == "com.github.tchx84.Flatseal" && $3 != "--reset"{c++} END{print c+0}' "$LOG")" -eq 1 ] || { echo "FAIL: Flatseal grants not batched into one call"; fail=1; }
want_app com.github.tchx84.Flatseal '--socket=wayland'
want_app com.github.tchx84.Flatseal '--filesystem=/var/lib/flatpak/app:ro'
want_app com.github.tchx84.Flatseal '--filesystem=xdg-data/flatpak/app:ro'
want_app com.github.tchx84.Flatseal '--filesystem=xdg-data/flatpak/overrides:create'
want_app com.github.tchx84.Flatseal '--talk-name=org.freedesktop.impl.portal.PermissionStore'
deny_global '--socket=wayland'
deny_global '--persist=.'
deny_app com.github.tchx84.Flatseal '--talk-name=org.gnome.Software'

# apps without a system bus policy get no system bus override at all
: > "$LOG"; FAKE_NO_SYSTEM=1 bash "$root/lockdown.sh" > /dev/null
! grep -q -- '--system-no-talk-name' "$LOG" || { echo "FAIL: system bus deny written for app without system policy"; fail=1; }
want_global '--no-talk-name=org.x.Y'

# Merged permissions can omit policies from lower override layers on the next run.
: > "$LOG"; FAKE_SYSTEM_LAYER=1 FAKE_NO_SYSTEM=1 bash "$root/lockdown.sh" > /dev/null
want 'override --system --show'
want 'override --installation=extra --show org.b.App'
want_global '--no-talk-name=org.example.SiteSession'
want_global '--remove-policy=Tracker3.dbus:org.example.Miner=tracker:Audio'
want_app org.a.App '--system-no-talk-name=org.example.SiteSystem'
deny_app org.b.App '--system-no-talk-name=org.example.SiteSystem'

# the per-app override listing skips global and Flatseal but shows other apps
mkdir -p "$HOME/.local/share/flatpak/overrides"; touch "$HOME/.local/share/flatpak/overrides/"{global,com.github.tchx84.Flatseal,org.c.App}
out=$(bash "$root/lockdown.sh")
grep -qxF org.c.App <<< "$out" || { echo "FAIL: per-app override not listed"; fail=1; }
! grep -qxF -e global -e com.github.tchx84.Flatseal <<< "$out" || { echo "FAIL: global/Flatseal override listed"; fail=1; }

# user-granted system bus names in per-app overrides survive re-runs; Flatseal denies are written with its grants
printf '[System Bus Policy]\r\norg.bluez = talk\r\norg.freedesktop.PackageKit=none\n' > "$HOME/.local/share/flatpak/overrides/org.a.App"
: > "$LOG"; FAKE_LIST_FLATSEAL=1 bash "$root/lockdown.sh" > /dev/null
deny_app org.a.App '--system-no-talk-name=org.bluez'
want_app org.a.App '--system-no-talk-name=org.freedesktop.PackageKit'
want_app org.a.App '--system-no-talk-name=org.z.W'
want_app com.github.tchx84.Flatseal '--system-no-talk-name=org.z.W'
rm -f "$HOME/.local/share/flatpak/overrides/org.a.App"

# flatpak 1.16 rejects host-root: must not be sent
: > "$LOG"; FAKE_FLATPAK_VERSION=1.16.0 bash "$root/lockdown.sh" > /dev/null
deny_global '--nofilesystem=host-root'
want_global '--nofilesystem=host:reset'

# flatpak too old or malformed version: abort and change nothing
: > "$LOG"; ! FAKE_FLATPAK_VERSION=1.14.0 bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: old flatpak accepted"; fail=1; }
! grep -q '^override' "$LOG" || { echo "FAIL: old flatpak: override was called"; fail=1; }
: > "$LOG"; ! FAKE_FLATPAK_VERSION=unknown bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: non-numeric flatpak version accepted"; fail=1; }
! grep -q '^override' "$LOG" || { echo "FAIL: non-numeric flatpak version: override was called"; fail=1; }
: > "$LOG"; ! FAKE_FLATPAK_VERSION=1.20.abc bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: trailing-alpha flatpak version accepted"; fail=1; }
! grep -q '^override' "$LOG" || { echo "FAIL: trailing-alpha flatpak version: override was called"; fail=1; }

# a failing deny must abort before any grant; a failing info must abort before touching any override at all
overrides="$HOME/.local/share/flatpak/overrides"
printf 'original global\n' > "$overrides/global"
printf 'original Flatseal\n' > "$overrides/com.github.tchx84.Flatseal"
: > "$LOG"; ! FAKE_FAIL_ON='--nodevice=dri' bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: failed deny ignored"; fail=1; }
deny 'override --user --reset com.github.tchx84.Flatseal'
deny_app com.github.tchx84.Flatseal '--talk-name=org.freedesktop.impl.portal.PermissionStore'
grep -qxF 'original global' "$overrides/global" || { echo 'FAIL: failed write lost global overrides'; fail=1; }
: > "$LOG"; ! FAKE_FAIL_ON=--socket=wayland bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo 'FAIL: failed Flatseal write ignored'; fail=1; }
grep -qxF 'original Flatseal' "$overrides/com.github.tchx84.Flatseal" || { echo 'FAIL: failed write lost Flatseal overrides'; fail=1; }
[ -z "$(find "$overrides" -name '.lockdown.*' -print -quit)" ] || { echo 'FAIL: staging directory left behind'; fail=1; }
for query in list --show-metadata --show-permissions --show; do
    : > "$LOG"; ! FAKE_FAIL_ON="$query" bash "$root/lockdown.sh" > /dev/null 2>&1 || { echo "FAIL: failed $query ignored"; fail=1; }
    ! grep -q '^override --user ' "$LOG" || { echo "FAIL: overrides changed after failed $query"; fail=1; }
done

# cleanup must refuse to delete data if an instance is still running
: > "$LOG"; ! FAKE_STUCK_PS=1 bash "$root/cleanup.sh" > /dev/null 2>&1 < /dev/null || { echo "FAIL: stuck instance ignored"; fail=1; }
[ -f "$HOME/.var/app/org.a.App/data/x" ] || { echo "FAIL: data deleted while instance running"; fail=1; }

# cleanup must wipe data including chmod 000 directories and per-app runtime tmp/xdg-run/dev-shm
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
want 'document-unexport --doc-id -- doc1'
[ -z "$(ls -A "$HOME/.var/app")" ] || { echo "FAIL: ~/.var/app not empty"; fail=1; }
[ -z "$(ls -A "$XDG_RUNTIME_DIR/app")" ] || { echo "FAIL: runtime app dir not empty"; fail=1; }
[ ! -e "$XDG_RUNTIME_DIR/.flatpak/org.a.App/tmp" ] || { echo "FAIL: .flatpak tmp not wiped"; fail=1; }
[ ! -e "$XDG_RUNTIME_DIR/.flatpak/org.a.App/xdg-run" ] || { echo "FAIL: .flatpak xdg-run not wiped"; fail=1; }
[ ! -L "$XDG_RUNTIME_DIR/.flatpak/org.a.App/dev-shm" ] || { echo "FAIL: .flatpak dev-shm symlink not wiped"; fail=1; }
[ ! -e "$tmp/shm/flatpak-org.a.App-AbCdEf" ] || { echo "FAIL: per-app dev-shm not wiped"; fail=1; }
[ -d "$tmp/shm/flatpak-backups" ] && [ -d "$tmp/shm/flatpak-org.a.App-archive" ] || { echo 'FAIL: non-Flatpak shared memory name removed'; fail=1; }
[ -f "$tmp/shm/other-dir/keep" ] && [ -f "$tmp/shm-target/keep" ] || { echo "FAIL: cleanup touched something outside flatpak-* dirs"; fail=1; }
[ "$(stat -c %a "$XDG_RUNTIME_DIR/.flatpak/org.a.App/metadata")" = 500 ] || { echo 'FAIL: unrelated metadata permissions changed'; fail=1; }
[ -f "$XDG_RUNTIME_DIR/.flatpak/org.a.App/.ref" ] || { echo "FAIL: .flatpak .ref lockfile removed"; fail=1; }

# No documents is success; a portal error is partial cleanup, not success.
: > "$LOG"; FAKE_DOC_IDS='' sh "$root/cleanup.sh" > /dev/null < /dev/null
! grep -q '^document-unexport' "$LOG" || { echo 'FAIL: empty document ID unexported'; fail=1; }
for failure in 'documents --columns=id' doc1; do
    touch "$HOME/.var/app/local-data"; : > "$LOG"
    if out=$(FAKE_FAIL_ON="$failure" FAKE_DOC_IDS=$'doc1\ndoc2' sh "$root/cleanup.sh" 2>&1 < /dev/null); then
        echo 'FAIL: document portal error reported success'; fail=1
    fi
    [[ "$out" == *'本地数据已清理，但'* && "$out" != *'清理完成！'* ]] || { echo 'FAIL: inaccurate completion message'; fail=1; }
    [ ! -e "$HOME/.var/app/local-data" ] || { echo 'FAIL: portal failure skipped local cleanup'; fail=1; }
    if [ "$failure" = doc1 ]; then want 'document-unexport --doc-id -- doc2'; fi
done

# flatpak ps lists an already dead instance for up to 4s after its start: cleanup must wait it out without re-killing
: > "$LOG"; FAKE_PS_UNTIL=$(( $(date +%s) + 4 )) sh "$root/cleanup.sh" > /dev/null 2>&1 < /dev/null || { echo "FAIL: cleanup gave up on a dead instance still listed by flatpak ps"; fail=1; }
[ "$(grep -cxF 'kill 4343' "$LOG")" -eq 1 ] || { echo "FAIL: dead instance killed more than once"; fail=1; }

# cleanup must retry flatpak kill when child-pid was 0 during startup or when flatpak kill fails
: > "$LOG"; FAKE_PS_STARTUP="$tmp/startup" sh "$root/cleanup.sh" > /dev/null 2>&1 < /dev/null || { echo "FAIL: cleanup did not retry pre-bwrap or failed kill"; fail=1; }
[ "$(grep -cxF 'kill 4444' "$LOG")" -eq 3 ] || { echo "FAIL: expected 3 kill attempts for starting instance"; fail=1; }

# cleanup must not follow a symlinked $XDG_RUNTIME_DIR/app
mkdir -p "$tmp/outside"; touch "$tmp/outside/keep"
rmdir "$XDG_RUNTIME_DIR/app"; ln -s "$tmp/outside" "$XDG_RUNTIME_DIR/app"
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
[ -f "$tmp/outside/keep" ] || { echo "FAIL: followed symlinked XDG_RUNTIME_DIR/app"; fail=1; }

# cleanup must not follow a symlinked $XDG_RUNTIME_DIR/.flatpak either
mkdir -p "$tmp/outside2/org.a.App/tmp"; touch "$tmp/outside2/org.a.App/tmp/keep"
rm -rf "$XDG_RUNTIME_DIR/.flatpak"; ln -s "$tmp/outside2" "$XDG_RUNTIME_DIR/.flatpak"
: > "$LOG"; bash "$root/cleanup.sh" > /dev/null < /dev/null
[ -f "$tmp/outside2/org.a.App/tmp/keep" ] || { echo "FAIL: followed symlinked XDG_RUNTIME_DIR/.flatpak"; fail=1; }

# A relocated data directory is supported, but a misconfigured root is rejected before cleanup.
rmdir "$HOME/.var/app"; mkdir "$tmp/relocated-data"; touch "$tmp/relocated-data/local-data"
ln -s "$tmp/relocated-data" "$HOME/.var/app"; sh "$root/cleanup.sh" > /dev/null < /dev/null
[ ! -e "$tmp/relocated-data/local-data" ] || { echo 'FAIL: relocated app data not cleaned'; fail=1; }
rm "$HOME/.var/app"; ln -s "$HOME" "$HOME/.var/app"; : > "$LOG"
! sh "$root/cleanup.sh" > /dev/null 2>&1 < /dev/null || { echo 'FAIL: unsafe app data root accepted'; fail=1; }
[ ! -s "$LOG" ] || { echo 'FAIL: cleanup started before checking its data root'; fail=1; }

[ $fail = 0 ] && echo "all tests passed"
exit $fail
