#!/bin/bash

# 1. 準備 TUN 裝置
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 666 /dev/net/tun
fi

# 2. 寫入網絡配置 (偽裝)
echo "config interface 'lan'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '$UU_LAN_IPADDR'
    option gateway '$UU_LAN_GATEWAY'
    option netmask '$UU_LAN_NETMASK'
    list dns '$UU_LAN_DNS'" > /etc/config/network

# 3. 透過 API 獲取下載連結並安裝 (替換原本的 install.sh)
echo "正在透過 API 獲取最新 UU 插件連結..."

# 獲取下載連結
DOWNLOAD_URL=$(curl -s "http://router.uu.163.com/api/plugin?type=openwrt-x86_64" | jq -r .url)

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
    echo "錯誤：無法從 API 獲取下載連結"
    exit 1
fi

echo "開始下載插件: $DOWNLOAD_URL"
# 下載並解壓
curl -L "$DOWNLOAD_URL" -o /tmp/uuplugin.tar.gz
mkdir -p /tmp/uu_extract
tar -xzf /tmp/uuplugin.tar.gz -C /tmp/uu_extract

# 尋找解壓後的二進制檔並移動到系統目錄
# 網易的壓縮包結構有時會變，我們用 find 找名為 uuplugin 的檔案
BINARY_PATH=$(find /tmp/uu_extract -name "uuplugin" -type f | head -n 1)

if [ -f "$BINARY_PATH" ]; then
    cp "$BINARY_PATH" /usr/sbin/uuplugin
    chmod +x /usr/sbin/uuplugin
    echo "UU 插件二進制檔安裝成功。"
else
    echo "錯誤：解壓後找不到 uuplugin 二進制檔"
    exit 1
fi

# 4. 啟動 UU 插件
echo "啟動 UU 加速器..."
/usr/sbin/uuplugin -d

# 5. 保持運行
touch /var/log/uuplugin.log
tail -f /var/log/uuplugin.log
