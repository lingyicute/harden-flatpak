#!/bin/sh
set -euo pipefail

flatpak ps --columns=instance | xargs -rn1 flatpak kill
LC_ALL=C flatpak documents --columns=id | grep -v ' ' | xargs -rn1 flatpak document-unexport --doc-id
flatpak ps --columns=instance | xargs -rn1 flatpak kill
rm -rf ~/.var/app/org.gnome.Loupe ~/.var/app/com.vscodium.codium
