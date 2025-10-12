# x86_64 Normal 镜像构建流程

## 构建单一 x86_64 Normal 版本 OpenWrt Docker 镜像

### 1. 环境准备
在 Ubuntu 系统上安装必要的构建工具：
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  libncurses5-dev \
  libncursesw5-dev \
  zlib1g-dev \
  gawk \
  git \
  gettext \
  libssl-dev \
  xsltproc \
  rsync \
  wget \
  unzip \
  python3 \
  qemu-utils
```

### 2. 下载 ImageBuilder
从 immortalwrt 官方仓库下载 x86_64 平台的 ImageBuilder：
Image Builder（原 Image Generator、简称 IB）是一个预编译环境，允许构建自定义固件映像而无需从源码编译。它支持下载预编译软件包并将其集成进固件中。
```bash
# 下载 ImageBuilder
wget https://storage.openwrt.cc/snapshots/targets/x86/64/immortalwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz

# 解压
tar -xJf immortalwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz

# 进入目录
cd immortalwrt-imagebuilder-x86-64.Linux-x86_64
```

### 3. 配置软件源
创建 repositories.conf 文件配置软件源：
```bash
cat > repositories.conf << 'EOF'
src/gz openwrt_core https://storage.openwrt.cc/snapshots/targets/x86/64/packages
src/gz openwrt_base https://storage.openwrt.cc/snapshots/packages/x86_64/base
src/gz openwrt_luci https://storage.openwrt.cc/snapshots/packages/x86_64/luci
src/gz openwrt_packages https://storage.openwrt.cc/snapshots/packages/x86_64/packages
src/gz openwrt_routing https://storage.openwrt.cc/snapshots/packages/x86_64/routing
src/gz openwrt_telephony https://storage.openwrt.cc/snapshots/packages/x86_64/telephony
src imagebuilder file:packages
option check_signature
EOF
```

### 4. 准备自定义文件
创建自定义文件目录结构：
```bash
# 创建必要的目录
mkdir -p files/etc/opkg
mkdir -p files/root

# 配置 opkg 软件源
cat > files/etc/opkg/distfeeds.conf << 'EOF'
src/gz openwrt_core https://openwrt.cc/snapshots/targets/x86/64/packages
src/gz openwrt_base https://openwrt.cc/snapshots/packages/x86_64/base
src/gz openwrt_luci https://openwrt.cc/snapshots/packages/x86_64/luci
src/gz openwrt_packages https://openwrt.cc/snapshots/packages/x86_64/packages
src/gz openwrt_routing https://openwrt.cc/snapshots/packages/x86_64/routing
src/gz openwrt_telephony https://openwrt.cc/snapshots/packages/x86_64/telephony
EOF

# 设置启动脚本权限（如果有）
[ -f files/etc/rc.local ] && chmod +x files/etc/rc.local
```

### 5. 安装终端工具（可选）
如果需要 oh-my-zsh 等终端增强工具：
```bash
# 进入 root 目录
cd files/root

# 克隆 oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh ./.oh-my-zsh

# 安装插件
git clone https://github.com/zsh-users/zsh-autosuggestions ./.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ./.oh-my-zsh/custom/plugins/zsh-completions

# 返回 ImageBuilder 目录
cd ../..
```

### 6. 配置构建选项
修改 .config 文件，禁用不需要的文件系统格式：
```bash
# 禁用 squashfs 和 ext4 文件系统（只保留 tar.gz）
sed -i "/CONFIG_TARGET_ROOTFS_SQUASHFS/s/.*/# CONFIG_TARGET_ROOTFS_SQUASHFS is not set/" .config
sed -i "/CONFIG_TARGET_ROOTFS_EXT4FS/s/.*/# CONFIG_TARGET_ROOTFS_EXT4FS is not set/" .config
```

### 7. 构建 RootFS
执行构建命令，包含所需的软件包：
```bash
# 定义软件包列表
PACKAGES="-luci-app-cpufreq \
htop \
luci-app-argon-config \
luci-app-aria2 \
luci-app-commands \
luci-app-ddns \
luci-app-fileassistant \
luci-app-filetransfer \
luci-app-firewall \
luci-app-frpc \
luci-app-gowebdav \
luci-app-n2n_v2 \
luci-app-netdata \
luci-app-nlbwmon \
luci-app-nps \
luci-app-openclash \
luci-app-passwall \
luci-app-samba \
luci-app-serverchan \
luci-app-smartdns \
luci-app-softethervpn \
luci-app-ssr-plus \
luci-app-transmission \
luci-app-ttyd \
luci-app-webadmin \
luci-app-wireguard \
luci-app-wrtbwmon \
luci-app-zerotier \
luci-base \
luci-compat \
luci-i18n-argon-config-zh-cn \
luci-i18n-aria2-zh-cn \
luci-i18n-base-zh-cn \
luci-i18n-commands-zh-cn \
luci-i18n-ddns-zh-cn \
luci-i18n-filetransfer-zh-cn \
luci-i18n-firewall-zh-cn \
luci-i18n-frpc-zh-cn \
luci-i18n-gowebdav-zh-cn \
luci-i18n-n2n_v2-zh-cn \
luci-i18n-netdata-zh-cn \
luci-i18n-nlbwmon-zh-cn \
luci-i18n-nps-zh-cn \
luci-i18n-passwall-zh-cn \
luci-i18n-samba-zh-cn \
luci-i18n-smartdns-zh-cn \
luci-i18n-softethervpn-zh-cn \
luci-i18n-ssr-plus-zh-cn \
luci-i18n-transmission-zh-cn \
luci-i18n-ttyd-zh-cn \
luci-i18n-turboacc-zh-cn \
luci-i18n-webadmin-zh-cn \
luci-i18n-wireguard-zh-cn \
luci-i18n-wrtbwmon-zh-cn \
luci-i18n-zerotier-zh-cn \
luci-lib-base \
luci-lib-ip \
luci-lib-ipkg \
luci-lib-jsonc \
luci-lib-nixio \
luci-mod-admin-full \
luci-theme-argon \
luci-theme-bootstrap \
nano \
vim-full"

# 执行构建
make image PACKAGES="$PACKAGES" FILES="files"
```

### 8. 创建 Docker 镜像
构建完成后，提取 rootfs 并创建 Docker 镜像：
```bash
# 复制生成的 rootfs 到工作目录
cp bin/targets/x86/64/*rootfs.tar.gz ../openwrt-x86-64-rootfs.tar.gz
cd ..

# 创建 Dockerfile
cat > Dockerfile << 'EOF'
FROM scratch
LABEL org.opencontainers.image.authors="lnexin"
ADD openwrt-x86-64-rootfs.tar.gz /
EOF

# 构建 Docker 镜像
docker build -t openwrt:x86_64-normal .
```

### 9. 测试镜像
运行容器测试：
```bash
# 创建 Docker 网络
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  openwrt-lan

# 运行容器
docker run -d \
  --name openwrt \
  --network openwrt-lan \
  --ip 192.168.1.100 \
  --restart unless-stopped \
  --privileged \
  openwrt:x86_64-normal \
  /sbin/init
```

### 10. 推送到镜像仓库（可选）
如果需要推送到 DockerHub：
```bash
# 登录 DockerHub
docker login

# 打标签
docker tag openwrt:x86_64-normal your-username/openwrt:x86_64

# 推送
docker push your-username/openwrt:x86_64

# 推送到阿里云（需要先登录）
docker login registry.cn-shanghai.aliyuncs.com
docker tag openwrt:x86_64-normal registry.cn-shanghai.aliyuncs.com/your-namespace/openwrt:x86_64
docker push registry.cn-shanghai.aliyuncs.com/your-namespace/openwrt:x86_64
```

## 注意事项

1. **内核模块**：Docker 容器与宿主机共享内核，某些功能可能需要在宿主机加载相应内核模块
2. **网络配置**：根据实际需求配置 Docker 网络，可以使用 macvlan、bridge 等不同网络模式
3. **权限要求**：OpenWrt 容器通常需要 --privileged 权限才能正常运行
4. **软件包兼容性**：并非所有软件包都能在 Docker 环境中正常工作，特别是依赖特定内核特性的包

## 软件包说明

Normal 版本包含的主要功能：
- **科学上网**：OpenClash, Passwall, SSR Plus
- **网络工具**：WireGuard, SoftEther VPN, N2N, ZeroTier
- **下载工具**：Aria2, Transmission
- **文件服务**：Samba, WebDAV
- **监控管理**：Netdata, 带宽监控, TTYD 终端
- **其他工具**：DDNS, 智能 DNS, 防火墙管理等