#!/usr/bin/env bash
set -euo pipefail

# x86_64 ImmortalWrt 24.10.3 → Docker 镜像构建

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
WORK_DIR="$SCRIPT_DIR/work"
OUTPUT_DIR="$SCRIPT_DIR/output"
FILES_DIR="$SCRIPT_DIR/files"

VERSION="24.10.3"
IMAGEBUILDER_URL_DEFAULT="https://downloads.immortalwrt.org/releases/${VERSION}/targets/x86/64/immortalwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64.tar.zst"
IMAGEBUILDER_URL="${IMAGEBUILDER_URL:-$IMAGEBUILDER_URL_DEFAULT}"
WGET_OPTS="--tries=3 --timeout=30 --retry-connrefused"

# Docker 标签
DOCKER_TAG1_DEFAULT="immortalwrt/x86-64:24.10"
DOCKER_TAG2_DEFAULT="immortalwrt/x86-64:${VERSION}"
DOCKER_TAG1="${DOCKER_TAG1:-$DOCKER_TAG1_DEFAULT}"
DOCKER_TAG2="${DOCKER_TAG2:-$DOCKER_TAG2_DEFAULT}"

# 构建参数（可通过环境变量覆盖）
PROFILE="${PROFILE:-1024}"
INCLUDE_DOCKER="${INCLUDE_DOCKER:-no}"
ENABLE_PPPOE="${ENABLE_PPPOE:-no}"
PPPOE_ACCOUNT="${PPPOE_ACCOUNT:-}"
PPPOE_PASSWORD="${PPPOE_PASSWORD:-}"
CUSTOM_PACKAGES="${CUSTOM_PACKAGES:-}"
# 兼容命名：ROOTFS_PARTSIZE 优先，未提供则沿用 PROFILE 数值
ROOTFS_PARTSIZE="${ROOTFS_PARTSIZE:-$PROFILE}"
# 可选：注入自定义路由器 IP（供 99-custom.sh 读取）
CUSTOM_ROUTER_IP="${CUSTOM_ROUTER_IP:-}"

DOCKER_BUILD=0
while getopts ":dt:" opt; do
  case $opt in
    d) DOCKER_BUILD=1 ;;
    t) DOCKER_TAG1="$OPTARG" ;;
    *) ;;
  esac
done

echo "[immortalwrt-image-build] VERSION=$VERSION"
echo "[immortalwrt-image-build] PROFILE=$PROFILE ROOTFS_PARTSIZE=${ROOTFS_PARTSIZE:-$PROFILE} INCLUDE_DOCKER=$INCLUDE_DOCKER"
echo "[immortalwrt-image-build] ENABLE_PPPOE=$ENABLE_PPPOE"
echo "[immortalwrt-image-build] IMAGEBUILDER_URL=$IMAGEBUILDER_URL"
echo "[immortalwrt-image-build] DOCKER_TAGS=$DOCKER_TAG1,$DOCKER_TAG2 (build=$DOCKER_BUILD)"

mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

IB_EXT="${IMAGEBUILDER_URL##*.}"
IB_TAR="$WORK_DIR/ib.tar.$IB_EXT"
if [ ! -f "$IB_TAR" ]; then
  echo "[immortalwrt-image-build] 下载 ImageBuilder..."
  wget $WGET_OPTS -qO "$IB_TAR" "$IMAGEBUILDER_URL"
fi

echo "[immortalwrt-image-build] 解压 ImageBuilder..."
case "$IB_EXT" in
  zst)
    tar --zstd -xf "$IB_TAR" -C "$WORK_DIR" ;;
  xz)
    tar -xJf "$IB_TAR" -C "$WORK_DIR" ;;
  *)
    tar -xf "$IB_TAR" -C "$WORK_DIR" ;;
esac
IB_DIR=$(find "$WORK_DIR" -maxdepth 1 -type d -name "immortalwrt-imagebuilder-*x86-64*" | head -n 1)
if [ -z "${IB_DIR:-}" ]; then
  echo "[immortalwrt-image-build] 未找到解压后的 ImageBuilder 目录" >&2
  exit 1
fi

# 准备覆盖层 files
echo "[immortalwrt-image-build] 同步覆盖层 files → ImageBuilder/files"
rm -rf "$IB_DIR/files"
mkdir -p "$IB_DIR/files"
cp -a "$FILES_DIR"/. "$IB_DIR/files/"

# 写入 PPPoE 设置（供 99-custom.sh 首启使用）
mkdir -p "$IB_DIR/files/etc/config"
cat > "$IB_DIR/files/etc/config/pppoe-settings" <<EOF
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

# 可选：通过环境变量注入自定义路由器 IP
if [ -n "${CUSTOM_ROUTER_IP:-}" ]; then
  echo "$CUSTOM_ROUTER_IP" > "$IB_DIR/files/etc/config/custom_router_ip.txt"
  echo "[immortalwrt-image-build] 已写入自定义路由器 IP: $CUSTOM_ROUTER_IP"
fi

# 拉取第三方包（run/ipk）并汇总到 packages/
echo "[immortalwrt-image-build] 拉取第三方包（store/run/x86）..."
TMP_STORE="$WORK_DIR/store-run-repo"
rm -rf "$TMP_STORE"
git clone --depth=1 https://github.com/wukongdaily/store.git "$TMP_STORE"
mkdir -p "$IB_DIR/extra-packages"
cp -r "$TMP_STORE/run/x86"/* "$IB_DIR/extra-packages/" || true
echo "[immortalwrt-image-build] 汇总 .ipk 至 ImageBuilder/packages"
( cd "$IB_DIR" && sh "$SCRIPT_DIR/shell/prepare-packages.sh" )
# 如存在本地 IPK，则为 packages/ 建立索引（兼容不同 IB 版本）
if [ -d "$IB_DIR/packages" ] && ls "$IB_DIR/packages"/*.ipk >/dev/null 2>&1; then
  echo "[immortalwrt-image-build] 为本地 packages 建立索引"
  sh "$SCRIPT_DIR/shell/index-packages.sh" "$IB_DIR"
fi

# 包列表（与仓库 x86-64/build24.sh 对齐，可根据需要增删）
PACKAGES=""
# helper to append pkg only if local ipk exists
add_if_local() {
  pkg="$1"
  if ls "$IB_DIR/packages/${pkg}_"*.ipk >/dev/null 2>&1; then
    PACKAGES="$PACKAGES $pkg"
  else
    echo "[immortalwrt-image-build] 跳过(未找到本地 ipk): $pkg"
  fi
}

PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-theme-argon"
# 仅当本地存在对应 ipk 时再加入，避免官方源缺失导致失败
add_if_local luci-app-argon-config
add_if_local luci-i18n-argon-config-zh-cn
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
# 第三方包：仅当本地 packages/ 有对应 ipk 时才加入
add_if_local luci-i18n-passwall-zh-cn
add_if_local luci-app-openclash
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-dufs-zh-cn"

# 自定义第三方包（与根仓库同机制）
# shell/custom-packages.sh 可拼接 CUSTOM_PACKAGES 变量，也可直接通过环境变量覆盖
if [ -f "$SCRIPT_DIR/shell/custom-packages.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/shell/custom-packages.sh"
fi
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

# 可选：包含 Dockerman UI
if [ "$INCLUDE_DOCKER" = "yes" ]; then
  PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
fi

# 若包含 openclash，下载 core/规则
if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
  echo "[immortalwrt-image-build] 检测到 openclash，下载 core & 数据文件"
  mkdir -p "$IB_DIR/files/etc/openclash/core"
  META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"
  wget $WGET_OPTS -qO- "$META_URL" | tar xOvz > "$IB_DIR/files/etc/openclash/core/clash_meta"
  chmod +x "$IB_DIR/files/etc/openclash/core/clash_meta"
  wget $WGET_OPTS -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O "$IB_DIR/files/etc/openclash/GeoIP.dat"
  wget $WGET_OPTS -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O "$IB_DIR/files/etc/openclash/GeoSite.dat"
fi

echo "[immortalwrt-image-build] 开始 make image..."
( cd "$IB_DIR" && \
  make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="$IB_DIR/files" ROOTFS_PARTSIZE="${ROOTFS_PARTSIZE:-$PROFILE}" )

echo "[immortalwrt-image-build] 搜索 rootfs tar..."
ROOTFS_TAR=$(find "$IB_DIR/bin/targets/x86/64" -type f -name "*rootfs.tar.gz" | head -n 1 || true)
if [ -z "${ROOTFS_TAR:-}" ]; then
  echo "[immortalwrt-image-build] 未找到 rootfs.tar.gz（请检查 ImageBuilder 输出）" >&2
  exit 1
fi
cp -f "$ROOTFS_TAR" "$OUTPUT_DIR/rootfs.tar.gz"
echo "[immortalwrt-image-build] 已导出：$OUTPUT_DIR/rootfs.tar.gz"

if [ "$DOCKER_BUILD" -eq 1 ]; then
  echo "[immortalwrt-image-build] 构建 Docker 镜像..."
  docker build -t "$DOCKER_TAG1" -t "$DOCKER_TAG2" -f "$SCRIPT_DIR/Dockerfile" "$OUTPUT_DIR"
  echo "[immortalwrt-image-build] 构建完成：$DOCKER_TAG1, $DOCKER_TAG2"
fi

echo "[immortalwrt-image-build] 完成"

