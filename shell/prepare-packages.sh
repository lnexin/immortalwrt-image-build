#!/bin/sh

BASE_DIR="extra-packages"
TEMP_DIR="$BASE_DIR/temp-unpack"
TARGET_DIR="packages"

rm -rf "$TEMP_DIR" "$TARGET_DIR"
mkdir -p "$TEMP_DIR" "$TARGET_DIR"

# 解压 .run 文件
for run_file in "$BASE_DIR"/*.run; do
    [ -e "$run_file" ] || continue
    echo "解压 $run_file -> $TEMP_DIR"
    sh "$run_file" --target "$TEMP_DIR" --noexec
done

# 1) 收集 run 解包出的 .ipk
find "$TEMP_DIR" -type f -name "*.ipk" -exec cp -v {} "$TARGET_DIR"/ \;

# 2) 收集 extra-packages/*/ 下的 .ipk（排除临时目录）
find "$BASE_DIR" -mindepth 2 -maxdepth 2 -type f -name "*.ipk" ! -path "$TEMP_DIR/*" \
  -exec echo "Found:" {} \; \
  -exec cp -v {} "$TARGET_DIR"/ \;

echo "已汇总 .ipk 至 $TARGET_DIR/"
