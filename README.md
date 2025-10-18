# immortalwrt-image-build — x86_64 ImmortalWrt Docker 构建

本目录提供仅 x86 平台的 ImmortalWrt 24.10.3 构建与打包为 Docker 镜像的独立项目。已在目录内自包含所有脚本与覆盖层：拉取 ImageBuilder、添加第三方包、应用 files 覆盖层、`make image` 构建，再基于 rootfs 生成镜像；不依赖仓库根目录文件。

## 快速开始（本地）
- 依赖：bash、git、wget、tar、make、docker（可选）
- 示例：
  - 仅构建固件：
    `PROFILE=1024 CUSTOM_PACKAGES="" bash immortalwrt-image-build/build.sh`
  - 构建并打包 Docker：
    `PROFILE=1024 INCLUDE_DOCKER=yes ENABLE_PPPOE=no CUSTOM_PACKAGES="" bash immortalwrt-image-build/build.sh -d`

镜像标签默认：`immortalwrt/x86-64:24.10` 与 `immortalwrt/x86-64:24.10.3`。

## 环境变量
- `PROFILE`：rootfs 分区大小（MB，默认 1024）
- `INCLUDE_DOCKER`：是否包含 Dockerman UI（yes/no）
- `ENABLE_PPPOE`、`PPPOE_ACCOUNT`、`PPPOE_PASSWORD`：首启 PPPoE 配置
- `CUSTOM_PACKAGES`：附加/移除包（如 `luci-app-foo -luci-app-bar`）

## GitHub Actions
- 已提供两个工作流文件：
  - 单仓库根目录版本：`.github/workflows/build-amd64.yml`
  - 便于独立项目使用的副本：`immortalwrt-image-build/build-amd64.yml`
- 独立仓库使用说明：
  - 将 immortalwrt-image-build 目录作为新仓库根目录使用；
  - 在新仓库中创建 `.github/workflows/` 目录，并将 `immortalwrt-image-build/build-amd64.yml` 移动到该目录；
  - 该工作流已适配路径，可在“含 immortalwrt-image-build 子目录”与“以 immortalwrt-image-build 为仓库根”两种布局下工作；
  - 在仓库 Secrets 配置：`DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`；
  - 手动触发 workflow_dispatch 并填写参数（或直接 push 使用默认参数构建）。

## 结构
- `build.sh`：一键拉取 ImageBuilder → 准备第三方包 → 构建 → 生成/打包 Docker
- `Dockerfile`：`FROM scratch` + `ADD rootfs.tar.gz /`
- `files/`：独立覆盖层（从仓库根 `files/` 拷贝）
- `shell/`：与仓库根保持一致的包准备脚本
# immortalwrt-image-build | x86_64 ImmortalWrt Docker 构建

本项目用于在 x86_64 平台上基于 ImmortalWrt ImageBuilder 生成 rootfs，并可选打包为 Docker 镜像。仓库内包含构建脚本、覆盖层与工作流，便于本地或 GitHub Actions 一键使用。

## 快速开始（本地）
- 前置依赖：bash、git、wget、tar、make、zstd、docker（若需生成镜像）。
- 仅构建 rootfs：
  `PROFILE=1024 CUSTOM_PACKAGES="" bash ./build.sh`
- 构建并生成 Docker 镜像：
  `PROFILE=1024 INCLUDE_DOCKER=yes ENABLE_PPPOE=no CUSTOM_PACKAGES="" bash ./build.sh -d`
- 构建产物：`output/rootfs.tar.gz`；若使用 `-d`，镜像标签默认为 `immortalwrt/x86-64:24.10` 和 `immortalwrt/x86-64:24.10.3`。

## 环境参数
- `PROFILE`/`ROOTFS_PARTSIZE`：rootfs 分区大小（MB），`ROOTFS_PARTSIZE` 优先，默认 1024。
- `INCLUDE_DOCKER`：是否包含 Dockerman UI（`yes`/`no`）。
- `ENABLE_PPPOE`、`PPPOE_ACCOUNT`、`PPPOE_PASSWORD`：是否启用 PPPoE 及其账号密码。
- `CUSTOM_PACKAGES`：追加/移除软件包，例如：`CUSTOM_PACKAGES="luci-app-foo luci-i18n-foo-zh-cn -luci-app-bar"`。
- `CUSTOM_ROUTER_IP`：写入 `files/etc/config/custom_router_ip.txt`，首次启动由 `files/etc/uci-defaults/99-custom.sh` 读取。

## GitHub Actions 使用
- 根目录工作流：`.github/workflows/build-amd64.yml`（可手动触发或在 push 时使用默认参数）。
- 手动触发参数：
  - `profile`（MB）、`include_docker`（yes/no）、`enable_pppoe`（yes/no）、`custom_packages`（字符串）、`docker_push`（true/false）。
- 推送镜像（可选）：设置仓库 Secrets `DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN` 后，可在手动触发时勾选 `docker_push=true`。

## 目录结构
- `build.sh`：主脚本，下载 ImageBuilder、准备包与覆盖层、生成 rootfs，并可选构建 Docker 镜像。
- `Dockerfile`：`FROM scratch`，`ADD rootfs.tar.gz /`。
- `files/`：系统覆盖层（会复制到 ImageBuilder 的 `FILES`）。
- `shell/`：构建辅助脚本（如 `prepare-packages.sh`）。
- `output/`：构建产物输出目录（生成）。
- `work/`：工作目录与缓存（生成，可删除）。
- `.github/workflows/build-amd64.yml` 与 `build-amd64.yml`：GitHub Actions 工作流（前者供本仓使用，后者便于拷贝到其他仓库）。

## 常见问题
- 下载失败：已为 `wget` 添加重试和超时；仍失败可重试任务或检查网络/代理。
- 本地 IPK 未生效：脚本会为 `packages/` 自动执行 `make package/index` 生成索引；仍失败请检查包兼容性与日志。
