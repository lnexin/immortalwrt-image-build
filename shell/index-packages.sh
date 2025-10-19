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

# Prefer robust tools if present; otherwise use a built-in generator
INDEXER=""
if [ -x "$IB_DIR/staging_dir/host/bin/opkg-make-index" ]; then
  INDEXER="$IB_DIR/staging_dir/host/bin/opkg-make-index"
elif [ -f "$IB_DIR/scripts/opkg-make-index.py" ]; then
  INDEXER="python3 $IB_DIR/scripts/opkg-make-index.py"
fi

generate_custom_index() {
  # Minimal, robust Packages generator avoiding fragile sed in ipkg-make-index.sh
  # Fields: control content + Filename/Size/MD5sum/SHA256sum
  : > Packages
  for f in *.ipk; do
    [ -f "$f" ] || continue
    CTRL=""
    if members=$(ar t "$f" 2>/dev/null); then
      for candidate in control.tar.gz control.tar.xz control.tar.zst control.tar.bz2 control.tar; do
        if printf '%s\n' "$members" | grep -Fqx "$candidate"; then
          case "$candidate" in
            control.tar.gz)
              CTRL=$(ar p "$f" "$candidate" 2>/dev/null \
                | tar -xzO ./control 2>/dev/null || true)
              ;;
            control.tar.xz)
              CTRL=$(ar p "$f" "$candidate" 2>/dev/null \
                | tar -xJO ./control 2>/dev/null || true)
              ;;
            control.tar.zst)
              CTRL=$(ar p "$f" "$candidate" 2>/dev/null \
                | tar --zstd -xO ./control 2>/dev/null || true)
              ;;
            control.tar.bz2)
              CTRL=$(ar p "$f" "$candidate" 2>/dev/null \
                | tar -xjO ./control 2>/dev/null || true)
              ;;
            control.tar)
              CTRL=$(ar p "$f" "$candidate" 2>/dev/null \
                | tar -xO ./control 2>/dev/null || true)
              ;;
          esac
          [ -n "$CTRL" ] && break
        fi
      done
    fi
    if [ -z "$CTRL" ]; then
      CTRL=$(tar -xzO -f "$f" ./control 2>/dev/null || true)
    fi
    if [ -z "$CTRL" ]; then
      CTRL=$(tar -xO -f "$f" ./control 2>/dev/null || true)
    fi
    if [ -z "$CTRL" ]; then
      echo "[index-packages] 跳过(无法读取 control): $f" >&2
      continue
    fi
    printf "%s\n" "$CTRL" >> Packages
    FILE_SIZE=$(wc -c <"$f" | tr -d ' ')
    MD5=$(md5sum "$f" | awk '{print $1}')
    SHA256=$(sha256sum "$f" | awk '{print $1}')
    printf "Filename: %s\n" "$f" >> Packages
    printf "Size: %s\n" "$FILE_SIZE" >> Packages
    printf "MD5sum: %s\n" "$MD5" >> Packages
    printf "SHA256sum: %s\n\n" "$SHA256" >> Packages
  done
  gzip -9nc Packages > Packages.gz
}

(
  cd "$PKG_DIR"
  if [ -n "$INDEXER" ]; then
    echo "[index-packages] 使用索引器: $INDEXER"
    # shellcheck disable=SC2086
    if ! $INDEXER . > Packages 2>/dev/null; then
      echo "[index-packages] 上述索引器失败，切换到内置生成器" >&2
      generate_custom_index
    else
      gzip -9nc Packages > Packages.gz
    fi
  else
    echo "[index-packages] 使用内置 Packages 生成器"
    generate_custom_index
  fi
)

echo "[index-packages] 已生成 packages/Packages(.gz)"
