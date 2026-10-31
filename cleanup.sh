#!/bin/sh
set -euo pipefail

# ==========================================
# 1. 运行前状态展示
# ==========================================
echo "========== 运行前状态 =========="
echo ">>> flatpak documents --columns=all"
flatpak documents --columns=all

echo ""
echo ">>> ~/.var/app 目录内容"
# 使用 || true 防止如果目录不存在导致 set -e 报错退出
ls -la ~/.var/app || echo "目录不存在"
echo "================================="
echo ""


# ==========================================
# 2. 执行清理操作
# ==========================================
echo "正在执行清理操作..."
flatpak ps --columns=instance | xargs -rn1 flatpak kill
LC_ALL=C flatpak documents --columns=id | grep -v ' ' | xargs -rn1 flatpak document-unexport --doc-id
flatpak ps --columns=instance | xargs -rn1 flatpak kill
rm -rf ~/.var/app/org.gnome.Loupe ~/.var/app/com.vscodium.codium
echo "清理完成！"
echo ""


# ==========================================
# 3. 运行后状态展示
# ==========================================
echo "========== 运行后状态 =========="
echo ">>> flatpak documents --columns=all"
flatpak documents --columns=all

echo ""
echo ">>> ~/.var/app 目录内容"
ls -la ~/.var/app || echo "目录不存在"
echo "================================="
echo ""


# ==========================================
# 4. 等待用户回车退出
# ==========================================
# 使用 printf 和 read 确保兼容各种 sh (包括 bash 和 dash)
printf "按回车键(Enter)退出..."
read -r _
