# immortalwrt-image-build
一份基于github immortalwrt 构建镜像的说明


## 简介
项目是基于 immortalwrt (https://github.com/immortalwrt/immortalwrt/tree/openwrt-24.10) 官方固件, 
利用官方的 imagebuilder 构建一个自定义okpg 的docker image
用于x86_64 主机在docker 里面使用 openwrt 路由


注: 项目是自行极空间Z4的镜像，如果是其他的平台，需要参照原有的文档说明改动






构建
https://github.com/SuLingGG/OpenWrt-Docker


https://github.com/zzsrv/OpenWrt-Docker/tree/main


z4极空间


https://hub.docker.com/r/kangkang223/openwrt




% aarch64_cortex-a53/armvirt/64/linux-arm64/armv8
% aarch64_cortex-a53/bcm27xx/bcm2710/linux-arm64/rpi3
% aarch64_cortex-a72/bcm27xx/bcm2711/linux-arm64/rpi4
% aarch64_generic/rockchip/armv8/linux-arm64
% arm_arm1176jzf-s_vfp/bcm27xx/bcm2708/linux-arm-v6/rpi1
% arm_arm926ej-s/at91/sam9x/linux-arm-v7
% arm_cortex-a15_neon-vfpv4/armvirt/32/linux-arm-v7/armv7
% arm_cortex-a5_vfpv4/at91/sama5/linux-arm-v7
% arm_cortex-a7/mediatek/mt7629/linux-arm-v7
% arm_cortex-a7_neon-vfpv4/bcm27xx/bcm2709/linux-arm-v7/rpi2
% arm_cortex-a9/bcm53xx/generic/linux-arm-v7
% arm_cortex-a9_vfpv3-d16/mvebu/cortexa9/linux-arm-v7
% i386_pentium4/x86/generic/linux-386/386