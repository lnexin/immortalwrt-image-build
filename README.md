# immortalwrt-image-build
一份基于github immortalwrt 构建镜像的说明


## 简介
项目是基于 immortalwrt (https://github.com/immortalwrt/immortalwrt/tree/openwrt-24.10) 官方固件, 
利用官方的 imagebuilder 构建一个自定义okpg 的docker image
用于x86_64 主机在docker 里面使用 openwrt 路由

1. 这个项目是自用x86_64 nas或者家里台式机的构建，如果是其他平台如树莓派, 高通等硬件平台，需要参照原有的文档说明。
2. 其他平台可参考 https://github.com/SuLingGG/OpenWrt-Docker 里面的样例和说明，这个里面有mini最小版本的构建说明。
3. 最终的docker image 可选添加极空间 docker 一些权限问题的处理, 可参照 https://hub.docker.com/r/kangkang223/openwrt





构建
https://github.com/SuLingGG/OpenWrt-Docker
https://github.com/zzsrv/OpenWrt-Docker/tree/main
z4极空间
https://hub.docker.com/r/kangkang223/openwrt