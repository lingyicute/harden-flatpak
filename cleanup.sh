#!/bin/sh
set -eu
(set -o pipefail) 2>/dev/null && set -o pipefail

app_data_dir="${HOME:?}/.var/app"

# ==========================================
# 1. 运行前状态展示
# ==========================================
echo "========== 运行前状态 =========="
echo ">>> flatpak documents --columns=all"
flatpak documents --columns=all || echo "(无法连接文档门户或当前无桌面会话)"

echo ""
echo ">>> ~/.var/app 目录内容"
ls -la "$app_data_dir" || echo "目录不存在"

# Portal 授权（通知、位置、麦克风等）既不在 override 里也不在 ~/.var/app 里，
# 而是在 ~/.local/share/flatpak/db/（xdg-permission-store）。本脚本未实施删除，
# 只显示出来，免得"清理完成"让人误以为 portal 授权也没了。
echo ""
echo ">>> flatpak permissions（portal 授权；本脚本不清理）"
flatpak permissions || true
echo "================================="
echo ""


# ==========================================
# 2. 执行清理操作
# ==========================================
echo "正在执行清理操作..."

# 杀掉所有实例并等它们真正退出；还有实例在跑就不删数据（以防它们把数据写回来）
# flatpak ps 只在 .ref 创建满 3 秒后才回收已退出的实例（st_mtime + 3 < now，最长约 4 秒），
# 所以刚启动的实例被杀后仍会被列出一阵子，这里至少要等 5 秒。
stop_instances() {
    for _ in $(seq 50); do
        instances=$(LC_ALL=C flatpak ps --columns=instance)
        [ -z "$instances" ] && return 0
        printf '%s\n' "$instances" | xargs -rn1 flatpak kill || true
        sleep 0.1
    done
    instances=$(LC_ALL=C flatpak ps --columns=instance)
    [ -z "$instances" ] && return 0
    echo "错误：仍有 Flatpak 实例在运行，未删除任何数据" >&2
    exit 1
}

# 加上 || true 防止 grep 没找到内容导致脚本中断
stop_instances
LC_ALL=C flatpak documents --columns=id | grep -v ' ' | xargs -rn1 flatpak document-unexport --doc-id || true
stop_instances

# -H：~/.var/app 本身是符号链接时也照常清理链接指向的目录
# 先恢复目录 u+rwx 权限，防止应用通过 chmod 000 锁死目录以逃避清理或导致脚本中断
if [ -d "$app_data_dir" ]; then
    find -H "$app_data_dir" -type d ! -perm -u=rwx -exec chmod u+rwx -- {} \;
    find -H "$app_data_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
fi

# 同一登录会话内的运行期应用状态 $XDG_RUNTIME_DIR/app/* 及 $XDG_RUNTIME_DIR/.flatpak/*/{tmp,xdg-run}
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR/app" ] && [ ! -L "$XDG_RUNTIME_DIR/app" ]; then
    find -P "$XDG_RUNTIME_DIR/app" -type d ! -perm -u=rwx -exec chmod u+rwx -- {} \;
    find -P "$XDG_RUNTIME_DIR/app" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
fi
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR/.flatpak" ] && [ ! -L "$XDG_RUNTIME_DIR/.flatpak" ]; then
    find -P "$XDG_RUNTIME_DIR/.flatpak" -type d ! -perm -u=rwx -exec chmod u+rwx -- {} \;
    find -P "$XDG_RUNTIME_DIR/.flatpak" -mindepth 2 -maxdepth 2 \( -name tmp -o -name xdg-run \) -exec rm -rf -- {} +
fi

echo "清理完成！"
echo ""


# ==========================================
# 3. 运行后状态展示
# ==========================================
echo "========== 运行后状态 =========="
echo ">>> flatpak documents --columns=all"
flatpak documents --columns=all || echo "(无法连接文档门户或当前无桌面会话)"

echo ""
echo ">>> ~/.var/app 目录内容"
ls -la "$app_data_dir" || echo "目录不存在"
echo "================================="
echo ""


# ==========================================
# 4. 等待用户回车退出
# ==========================================
if [ -t 0 ]; then
    printf "按回车键(Enter)退出..."
    read -r _ || true
fi
