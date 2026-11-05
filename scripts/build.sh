#!/bin/bash
# 编译 TabDoubleClick.app
# 依赖：Xcode Command Line Tools（xcode-select --install）
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/build/TabDoubleClick.app"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "错误：未找到 swiftc。请先安装 Xcode 命令行工具："
  echo "  xcode-select --install"
  exit 1
fi

echo "==> 清理"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> 编译 Swift"
swiftc -O \
  -o "$APP/Contents/MacOS/TabDoubleClick" \
  "$ROOT/Sources/main.swift" \
  -framework Cocoa -framework ApplicationServices

echo "==> 组装 App 包"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> 签名（ad-hoc）"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --sign - --identifier com.local.tabdoubleclick "$APP"
codesign -v --verbose=2 "$APP" 2>&1 | sed 's/^/    /'

echo
echo "构建完成: $APP"
