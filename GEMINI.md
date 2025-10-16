# GEMINI.md - ImmortalWRT 镜像构建

## 项目概述

该项目为 x86-64 架构构建自定义的 ImmortalWRT Docker 镜像。它利用官方的 ImmortalWRT 镜像构建器（Image Builder）创建一个包含预定义软件包集的 Docker 镜像，专为在 Docker 容器中运行功能丰富的 OpenWrt 环境而设计。构建过程通过 GitHub Actions 工作流实现自动化，该工作流生成镜像并将其推送到 Docker Hub。

项目主要配置用于构建 `x86_64` 平台的镜像，如 `config/platform.config` 和 `build-x86.sh` 脚本中所指定。

## 构建与运行

### 自动构建 (GitHub Actions)

构建镜像的主要方法是通过 `.github/workflows/immortalwrt-build-image-actions.yml` 工作流。该工作流可以手动触发或按计划执行 (`cron: 0 0 * * *`)。

工作流执行以下步骤：
1.  **初始化环境**并安装必要的构建工具。
2.  **下载目标平台**的 ImmortalWRT 镜像构建器。
3.  **添加自定义软件包和配置文件**：
    *   包含 `config/packages.config` 中的软件包。
    *   将 `files/` 目录中的自定义文件复制到镜像的根文件系统中。
    *   使用 `scripts/preset-terminal-tools.sh` 设置 `oh-my-zsh` 等终端工具。
4.  **构建根文件系统** (`rootfs.tar.gz`)。
5.  使用 `Dockerfile` **构建 Docker 镜像**，该文件仅添加了 rootfs。
6.  **将镜像推送**到 Docker Hub。

### 手动构建

对于本地或手动构建，您可以按照 `x86_64_normal_build.md` 中的详细说明进行操作。`build-x86.sh` 脚本也为本地构建提供了起点。

一般步骤如下：
1.  使用所需工具设置构建环境。
2.  下载 ImmortalWRT 镜像构建器。
3.  配置软件包仓库并添加自定义文件。
4.  使用所需软件包运行 `make image` 命令。
5.  从生成的 rootfs 存档构建 Docker 镜像。

## 开发约定

### 自定义

可以通过修改以下文件和目录来自定义镜像：

*   **`config/packages.config`**：该文件包含要安装在镜像中的 `opkg` 软件包列表。您可以从此列表中添加或删除软件包以更改包含的软件。
*   **`config/platform.config`**：定义构建的目标平台。默认为 `x86_64/x86/64/linux-amd64/amd64`。
*   **`config/repositories.conf`**：指定镜像构建器使用的软件包仓库。
*   **`files/`**：此目录包含将直接复制到镜像根文件系统中的文件。这对于提供默认配置很有用。例如：
    *   `files/etc/uci-defaults/99-init-settings`：在首次启动时运行以应用初始设置的脚本，例如设置默认主题。
    *   `files/root/.zshrc`：`zsh` shell 的配置文件。
*   **`scripts/preset-terminal-tools.sh`**：此脚本用于在镜像中安装和配置 `oh-my-zsh` 及其插件等终端工具。

### Dockerfile

`Dockerfile` 非常简单。它使用 `scratch` 基础镜像并添加由镜像构建器生成的 `rootfs.tar.gz`。

```dockerfile
FROM scratch

LABEL org.opencontainers.image.authors="lnexin"

ADD *.tar.gz /
```