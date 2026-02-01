#!/bin/bash

# 1. 準備 TUN 裝置
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 666 /dev/net/tun
fi

# 2. 寫入偽裝的 OpenWrt 網絡配置 (供 UU 插件讀取)
echo "config interface 'lan'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '$UU_LAN_IPADDR'
    option gateway '$UU_LAN_GATEWAY'
    option netmask '$UU_LAN_NETMASK'
    list dns '$UU_LAN_DNS'" > /etc/config/network

# 3. 下載並安裝最新 V2 插件 (依據你指定的網址)
echo "正在安裝網易 UU 插件 V2..."
wget https://uurouter.gdl.netease.com/uuplugin-script/openwrt/install/v2/install.sh -O /tmp/install.sh
# 強制以 openwrt x86_64 模式運行
sh /tmp/install.sh openwrt x86_64

# 4. 啟動 UU 插件
# V2 安裝後通常會在 /usr/sbin/uuplugin
if [ -f /usr/sbin/uuplugin ]; then
    echo "啟動 UU 加速器..."
    /usr/sbin/uuplugin -d
else
    echo "安裝失敗，找不到二進制檔。"
    exit 1
fi

# 5. 保持前台運行並輸出日誌
echo "UU Plugin 運行中..."
# 模擬 OpenWrt 日誌輸出
touch /var/log/messages
tail -f /var/log/messages
