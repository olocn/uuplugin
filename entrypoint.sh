#!/bin/bash

# --- 1. 網路核心設置 (對應 uci set dhcp.lan.ignore=1) ---
echo 1 > /proc/sys/net/ipv4/ip_forward

# --- 2. 模擬 OpenWRT 網路配置文件 (關鍵：必須有 lan 區塊) ---
mkdir -p /etc/config
echo "
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '$UU_LAN_IPADDR'
    option gateway '$UU_LAN_GATEWAY'
    option netmask '$UU_LAN_NETMASK'
    list dns '$UU_LAN_DNS'
" > /etc/config/network

# --- 3. 準備 TUN 設備 (加速器必備) ---
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 666 /dev/net/tun
fi

# --- 4. 下載並安裝插件 (使用你要求的 v2 版本或 API) ---
echo "正在獲取最新插件..."
DOWNLOAD_URL=$(curl -s "http://router.uu.163.com/api/plugin?type=openwrt-x86_64" | jq -r .url)

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
    echo "無法從 API 獲取連結，嘗試手動安裝..."
    exit 1
fi

curl -L "$DOWNLOAD_URL" -o /tmp/uu.tar.gz
mkdir -p /tmp/uu_extract
tar -xzf /tmp/uu.tar.gz -C /tmp/uu_extract

# 移動二進制文件
BINARY_PATH=$(find /tmp/uu_extract -name "uuplugin" -type f | head -n 1)
if [ -f "$BINARY_PATH" ]; then
    cp "$BINARY_PATH" /usr/sbin/uuplugin
    chmod +x /usr/sbin/uuplugin
    echo "插件安裝成功。"
else
    echo "安裝失敗，找不到二進制文件。"
    exit 1
fi

# 建立插件運作目錄
mkdir -p /var/run/uuplugin
mkdir -p /etc/uuplugin

# --- 5. 啟動插件 ---
echo "啟動 UU 加速器..."
/usr/sbin/uuplugin -d

# --- 6. 核心排錯：強制檢查 iptables ---
sleep 5
IPT_CHECK=$(iptables -t nat -L -n | grep UU_GAME)
if [ -z "$IPT_CHECK" ]; then
    echo "警告：插件未自動寫入 iptables 規則！"
    echo "這通常是因為 QNAP 宿主機缺少 xt_REDIRECT 內核模組。"
    echo "嘗試手動寫入一條測試規則..."
    iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-ports 43474 2>&1
else
    echo "成功：偵測到 UU 規則已寫入。"
fi

# 保持運行
tail -f /dev/null
