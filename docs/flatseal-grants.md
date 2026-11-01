# Why Flatseal gets exactly these grants

`lockdown.sh` re-grants Flatseal (`com.github.tchx84.Flatseal`) only:

```bash
kFlatsealSocketAccess=("wayland")
kFlatsealFilesystemAccess=("/var/lib/flatpak/app:ro" "xdg-data/flatpak/app:ro" "xdg-data/flatpak/overrides:create")
kFlatsealNameAccess=("org.freedesktop.impl.portal.PermissionStore")
```

The inherited secureblue list also contained `org.gnome.Software`. It was dropped here
on purpose.

## Evidence

Measured against Flatseal 2.4.1 (stable) with this lockdown applied
to a throwaway user installation, and a 100-line stand-in for `org.freedesktop.impl.portal.PermissionStore` 
that logged every call. The results are:

| Flatseal override | result |
|---|---|
| lockdown only | app list **empty**: Flatseal needs the three filesystem paths from its own manifest |
| + the 3 filesystem paths, no `PermissionStore` | app list and detail pages work, no bus name needed. **Portals section greyed out**, 0 calls reached the store |
| + `PermissionStore`, no `org.gnome.Software` | Portals live: switches write e.g. `SetPermission('devices','microphone',APP,['yes'])`; only the *Show Details* button is greyed out |

## Verdict

- `org.freedesktop.impl.portal.PermissionStore`: **required** for the Portals page
  (background, notifications, microphone, speakers, camera, location).
- `org.gnome.Software`: **not required**. It only powers "Show Details".

`PermissionStore` does no authorization of its own, so any app that may talk to it can rewrite
every app's portal decisions. Flatseal is the one app where that is the whole point; that is
why `lockdown.sh` denies the name for everybody else.
