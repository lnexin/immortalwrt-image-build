# immortalwrt-image-build

针对 x86_64 平台的 ImmortalWrt 24.10.3 一键构建脚本。项目会自动拉取官方 ImageBuilder，注入自定义覆盖层与第三方软件包，产出 `rootfs.tar.gz`，并可选构建三个 Docker 镜像：
- `xindzh/immoralwrt-amd64:latest`：基础 rootfs 镜像
- `xindzh/immoralwrt-amd64:24.10.3`：带版本标签的同一份镜像
- `xindzh/immoralwrt-amd64:z4`：继承 `latest`，支持通过环境变量直接设定 LAN/DNS

GitHub Actions 会在推送时自动将上述镜像额外打标签到 `xindzh/immoralwrt-amd64:*`，便于发布到 Docker Hub。

所有脚本、覆盖层、CI 工作流均包含在仓库内，可在本地或 GitHub Actions 中独立运行。

## 目录速览
- `build.sh`：主入口。下载 ImageBuilder → 同步 `files/` → 拉取第三方包 → 执行 `make image` → 导出 rootfs → 构建 Docker 镜像。
- `Dockerfile`：最小化镜像（`FROM scratch` + `ADD rootfs.tar.gz /`）。
- `Dockerfile.z4`：基于 `xindzh/immoralwrt-amd64:latest` 的自定义镜像，预置网络相关环境变量并部署 `/etc/rc.local`。
- `docker/rc.local`：容器启动时根据环境变量更新 LAN 地址、网关、DNS 以及 `dnsmasq` 上游。
- `files/`：会复制到 ImageBuilder 的 `FILES` 目录，用于首启脚本、配置等覆盖。
- `shell/`：构建辅助脚本（准备第三方包、生成索引等）。
- `output/`、`work/`：构建过程中生成的产物与缓存，可随时删除重新构建。
- `.github/workflows/build-amd64.yml`：官方工作流，包含依赖安装、PATH 清理、构建与推送逻辑。

## 环境准备
建议使用 WSL/Ubuntu 24.04 或其他 Linux 环境，并确保位于**区分大小写**的文件系统。

一次性安装构建所需依赖：
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential git wget curl ca-certificates \
  tar unzip xz-utils zstd bzip2 gzip coreutils findutils diffutils patch \
  python3 python3-distutils file make \
  qemu-utils genisoimage dosfstools e2fsprogs
```

## 本地构建示例
- 仅生成 rootfs：
  ```bash
  PROFILE=1024 CUSTOM_PACKAGES="" bash ./build.sh
  ```
  产物位于 `output/rootfs.tar.gz`。

- 生成 rootfs 并构建 Docker 镜像：
  ```bash
  PROFILE=1024 INCLUDE_DOCKER=yes ENABLE_PPPOE=no CUSTOM_PACKAGES="" bash ./build.sh -d
  ```
  若构建成功，可在本机看到三条镜像记录：
  ```
  xindzh/immoralwrt-amd64       latest     <id>   ...
  xindzh/immoralwrt-amd64       24.10.3    <id>   ...
  xindzh/immoralwrt-amd64       z4         <id>   ...
  ```

- 运行 z4 镜像并覆盖网络参数：
  ```bash
  docker run --rm \
    -e LAN_ADDR=192.168.88.10 \
    -e LAN_GATEWAY=192.168.88.1 \
    -e LAN_DNS=223.5.5.5 \
    -e DNS_MASQ_SERVER=127.0.0.1,114.114.114.114 \
    xindzh/immoralwrt-amd64:z4
  ```
  `docker/rc.local` 会在容器启动时写入 UCI 配置并重启 `dnsmasq` 与 `lan` 接口。

## 参数与环境变量
构建脚本支持以下可覆盖参数（全部在调用前导出或直接在命令行设置）：
- `PROFILE`：ImageBuilder profile，决定 rootfs/镜像尺寸（默认 1024）。
- `ROOTFS_PARTSIZE`：覆盖 rootfs 分区大小（MiB），未提供时沿用 `PROFILE`。
- `GRUB_BIOS_PARTSIZE`：BIOS 引导分区大小（MiB），默认 16，确保生成的 qcow2/VDI 镜像不再报警。
- `INCLUDE_DOCKER`：是否附带 `luci-i18n-dockerman-zh-cn`（默认 `no`）。
- `ENABLE_PPPOE`：是否首启 PPPoE，配合 `PPPOE_ACCOUNT`、`PPPOE_PASSWORD`。
- `CUSTOM_PACKAGES`：追加或移除软件包，接受形如 `pkg1 pkg2 -pkg3` 的字符串。
- `CUSTOM_ROUTER_IP`：写入自定义初始 LAN IP，供 `files/etc/uci-defaults/99-custom.sh` 使用。
- `DOCKER_TAG1`、`DOCKER_TAG2`、`DOCKER_TAG_Z4`：覆盖默认镜像标签（默认分别为 `xindzh/immoralwrt-amd64:latest`、`xindzh/immoralwrt-amd64:${VERSION}`、`xindzh/immoralwrt-amd64:z4`）。

镜像构建过程中还会自动：
- 拉取并解包 GitHub `wukongdaily/store` 中的第三方 `.ipk`；
- 对本地 `packages/` 目录执行自定义索引生成，保证 `opkg` 能识别新增软件包；
- 若检测到 `luci-app-openclash`，下载 clash core 与规则文件；
- 清理 PATH 中含空格或非法条目，避免 `find -execdir` 报错。

## GitHub Actions
仓库已提供 `.github/workflows/build-amd64.yml`，具备以下特点：
- 安装 `qemu-utils`、`genisoimage`，避免 `mkisofs`/`qemu-img` 缺失；
- 清理 Runner 的 PATH，规避 Windows/WSL 环境变量干扰；
- 支持 `workflow_dispatch` 手动触发，自定义 profile、是否打包 Docker、附加包列表等；
- 当 `docker_push=true` 且配置了 Secrets：
  - `DOCKERHUB_USERNAME`
  - `DOCKERHUB_TOKEN`
  将自动登录并推送 `xindzh/immoralwrt-amd64:latest / 24.10.3 / z4`。

### 手动触发参数
在 Actions 页面选择 `amd64-docker → Run workflow` 时，可以指定以下字段：
- `profile`：rootfs 分区大小（MB），默认 `1024`。
- `include_docker`：是否附带 Dockerman（`yes`/`no`）。
- `enable_pppoe`：首启是否启用 PPPoE（`yes`/`no`），配合脚本内的账号/密码环境变量。
- `custom_packages`：追加/移除软件包，格式同本地构建（例如 `luci-app-foo -luci-app-bar`）。
- `docker_push`：是否将生成的镜像推送到 Docker Hub（`true`/`false`）。若设为 `true` 必须先配置下述 Secrets。

### 配置 Docker Hub 推送凭据
1. 登录 Docker Hub，创建或确认目标仓库（例：`xindzh/immoralwrt-amd64`）。  
2. 进入 **Account Settings → Security**，点击 **New Access Token**，复制生成的 Token（仅显示一次）。  
3. 在 GitHub 仓库中打开 **Settings → Secrets and variables → Actions → New repository secret**：  
   - `DOCKERHUB_USERNAME`：填入 Docker Hub 用户名。  
   - `DOCKERHUB_TOKEN`：填入第二步获取的 Access Token。  
4. 重新手动触发 workflow，设置 `docker_push=true`，即可在构建完成后自动执行 `docker push`。

若要在其他仓库中复用，复制 `build.sh`、`files/`、`shell/`、`Dockerfile*`、`.github/workflows/build-amd64.yml` 后即可直接运行，路径已经写成仓库根目录 friendly 的形式。

## 常见问题
- **构建提示 BIOS Boot Partition 过小**：已将默认大小改为 16 MiB；若仍提示，可手动设置 `GRUB_BIOS_PARTSIZE=32`。
- **缺少 `mkisofs` / `qemu-img`**：确保执行了上文的依赖安装或在 CI 中保留安装步骤。
- **额外包未安装**：检查 `work/.../packages/Packages` 中是否已有对应条目，必要时清理 `work/` 目录重新构建。
- **路径包含空格导致 `find` 报错**：脚本会自动过滤含空格的 PATH 条目；若手动执行 `make image`，请在终端先移除这些 PATH。

构建完成后，可通过 `docker run -it --rm xindzh/immoralwrt-amd64:z4 /bin/ash` 进入容器，或导出 `output/rootfs.tar.gz` 供自定义部署。欢迎根据自身需求调整 `files/`、`shell/` 及 Dockerfile，持续扩展镜像功能。
