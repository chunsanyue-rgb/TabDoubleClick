#!/bin/bash
# 编译 TabDoubleClick.app
# 依赖：Xcode Command Line Tools（xcode-select --install）
# 默认尝试构建 arm64 + x86_64 的 Universal 二进制；任一架构不可用时自动退回本机架构
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/build/TabDoubleClick.app"
BIN="$APP/Contents/MacOS/TabDoubleClick"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "错误：未找到 swiftc。请先安装 Xcode 命令行工具："
  echo "  xcode-select --install"
  exit 1
fi

echo "==> 清理"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

compile() {  # $1=arch $2=out
  swiftc -O -target "$1-apple-macos12.0" \
    -o "$2" "$ROOT/Sources/main.swift" \
    -framework Cocoa -framework ApplicationServices >/dev/null 2>&1
}

echo "==> 编译 Swift"
TMP_A=$(mktemp -d)
OK_A=0; OK_I=0
compile arm64 "$TMP_A/arm64" && OK_A=1 || echo "    arm64 编译失败"
compile x86_64 "$TMP_A/x86_64" && OK_I=1 || echo "    x86_64 编译失败（本机 SDK 不支持交叉编译，将只产出单架构）"

if [ "$OK_A" = 1 ] && [ "$OK_I" = 1 ]; then
  lipo -create -output "$BIN" "$TMP_A/arm64" "$TMP_A/x86_64"
  echo "    → Universal (arm64 + x86_64)"
elif [ "$OK_A" = 1 ]; then
  cp "$TMP_A/arm64" "$BIN"; echo "    → 仅 arm64"
elif [ "$OK_I" = 1 ]; then
  cp "$TMP_A/x86_64" "$BIN"; echo "    → 仅 x86_64"
else
  # 最后兜底：完全交给本机默认架构
  swiftc -O -o "$BIN" "$ROOT/Sources/main.swift" -framework Cocoa -framework ApplicationServices
  echo "    → 本机默认架构 ($(uname -m))"
fi
chmod +x "$BIN"
rm -rf "$TMP_A"

echo "==> 组装 App 包"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> 签名（ad-hoc）"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --sign - --identifier com.local.tabdoubleclick "$APP"
codesign -v --verbose=2 "$APP" 2>&1 | sed 's/^/    /'

echo
file "$BIN" | sed 's/^/    /'
echo "构建完成: $APP"
