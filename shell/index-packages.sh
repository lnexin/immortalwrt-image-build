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
INDEXER_IS_IPKG_SH=0
if [ -x "$IB_DIR/staging_dir/host/bin/opkg-make-index" ]; then
  INDEXER="$IB_DIR/staging_dir/host/bin/opkg-make-index"
elif [ -x "$IB_DIR/staging_dir/host/bin/ipkg-make-index" ]; then
  INDEXER="$IB_DIR/staging_dir/host/bin/ipkg-make-index"
elif [ -f "$IB_DIR/scripts/opkg-make-index.py" ]; then
  INDEXER="python3 $IB_DIR/scripts/opkg-make-index.py"
elif [ -x "$IB_DIR/scripts/ipkg-make-index.sh" ]; then
  INDEXER="$IB_DIR/scripts/ipkg-make-index.sh"
  INDEXER_IS_IPKG_SH=1
fi

if [ -z "$INDEXER" ]; then
  echo "[index-packages] 未找到 opkg/ipkg 索引脚本或工具，跳过" >&2
  exit 0
fi

echo "[index-packages] 使用索引器: $INDEXER"
(
  cd "$PKG_DIR"
  if [ "$INDEXER_IS_IPKG_SH" -eq 1 ]; then
    # ipkg-make-index.sh may hardcode 'sha256' command; provide a shim mapping to sha256sum
    TOOLS_DIR="$IB_DIR/.index-tools"
    mkdir -p "$TOOLS_DIR"
    cat >"$TOOLS_DIR/sha256" <<'EOS'
#!/bin/sh
exec sha256sum "$@"
EOS
    chmod +x "$TOOLS_DIR/sha256"
    # Prefer env var too, for variants honoring SHA256 variable
    # shellcheck disable=SC2086
    PATH="$TOOLS_DIR:$PATH" SHA256=sha256sum $INDEXER . > Packages
  else
    # shellcheck disable=SC2086
    $INDEXER . > Packages
  fi
  gzip -9nc Packages > Packages.gz
)

echo "[index-packages] 已生成 packages/Packages(.gz)"
