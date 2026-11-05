#!/bin/bash
# 安装 TabDoubleClick 到 ~/Applications 并启动
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/build/TabDoubleClick.app"
DEST="$HOME/Applications"

if [ ! -d "$APP" ]; then
  echo "未找到构建产物，先执行编译…"
  "$ROOT/scripts/build.sh"
fi

echo "==> 安装到 $DEST"
mkdir -p "$DEST"
if [ -d "$DEST/TabDoubleClick.app" ]; then
  BAK="$DEST/TabDoubleClick.app.bak-$(date +%Y%m%d%H%M%S)"
  mv "$DEST/TabDoubleClick.app" "$BAK"
  echo "    旧版本已备份: $BAK"
fi
cp -R "$APP" "$DEST/"
xattr -dr com.apple.quarantine "$DEST/TabDoubleClick.app" 2>/dev/null || true

echo "==> 启动"
open "$DEST/TabDoubleClick.app"

cat <<'TIP'

安装完成，还需一步授权：

  1) 首次启动会弹出辅助功能授权请求 → 点「打开系统设置」
  2) 系统设置 → 隐私与安全性 → 辅助功能 → 找到 TabDoubleClick
  3) 打开右侧开关（首次需输入开机密码，点「修改设置」）
  4) 授权后自动生效，无需重启

开机自启（可选）：
  系统设置 → 通用 → 登录项与扩展 → 点 + → 选择 ~/Applications/TabDoubleClick.app

TIP
