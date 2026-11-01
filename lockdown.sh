#!/usr/bin/bash
set -euo pipefail

# Forked from https://github.com/secureblue/secureblue/blob/live/files/system/desktop/usr/libexec/secureblue/flatpak-permissions-lockdown 21d8fd869d1da9fb8a974bb8e503dc90bde8a087

kCommand="flatpak override --user"
kSharePermissions=("network" "ipc")
kSocketPermissions=("wayland" "inherit-wayland-socket" "gpg-agent" "cups" "pcsc" "ssh-auth" "system-bus" "session-bus" "pulseaudio" "x11" "fallback-x11")
kDevicePermissions=("all" "shm" "kvm" "input" "usb" "dri")
kFeaturePermissions=("per-app-dev-shm" "canbus" "bluetooth" "multiarch" "devel")
kFilesystemPermissions=("host:reset" "home" "host-etc" "host" "host-os")
kDangerousFilesystemPermissions=("xdg-data/flatpak/overrides" "~/.bashrc" "~/.bash_profile" "~/.bash_login" "~/.profile" "~/.zshrc" "~/.zprofile" "~/.zshenv" "~/.zlogin" "~/.zlogout" "~/.bash_logout" "~/.config/fish" "~/.config/autostart" "~/.config/systemd" "~/.config/environment.d" "~/.local/share/dbus-1/services" "~/.local/share/systemd" "~/.local/bin" "~/.ssh" "~/.gnupg" "~/.netrc" "~/.password-store" "/home" "/var/home" "/var" "/media" "/run/media" "/run" "/mnt" "xdg-config/kdeglobals" "xdg-run/gnupg" "xdg-download" "xdg-run/gvfs" "xdg-run/gvfsd" "~/.local/share/flatpak/overrides" "/var/lib/flatpak" "/root" "/boot" "~/.config/gnupg" "/run/docker.sock" "/run/podman" "/run/libvirt" "xdg-run/docker" "xdg-run/docker.sock" "xdg-run/podman" "xdg-run/containers" "xdg-run/libvirt" "xdg-run/keyring" "xdg-run/dconf" "xdg-run/at-spi" "xdg-run/hypr" "xdg-config/fish" "xdg-config/autostart" "xdg-config/systemd" "xdg-config/environment.d" "xdg-data/dbus-1/services" "xdg-data/systemd" "~/.local/share/applications" "xdg-data/applications" "xdg-run/pipewire-0")
kKnownSessionBusNames=("org.xfce.ScreenSaver" "org.mate.ScreenSaver" "org.cinnamon.ScreenSaver" "org.gnome.ScreenSaver" "org.kde.kwalletd6" "org.gnome.Mutter.IdleMonitor.*" "org.gnome.ControlCenter" "org.gnome.Settings" "org.gnome.SettingsDaemon.MediaKeys" "org.gnome.SessionManager" "org.gnome.Shell.Screenshot" "org.kde.kiod5" "org.kde.kwin.Screenshot" "org.kde.JobViewServer" "org.gtk.vfs.*" "org.freedesktop.secrets" "org.kde.kconfig.notify" "org.kde.kpasswdserver" "org.kde.*" "org.kde.StatusNotifierWatcher" "org.kde.kded6" "org.kde.kpasswdserver6" "org.kde.kiod6" "com.canonical.Unity" "org.freedesktop.Notifications" "org.freedesktop.FileManager1" "org.freedesktop.impl.portal.PermissionStore" "org.freedesktop.impl.portal.*" "org.freedesktop.impl.portal.Secret" "org.freedesktop.impl.portal.desktop.gnome" "org.freedesktop.impl.portal.desktop.gtk" "org.freedesktop.impl.portal.desktop.kde" "org.freedesktop.impl.portal.desktop.wlr" "org.freedesktop.impl.portal.desktop.hyprland" "org.freedesktop.impl.portal.desktop.cosmic" "org.freedesktop.impl.portal.desktop.lxqt" "org.freedesktop.impl.portal.desktop.xapp" "org.freedesktop.impl.portal.desktop.pantheon" "org.freedesktop.systemd1" "org.freedesktop.systemd1.*" "org.freedesktop.Flatpak.*" "org.freedesktop.Flatpak.Development" "org.freedesktop.Flatpak" "com.canonical.AppMenu.Registrar" "org.kde.KGlobalSettings" "org.kde.kded5" "com.canonical.Unity.LauncherEntry" "org.kde.kwalletd5" "org.gnome.SettingsDaemon" "org.a11y.Bus" "com.canonical.indicator.application" "org.freedesktop.ScreenSaver" "ca.desrt.dconf" "org.freedesktop.PowerManagement" "org.gnome.Software" "org.freedesktop.Tracker3.Writeback" "io.missioncenter.MissionCenter.Gatherer" "org.gnome.Shell" "org.gnome.Shell.Extensions" "org.gnome.Shell.Screencast" "org.gnome.Mutter.ScreenCast" "org.gnome.Mutter.DisplayConfig" "org.gnome.keyring" "org.gnome.keyring.SystemPrompter" "org.gnome.OnlineAccounts" "org.gnome.Nautilus" "org.gtk.vfs" "org.gtk.MountOperationHandler" "org.kde.KWin" "org.kde.kwin.Scripting" "org.kde.kwalletd" "org.kde.plasmashell" "org.kde.klipper" "org.kde.kglobalaccel" "org.kde.klauncher5" "org.kde.kdeconnect" "org.kde.baloo"       "org.xfce.FileManager" "org.xfce.SessionManager" "org.mate.SessionManager" "org.freedesktop.PackageKit" "org.freedesktop.login1" "org.freedesktop.Accounts" "org.freedesktop.IBus" "org.freedesktop.Tracker3.Miner.Files" "org.freedesktop.Tracker3.Miner.Files.Control" "org.freedesktop.Tracker3.Endpoint" "org.keepassxc.KeePassXC.BrowserServer" "org.freedesktop.impl.portal.desktop.darkman" "org.freedesktop.impl.portal.desktop.dde" "org.freedesktop.impl.portal.desktop.shana" "org.freedesktop.impl.portal.desktop.termfilechooser" "org.bluez.obex" "org.gnome.Sysprof3" "org.gnome.Shell.*" "org.kde.KWin.*" "org.a11y.*" "org.a11y.bus" "org.freedesktop.IBus.*" "org.freedesktop.NativeMessagingProxy" "org.ayatana.indicator.application" "com.system76.CosmicSettingsDaemon" "com.system76.CosmicSettingsDaemon.*" "org.freedesktop.Tracker1" "org.gnome.Mutter.IdleMonitor" "org.freedesktop.Flatpak.SystemHelper")
kKnownSystemBusNames=("org.bluez" "org.freedesktop.home1" "org.freedesktop.hostname1" "org.freedesktop.import1" "org.freedesktop.locale1" "org.freedesktop.LogControl1" "org.freedesktop.machine1" "org.freedesktop.network1" "org.freedesktop.oom1" "org.freedesktop.portable1" "org.freedesktop.resolve1" "org.freedesktop.sysupdate1" "org.freedesktop.timesync1" "org.freedesktop.timedate1" "org.freedesktop.systemd1" "org.freedesktop.Avahi" "org.freedesktop.Avahi.*" "org.freedesktop.login1" "org.freedesktop.NetworkManager" "org.freedesktop.UPower" "org.freedesktop.UDisks2" "org.freedesktop.fwupd" "org.freedesktop.Flatpak" "org.freedesktop.Flatpak.*" "org.freedesktop.Flatpak.SystemHelper" "org.freedesktop.systemd1.*" "org.freedesktop.Accounts" "org.freedesktop.PolicyKit1" "org.freedesktop.RealtimeKit1" "org.freedesktop.ModemManager1" "org.freedesktop.GeoClue2" "org.freedesktop.ColorManager" "org.freedesktop.ConsoleKit" "org.freedesktop.FileManager1" "org.freedesktop.Flatpak.Development" "org.fedoraproject.FirewallD1" "org.fedoraproject.FirewallD1.config" "net.reactivated.Fprint" "org.freedesktop.ratbag1" "org.bluez.*" "org.freedesktop.NetworkManager.*" "org.freedesktop.ModemManager1.*" "org.freedesktop.UPower.*" "org.freedesktop.UDisks2.*" "org.freedesktop.Udisks2" "org.freedesktop.GeoClue2.*" "net.hadess.SwitcherooControl")
kSubsystemPolicies=("Tracker3.dbus:org.freedesktop.Tracker3.Miner.Files=tracker:Audio" "Tracker3.dbus:org.freedesktop.Tracker3.Miner.Files=tracker:Pictures" "Tracker3.dbus:org.freedesktop.Tracker3.Miner.Files=tracker:Software")
kFlatsealSocketAccess=("wayland")
kFlatsealFilesystemAccess=("/var/lib/flatpak/app:ro" "xdg-data/flatpak/app:ro" "xdg-data/flatpak/overrides:create")
kFlatsealNameAccess=("org.freedesktop.impl.portal.PermissionStore")
kMinFlatpak=1.16.0   # --nousb=all (USB portal) needs it; older flatpak would abort halfway through
kFlatpakVersion=$(flatpak --version | awk '{print $2}')
if [ "$(printf '%s\n%s\n' "${kFlatpakVersion}" "${kMinFlatpak}" | sort -V | head -n1)" != "${kMinFlatpak}" ]; then
    echo "error: flatpak ${kFlatpakVersion:-unknown} is too old, need >= ${kMinFlatpak}; nothing was changed." >&2
    exit 1
fi
echo "This will configure flatpak to automatically reject most permissions, including the Wayland socket and the Dri device."
echo "This will also grant Flatseal access to certain permissions to allow them to operate and make reconfiguring much easier."
echo "NOTE: This will break just about all Flatpaks by default, it is ON YOU to configure them to work with this configuration."
echo ""
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
    echo "Note: This is a VERY flawed implementation but it does cover a few blatant sandbox escape methods (such as the .bashrc escape or mounted drive access)"
    echo "It is not possible to cover all files since each file can be requested manually and therefore must be rejected manually"
    for i in "${kDangerousFilesystemPermissions[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --nofilesystem="${i}"
    done
    echo "NOTE: The next 2 lockdowns are NOT complete and only cover a list of known names, this can be expanded at any time"
    echo "-- Session Bus Name Access --"
    for i in "${kKnownSessionBusNames[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --no-talk-name="${i}"
    done

    echo "-- System Bus Name Access --"
    for i in "${kKnownSystemBusNames[@]}"; do
        echo "	Rejecting ${i}..."
        ${kCommand} --system-no-talk-name="${i}"
    done

    echo "-- Bus Names And Policies Requested By Installed Apps --"
    echo "Note: --no-talk-name=foo.* only cancels a literal \"foo.*\" entry, it is not a glob, so the lists above can never be complete."
    echo "This also rejects every bus name and subsystem policy the apps installed right now ask for. Re-run this script after installing apps."
    flatpak list --app --columns=application | while IFS= read -r app; do
        flatpak info --show-permissions "${app}" < /dev/null
    done | awk -F= '
        /^\[/ { sec = $0; next }
        NF == 2 && $2 != "none" && sec == "[Session Bus Policy]" { print "--no-talk-name=" $1 }
        NF == 2 && $2 != "none" && sec == "[System Bus Policy]"  { print "--system-no-talk-name=" $1 }
        NF == 2 && sec ~ /^\[Policy .+\]$/ {
            n = split($2, v, ";")
            for (i = 1; i <= n; i++)
                if (v[i] != "" && v[i] !~ /^!/) print "--remove-policy=" substr(sec, 9, length(sec) - 9) "." $1 "=" v[i]
        }
    ' | sort -u | while IFS= read -r flag; do
        echo "	Rejecting ${flag#*=}..."
        ${kCommand} "${flag}" < /dev/null
    done

    echo "-- Granting Flatseal Access --"
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

    echo "Lockdown complete!"
