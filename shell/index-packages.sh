#!/bin/sh
set -eu

# Build local Packages and Packages.gz for ImageBuilder packages/
# Usage: sh shell/index-packages.sh <IB_DIR>

IB_DIR=${1:-}
if [ -z "$IB_DIR" ]; then
  echo "Usage: $0 <IB_DIR>" >&2
  exit 2
fi

PKG_DIR="$IB_DIR/packages"
if [ ! -d "$PKG_DIR" ] || ! ls "$PKG_DIR"/*.ipk >/dev/null 2>&1; then
  echo "[index-packages] 无 .ipk，跳过索引"
  exit 0
fi

# Prefer host tool, then scripts fallbacks
INDEXER=""
if [ -x "$IB_DIR/staging_dir/host/bin/opkg-make-index" ]; then
  INDEXER="$IB_DIR/staging_dir/host/bin/opkg-make-index"
elif [ -x "$IB_DIR/staging_dir/host/bin/ipkg-make-index" ]; then
  INDEXER="$IB_DIR/staging_dir/host/bin/ipkg-make-index"
elif [ -f "$IB_DIR/scripts/opkg-make-index.py" ]; then
  INDEXER="python3 $IB_DIR/scripts/opkg-make-index.py"
elif [ -x "$IB_DIR/scripts/ipkg-make-index.sh" ]; then
  INDEXER="$IB_DIR/scripts/ipkg-make-index.sh"
fi

if [ -z "$INDEXER" ]; then
  echo "[index-packages] 未找到 opkg/ipkg 索引脚本或工具，跳过" >&2
  exit 0
fi

echo "[index-packages] 使用索引器: $INDEXER"
(
  cd "$PKG_DIR"
  # Some indexers require pointing at current dir
  # shellcheck disable=SC2086
  $INDEXER . > Packages
  gzip -9nc Packages > Packages.gz
)

echo "[index-packages] 已生成 packages/Packages(.gz)"

