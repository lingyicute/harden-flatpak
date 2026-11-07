#!/usr/bin/bash
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true
export LC_ALL=C

# Forked from https://github.com/secureblue/secureblue/blob/live/files/system/desktop/usr/libexec/secureblue/flatpak-permissions-lockdown 21d8fd869d1da9fb8a974bb8e503dc90bde8a087

kCommand="flatpak override --user"
kSharePermissions=("network" "ipc")
kSocketPermissions=("wayland" "inherit-wayland-socket" "gpg-agent" "cups" "pcsc" "ssh-auth" "system-bus" "session-bus" "pulseaudio" "x11" "fallback-x11")
kDevicePermissions=("all" "shm" "kvm" "input" "usb" "dri")
kFeaturePermissions=("per-app-dev-shm" "canbus" "bluetooth" "multiarch" "devel")
kFilesystemPermissions=("host:reset" "home" "host-etc" "host" "host-os")
kDangerousFilesystemPermissions=("xdg-data/flatpak/overrides" "~/.bashrc" "~/.bash_profile" "~/.bash_login" "~/.profile" "~/.zshrc" "~/.zprofile" "~/.zshenv" "~/.zlogin" "~/.zlogout" "~/.bash_logout" "~/.config/fish" "~/.config/autostart" "~/.config/systemd" "~/.config/environment.d" "~/.local/share/dbus-1/services" "~/.local/share/systemd" "~/.local/bin" "~/.ssh" "~/.gnupg" "~/.netrc" "~/.password-store" "/home" "/var/home" "/var" "/media" "/run/media" "/mnt" "xdg-config/kdeglobals" "xdg-run/gnupg" "xdg-download" "xdg-run/gvfs" "xdg-run/gvfsd" "~/.local/share/flatpak/overrides" "/var/lib/flatpak" "/root" "/boot" "~/.config/gnupg" "/run/docker.sock" "/run/podman" "/run/libvirt" "xdg-run/docker" "xdg-run/docker.sock" "xdg-run/podman" "xdg-run/containers" "xdg-run/libvirt" "xdg-run/keyring" "xdg-run/dconf" "xdg-run/at-spi" "xdg-run/hypr" "xdg-config/fish" "xdg-config/autostart" "xdg-config/systemd" "xdg-config/environment.d" "xdg-data/dbus-1/services" "xdg-data/systemd" "~/.local/share/applications" "xdg-data/applications" "xdg-run/pipewire-0" "xdg-run/bus" "xdg-run/wayland-0" "xdg-run/wayland-1" "xdg-run/ssh-agent" "xdg-run/openssh_agent" "xdg-config/gnupg" "~/.local/share/flatpak" "xdg-data/flatpak" "~/.local/share/keyrings" "xdg-data/keyrings" "~/.local/share/kwalletd" "xdg-data/kwalletd" "~/.bashrc.d" "~/.config/autostart-scripts" "xdg-config/autostart-scripts" "~/.config/plasma-workspace" "xdg-config/plasma-workspace" "~/.config/hypr" "xdg-config/hypr" "~/.config/sway" "xdg-config/sway" "~/.config/i3" "xdg-config/i3" "~/.local/share/gnome-shell" "xdg-data/gnome-shell" "~/.local/share/nautilus-python" "xdg-data/nautilus-python" "~/.pki" "~/.config/git" "xdg-config/git" "~/.aws" "~/.kube" "~/.docker" "~/.config/containers" "xdg-config/containers" "xdg-run/systemd" "xdg-run/dbus-1" "xdg-run/pulse" "xdg-run/gcr" "xdg-run/p11-kit" "xdg-run/speech-dispatcher" "~/.local/share/nautilus/scripts" "xdg-data/nautilus/scripts" "~/.local/share/nemo/scripts" "xdg-data/nemo/scripts" "~/.local/share/nemo/actions" "xdg-data/nemo/actions" "~/.local/share/nemo-python" "xdg-data/nemo-python" "~/.local/share/caja/scripts" "xdg-data/caja/scripts" "~/.local/share/caja-python" "xdg-data/caja-python" "~/.local/share/kio/servicemenus" "xdg-data/kio/servicemenus" "~/.local/share/kwin" "xdg-data/kwin" "~/.local/share/plasma" "xdg-data/plasma" "~/.config/zsh" "xdg-config/zsh" "~/.config/uwsm" "xdg-config/uwsm" "~/.config/gh" "xdg-config/gh" "~/.config/glab-cli" "xdg-config/glab-cli" "~/.config/rclone" "xdg-config/rclone" "~/.config/gopass" "xdg-config/gopass" "~/.local/share/gopass" "xdg-data/gopass" "~/.config/age" "xdg-config/age" "~/.config/sops" "xdg-config/sops" "~/.config/gcloud" "xdg-config/gcloud" "~/.azure" "~/.cargo" "~/.vscode" "~/.config/Code" "xdg-config/Code" "~/.config/VSCodium" "xdg-config/VSCodium" "~/.npm" "~/.yarn" "~/.local/share/pnpm" "xdg-data/pnpm" "~/.m2" "~/.gradle" "~/.config/pip" "xdg-config/pip" "~/.mozilla" "~/.config/google-chrome" "xdg-config/google-chrome" "~/.config/chromium" "xdg-config/chromium" "~/.config/BraveSoftware" "xdg-config/BraveSoftware")
kKnownSessionBusNames=("org.xfce.ScreenSaver" "org.mate.ScreenSaver" "org.cinnamon.ScreenSaver" "org.gnome.ScreenSaver" "org.kde.kwalletd6" "org.gnome.Mutter.IdleMonitor.*" "org.gnome.ControlCenter" "org.gnome.Settings" "org.gnome.SettingsDaemon.MediaKeys" "org.gnome.SessionManager" "org.gnome.Shell.Screenshot" "org.kde.kiod5" "org.kde.kwin.Screenshot" "org.kde.JobViewServer" "org.gtk.vfs.*" "org.freedesktop.secrets" "org.kde.kconfig.notify" "org.kde.kpasswdserver" "org.kde.*" "org.kde.StatusNotifierWatcher" "org.kde.kded6" "org.kde.kpasswdserver6" "org.kde.kiod6" "com.canonical.Unity" "org.freedesktop.Notifications" "org.freedesktop.FileManager1" "org.freedesktop.impl.portal.PermissionStore" "org.freedesktop.impl.portal.*" "org.freedesktop.impl.portal.Secret" "org.freedesktop.impl.portal.desktop.gnome" "org.freedesktop.impl.portal.desktop.gtk" "org.freedesktop.impl.portal.desktop.kde" "org.freedesktop.impl.portal.desktop.wlr" "org.freedesktop.impl.portal.desktop.hyprland" "org.freedesktop.impl.portal.desktop.cosmic" "org.freedesktop.impl.portal.desktop.lxqt" "org.freedesktop.impl.portal.desktop.xapp" "org.freedesktop.impl.portal.desktop.pantheon" "org.freedesktop.systemd1" "org.freedesktop.systemd1.*" "org.freedesktop.Flatpak.*" "org.freedesktop.Flatpak.Development" "org.freedesktop.Flatpak" "com.canonical.AppMenu.Registrar" "org.kde.KGlobalSettings" "org.kde.kded5" "com.canonical.Unity.LauncherEntry" "org.kde.kwalletd5" "org.gnome.SettingsDaemon" "org.a11y.Bus" "com.canonical.indicator.application" "org.freedesktop.ScreenSaver" "ca.desrt.dconf" "org.freedesktop.PowerManagement" "org.gnome.Software" "org.freedesktop.Tracker3.Writeback" "io.missioncenter.MissionCenter.Gatherer" "org.gnome.Shell" "org.gnome.Shell.Extensions" "org.gnome.Shell.Screencast" "org.gnome.Mutter.ScreenCast" "org.gnome.Mutter.DisplayConfig" "org.gnome.keyring" "org.gnome.keyring.SystemPrompter" "org.gnome.OnlineAccounts" "org.gnome.Nautilus" "org.gtk.vfs" "org.gtk.MountOperationHandler" "org.kde.KWin" "org.kde.kwin.Scripting" "org.kde.kwalletd" "org.kde.plasmashell" "org.kde.klipper" "org.kde.kglobalaccel" "org.kde.klauncher5" "org.kde.kdeconnect" "org.kde.baloo"       "org.xfce.FileManager" "org.xfce.SessionManager" "org.mate.SessionManager" "org.freedesktop.PackageKit" "org.freedesktop.login1" "org.freedesktop.Accounts" "org.freedesktop.IBus" "org.freedesktop.Tracker3.Miner.Files" "org.freedesktop.Tracker3.Miner.Files.Control" "org.freedesktop.Tracker3.Endpoint" "org.keepassxc.KeePassXC.BrowserServer" "org.freedesktop.impl.portal.desktop.darkman" "org.freedesktop.impl.portal.desktop.dde" "org.freedesktop.impl.portal.desktop.shana" "org.freedesktop.impl.portal.desktop.termfilechooser" "org.bluez.obex" "org.gnome.Sysprof3" "org.gnome.Shell.*" "org.kde.KWin.*" "org.a11y.*" "org.a11y.bus" "org.freedesktop.IBus.*" "org.freedesktop.NativeMessagingProxy" "org.ayatana.indicator.application" "com.system76.CosmicSettingsDaemon" "com.system76.CosmicSettingsDaemon.*" "org.freedesktop.Tracker1" "org.gnome.Mutter.IdleMonitor" "org.freedesktop.Flatpak.SystemHelper" "org.gnome.evolution.dataserver.AddressBook9" "org.gnome.evolution.dataserver.AddressBook10" "org.gnome.evolution.dataserver.Calendar7" "org.gnome.evolution.dataserver.Calendar8" "org.gnome.evolution.dataserver.Sources5" "org.freedesktop.Akonadi" "org.gnome.SettingsDaemon.Color" "org.gnome.SettingsDaemon.Power" "org.gnome.SettingsDaemon.Housekeeping" "org.freedesktop.Telepathy.AccountManager" "org.freedesktop.Telepathy.MissionControl5" "org.freedesktop.UPower" "org.freedesktop.NetworkManager" "org.freedesktop.Avahi" "org.freedesktop.StatusNotifierWatcher" "org.freedesktop.StatusNotifierItem" "org.kde.StatusNotifierItem" "com.canonical.AppIndicator" "com.canonical.dbusmenu" "com.canonical.Unity.Launcher" "com.canonical.Unity.Session" "org.freedesktop.thumbnails.Thumbnailer1" "org.freedesktop.ReserveDevice1.*" "org.freedesktop.PowerManagement.Inhibit" "org.freedesktop.FileManager1.*" "org.freedesktop.Akonadi.*" "org.freedesktop.Telepathy.ChannelDispatcher" "org.gnome.Notifications" "org.gtk.Notifications" "org.gnome.SessionManager.Presence" "org.gnome.evolution.dataserver.*" "org.gnome.GConf" "org.mate.SettingsDaemon" "org.kde.kuiserver" "org.kde.knotify" "org.kde.ScreenSaver" "org.kde.Solid.PowerManagement" "org.kde.kdeconnectd" "org.kde.Shutdown" "org.kde.LogoutPrompt" "org.kde.kssld5" "org.kde.kssld6" "org.kde.kcookiejar5" "org.kde.KWin.NightLight" "org.kde.keyboard" "org.kde.pim.*" "org.mpris.MediaPlayer2.*" "org.gnome.evolution.dataserver.Subprocess.Backend.*" "com.canonical.AppMenu.Registrar.*" "com.feralinteractive.GameMode" "org.unifiedpush.Distributor.*" "org.gnome.Settings.*" "org.gnome.SettingsDaemon.*" "org.gnome.SessionManager.*" "org.gnome.ControlCenter.*" "org.gnome.keyring.*" "org.gnome.OnlineAccounts.*" "org.freedesktop.Tracker3.*" "org.kde.plasmashell.*" "org.kde.kdeconnect.*" "org.freedesktop.impl.portal.desktop.xfce" "org.gnome.Mutter.RemoteDesktop" "org.gnome.Mutter.*" "org.gnome.Shell.Introspect" "org.freedesktop.secrets.*" "org.freedesktop.PackageKit.*" "org.fcitx.Fcitx" "org.fcitx.Fcitx.*" "org.fcitx.Fcitx5" "org.fcitx.Fcitx5.*")
kKnownSystemBusNames=("org.bluez" "org.freedesktop.home1" "org.freedesktop.hostname1" "org.freedesktop.import1" "org.freedesktop.locale1" "org.freedesktop.LogControl1" "org.freedesktop.machine1" "org.freedesktop.network1" "org.freedesktop.oom1" "org.freedesktop.portable1" "org.freedesktop.resolve1" "org.freedesktop.sysupdate1" "org.freedesktop.timesync1" "org.freedesktop.timedate1" "org.freedesktop.systemd1" "org.freedesktop.Avahi" "org.freedesktop.Avahi.*" "org.freedesktop.login1" "org.freedesktop.NetworkManager" "org.freedesktop.UPower" "org.freedesktop.UDisks2" "org.freedesktop.fwupd" "org.freedesktop.Flatpak" "org.freedesktop.Flatpak.*" "org.freedesktop.Flatpak.SystemHelper" "org.freedesktop.systemd1.*" "org.freedesktop.Accounts" "org.freedesktop.PolicyKit1" "org.freedesktop.RealtimeKit1" "org.freedesktop.ModemManager1" "org.freedesktop.GeoClue2" "org.freedesktop.ColorManager" "org.freedesktop.ConsoleKit" "org.freedesktop.FileManager1" "org.freedesktop.Flatpak.Development" "org.fedoraproject.FirewallD1" "org.fedoraproject.FirewallD1.config" "net.reactivated.Fprint" "org.freedesktop.ratbag1" "org.bluez.*" "org.freedesktop.NetworkManager.*" "org.freedesktop.ModemManager1.*" "org.freedesktop.UPower.*" "org.freedesktop.UDisks2.*" "org.freedesktop.Udisks2" "org.freedesktop.GeoClue2.*" "net.hadess.SwitcherooControl" "com.redhat.tuned" "net.openvpn.v3.configuration" "net.openvpn.v3.log" "net.openvpn.v3.sessions" "org.bluez.obex" "org.gnome.Sysprof3" "org.freedesktop.Accounts.*" "org.freedesktop.PolicyKit1.*" "org.freedesktop.login1.*" "org.freedesktop.hostname1.*" "org.freedesktop.timedate1.*" "org.freedesktop.resolve1.*" "org.freedesktop.network1.*" "org.freedesktop.machine1.*" "org.freedesktop.home1.*" "org.freedesktop.import1.*" "org.freedesktop.portable1.*" "org.freedesktop.sysupdate1.*" "org.freedesktop.fwupd.*" "org.fedoraproject.FirewallD1.*" "org.freedesktop.bolt" "org.freedesktop.PackageKit" "org.freedesktop.PackageKit.*" "net.hadess.PowerProfiles" "net.hadess.PowerProfiles.*" "org.freedesktop.UPower.PowerProfiles" "org.freedesktop.UPower.PowerProfiles.*" "net.hadess.SensorProxy" "net.hadess.SensorProxy.*" "org.freedesktop.bolt.*" "org.freedesktop.ColorManager.*" "org.freedesktop.RealtimeKit1.*" "org.freedesktop.locale1.*" "org.freedesktop.timesync1.*" "org.freedesktop.oom1.*" "org.freedesktop.LogControl1.*")
kSubsystemPolicies=("Tracker3.dbus:org.freedesktop.Tracker3.Miner.Files=tracker:Audio" "Tracker3.dbus:org.freedesktop.Tracker3.Miner.Files=tracker:Pictures" "Tracker3.dbus:org.freedesktop.Tracker3.Miner.Files=tracker:Software")
kFlatsealSocketAccess=("wayland")
kFlatsealFilesystemAccess=("/var/lib/flatpak/app:ro" "xdg-data/flatpak/app:ro" "xdg-data/flatpak/overrides:create")
kFlatsealNameAccess=("org.freedesktop.impl.portal.PermissionStore")
kMinFlatpak=1.16.0   # --nousb needs 1.16
ver_ge() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)+$ ]] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]; }
kFlatpakVersion=$(flatpak --version | awk 'NR==1 {print $2}')
if ! ver_ge "${kFlatpakVersion}" "${kMinFlatpak}"; then
    echo "error: flatpak ${kFlatpakVersion:-unknown} is too old, need >= ${kMinFlatpak}; nothing was changed." >&2
    exit 1
fi
if ver_ge "${kFlatpakVersion}" 1.17.0; then kFilesystemPermissions+=("host-root"); fi   # 1.16 rejects host-root
echo "This will configure flatpak to automatically reject most permissions, including the Wayland socket and the Dri device."
echo "This will also grant Flatseal access to certain permissions to allow them to operate and make reconfiguring much easier."
echo "NOTE: This will break just about all Flatpaks by default, it is ON YOU to configure them to work with this configuration."
echo ""
    echo "-- Resetting Global Overrides --"
    ${kCommand} --reset

    echo "-- Share Permissions --"
    for i in "${kSharePermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --unshare="${i}"
    done

    echo "-- Socket Permissions --"
    for i in "${kSocketPermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --nosocket="${i}"
    done

    echo "-- Device Permissions --"
    for i in "${kDevicePermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --nodevice="${i}"
    done

    echo "-- Feature Permissions --"
    for i in "${kFeaturePermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --disallow="${i}"
    done

    echo "-- USB Portal Permissions --"
    echo "	Rejecting all..."
    ${kCommand} --nousb=all

    echo "-- Subsystem Policies --"
    for i in "${kSubsystemPolicies[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --remove-policy="${i}"
    done

    echo "-- Filesystem Permissions --"
    for i in "${kFilesystemPermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --nofilesystem="${i}"
    done

    echo "-- Dangerous Filesystem Permissions --"
    echo "Note: This is a VERY flawed implementation. Flatpak only masks existing directories (with a tmpfs); files and sockets are never masked,"
    echo "and top-level dirs (/mnt, /media, /run/media, /home) stay visible under host. These entries only cancel explicit per-path grants (e.g. from an app manifest)."
    echo "With --filesystem=home or host an app can still read and write ~/.bashrc and similar files. It is not possible to cover all paths, each must be rejected manually."
    for i in "${kDangerousFilesystemPermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --nofilesystem="${i}"
    done
    echo "NOTE: The next lockdown is NOT complete and only covers a list of known names, this can be expanded at any time"
    echo "-- Session Bus Name Access --"
    for i in "${kKnownSessionBusNames[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --no-talk-name="${i}"
    done

    echo "-- Bus Names And Policies Requested By Installed Apps --"
    echo "Note: --no-talk-name=foo.* only cancels a literal \"foo.*\" entry, it is not a glob, so the lists above can never be complete."
    echo "This also rejects every session bus name and subsystem policy the apps installed right now ask for. Re-run this script after installing apps."
    echo "System bus names are rejected per app, and only for apps that already declare a system bus policy. A global --system-no-talk-name entry"
    echo "would make flatpak start a system bus proxy and mount /run/dbus/system_bus_socket in every app, even those that never used the system bus."
    global_flags=""
    # Read every installation separately: the same ref can exist in user and system, and
    # 'flatpak info' without a selector only sees the user one. --show-metadata is the raw
    # manifest, --show-permissions is the merge with all overrides and hides names an override
    # already set to none, so a later override reset would bring those names back.
    installed_apps=$(flatpak list --app --columns=installation,ref | sort -u)
    while IFS=$'\t' read -r inst ref; do
        [ -n "${ref}" ] || continue
        case "${inst}" in
            user) sel=(--user) ;;
            system) sel=(--system) ;;
            "system ("*")") inst=${inst#"system ("}; sel=("--installation=${inst%")"}") ;;
            *) echo "error: unknown flatpak installation: ${inst}" >&2; exit 1 ;;
        esac
        perms=$(
            flatpak info "${sel[@]}" --show-metadata "${ref}" < /dev/null
            echo
            flatpak info "${sel[@]}" --show-permissions "${ref}" < /dev/null
        )
        app_flags=$(awk '
            /^[[:space:]]*(#|$)/ { next }
            /^\[/ { sec = $0; next }
            (idx = index($0, "=")) > 1 {
                k = substr($0, 1, idx - 1)
                val = substr($0, idx + 1)
                if (val != "none" && sec == "[Session Bus Policy]") print "--no-talk-name=" k
                else if (val != "none" && sec == "[System Bus Policy]") print "--system-no-talk-name=" k
                else if (sec ~ /^\[Policy .+\]$/) {
                    n = split(val, v, ";")
                    for (i = 1; i <= n; i++)
                        if (v[i] != "" && v[i] !~ /^!/) print "--remove-policy=" substr(sec, 9, length(sec) - 9) "." k "=" v[i]
                }
            }
        ' <<< "${perms}" | sort -u)
        global_flags+=$(grep -v '^--system-no-talk-name=' <<< "${app_flags}" || true)$'\n'
        system_args=()
        while IFS= read -r flag; do
            [ -z "${flag}" ] || system_args+=("${flag}")
        done < <(grep '^--system-no-talk-name=' <<< "${app_flags}" || true)
        if [ "${#system_args[@]}" -gt 0 ]; then
            for i in "${kKnownSystemBusNames[@]}"; do system_args+=("--system-no-talk-name=${i}"); done
            echo "\tRejecting system bus names for ${ref%%/*}..."
            ${kCommand} "${system_args[@]}" "${ref%%/*}" < /dev/null
        fi
    done <<< "${installed_apps}"
    installed_flags=$(printf '%s\n' "${global_flags}" | sort -u)
    while IFS= read -r flag; do
        [ -z "${flag}" ] && continue
        echo "	Rejecting ${flag#*=}..."
        ${kCommand} "${flag}" < /dev/null
    done <<< "${installed_flags}"

    echo "-- Granting Flatseal Access --"
    echo "	Resetting Flatseal overrides..."
    ${kCommand} --reset com.github.tchx84.Flatseal
    for i in "${kFlatsealSocketAccess[@]}"; do
        echo "	Granting socket ${i}..."
        ${kCommand} --socket="${i}" com.github.tchx84.Flatseal
    done
    for i in "${kFlatsealFilesystemAccess[@]}"; do
        echo "	Granting filesystem ${i}..."
        ${kCommand} --filesystem="${i}" com.github.tchx84.Flatseal
    done
    for i in "${kFlatsealNameAccess[@]}"; do
        echo "	Granting ${i}..."
        ${kCommand} --talk-name="${i}" com.github.tchx84.Flatseal
    done

    echo "-- Per-app Overrides (these still win over everything above; inspect: flatpak override --user --show APP_ID) --"
    echo "Note: apps that got the system bus denies above are listed too."
    ls -A "${FLATPAK_USER_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/flatpak}/overrides" 2>/dev/null | grep -vxF -e global -e com.github.tchx84.Flatseal || echo "	none"

    echo "Lockdown complete!"
