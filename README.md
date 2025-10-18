# immortalwrt-image-build — x86_64 ImmortalWrt Docker 构建

本目录提供仅 x86 平台的 ImmortalWrt 24.10.3 构建与打包为 Docker 镜像的独立项目。已在目录内自包含所有脚本与覆盖层：拉取 ImageBuilder、添加第三方包、应用 onlyx8664/files 覆盖层、`make image` 构建，再基于 rootfs 生成镜像；不依赖仓库根目录文件。

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
  - 单仓库根目录版本：`.github/workflows/build-onlyx8664.yml`
  - 便于独立项目使用的副本：`immortalwrt-image-build/build-onlyx8664.yml`
- 独立仓库使用说明：
  - 将 immortalwrt-image-build 目录作为新仓库根目录使用；
  - 在新仓库中创建 `.github/workflows/` 目录，并将 `immortalwrt-image-build/build-onlyx8664.yml` 移动到该目录；
  - 该工作流已适配路径，可在“含 immortalwrt-image-build 子目录”与“以 immortalwrt-image-build 为仓库根”两种布局下工作；
  - 在仓库 Secrets 配置：`DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`；
  - 手动触发 workflow_dispatch 并填写参数（或直接 push 使用默认参数构建）。

## 结构
- `build.sh`：一键拉取 ImageBuilder → 准备第三方包 → 构建 → 生成/打包 Docker
- `Dockerfile`：`FROM scratch` + `ADD rootfs.tar.gz /`
- `files/`：独立覆盖层（从仓库根 `files/` 拷贝）
- `shell/`：与仓库根保持一致的包准备脚本
