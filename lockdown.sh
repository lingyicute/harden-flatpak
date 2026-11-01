#!/usr/bin/bash
set -euo pipefail

# Forked from https://github.com/secureblue/secureblue/blob/live/files/system/desktop/usr/libexec/secureblue/flatpak-permissions-lockdown 21d8fd869d1da9fb8a974bb8e503dc90bde8a087

kCommand="flatpak override --user"
kSharePermissions=("network" "ipc")
kSocketPermissions=("wayland" "inherit-wayland-socket" "gpg-agent" "cups" "pcsc" "ssh-auth" "system-bus" "session-bus" "pulseaudio" "x11" "fallback-x11")
kDevicePermissions=("all" "shm" "kvm" "input" "usb" "dri")
kFeaturePermissions=("per-app-dev-shm" "canbus" "bluetooth" "multiarch" "devel")
kFilesystemPermissions=("host:reset" "home" "host-etc" "host" "host-os")
kDangerousFilesystemPermissions=("~/.bashrc" "~/.bash_profile" "/home" "/var/home" "/var" "/media" "/run/media" "/run" "/mnt" "xdg-config/kdeglobals" "xdg-run/gnupg" "xdg-download" "xdg-run/gvfs" "xdg-run/gvfsd")
kKnownSessionBusNames=("org.xfce.ScreenSaver" "org.mate.ScreenSaver" "org.cinnamon.ScreenSaver" "org.gnome.ScreenSaver" "org.kde.kwalletd6" "org.gnome.Mutter.IdleMonitor.*" "org.gnome.ControlCenter" "org.gnome.Settings" "org.gnome.SettingsDaemon.MediaKeys" "org.gnome.SessionManager" "org.gnome.Shell.Screenshot" "org.kde.kiod5" "org.kde.kwin.Screenshot" "org.kde.JobViewServer" "org.gtk.vfs.*" "org.freedesktop.secrets" "org.kde.kconfig.notify" "org.kde.kpasswdserver" "org.kde.*" "org.kde.StatusNotifierWatcher" "org.kde.kded6" "org.kde.kpasswdserver6" "org.kde.kiod6" "com.canonical.Unity" "org.freedesktop.Notifications" "org.freedesktop.FileManager1" "org.freedesktop.impl.portal.PermissionStore" "org.freedesktop.Flatpak" "com.canonical.AppMenu.Registrar" "org.kde.KGlobalSettings" "org.kde.kded5" "com.canonical.Unity.LauncherEntry" "org.kde.kwalletd5" "org.gnome.SettingsDaemon" "org.a11y.Bus" "com.canonical.indicator.application" "org.freedesktop.ScreenSaver" "ca.desrt.dconf" "org.freedesktop.PowerManagement" "org.gnome.Software" "org.freedesktop.Tracker3.Writeback" "io.missioncenter.MissionCenter.Gatherer")
kKnownSystemBusNames=("org.bluez" "org.freedesktop.home1" "org.freedesktop.hostname1" "org.freedesktop.import1" "org.freedesktop.locale1" "org.freedesktop.LogControl1" "org.freedesktop.machine1" "org.freedesktop.network1" "org.freedesktop.oom1" "org.freedesktop.portable1" "org.freedesktop.resolve1" "org.freedesktop.sysupdate1" "org.freedesktop.timesync1" "org.freedesktop.timedate1" "org.freedesktop.systemd1" "org.freedesktop.Avahi" "org.freedesktop.Avahi.*" "org.freedesktop.login1" "org.freedesktop.NetworkManager" "org.freedesktop.UPower" "org.freedesktop.UDisks2" "org.freedesktop.fwupd")
kFlatsealNameAccess=("org.freedesktop.impl.portal.PermissionStore")
echo "This will configure flatpak to automatically reject most permissions (with the exception of the Wayland socket and the Dri device, since these are commonly used and ensure at the very least most apps will work without crashing)."
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

    echo "-- Granting Flatseal Access to Bus Names --"
    for i in "${kFlatsealNameAccess[@]}"; do
        echo "	Granting ${i}..."
        ${kCommand} --talk-name="${i}" com.github.tchx84.Flatseal
    done

    echo "Lockdown complete!"
