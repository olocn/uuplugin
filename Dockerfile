FROM alpine:3.16
LABEL maintainer="UU-Custom"

# 設定預設環境變數
ENV UU_LAN_IPADDR="192.168.8.2"
ENV UU_LAN_GATEWAY="192.168.8.1"
ENV UU_LAN_NETMASK="255.255.255.0"
ENV UU_LAN_DNS="119.29.29.29"

# 安裝必要依賴 (Alpine 環境)
# libc6-compat 是運行網易二進制檔(glibc)的關鍵
RUN apk add --no-cache \
    wget \
    curl \
    jq \
    tar \
    ca-certificates \
    iptables \
    iproute2 \
    libc6-compat \
    bash

# 偽裝 OpenWrt 環境目錄與標誌檔案
# 網易腳本會檢查 /etc/openwrt_release
RUN mkdir -p /etc/config /etc/init.d /var/lock /var/run && \
    echo "DISTRIB_ID='OpenWrt'" > /etc/openwrt_release

# 複製並設定啟動腳本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露插件通訊端口
EXPOSE 43474

# 啟動容器時直接執行腳本，不再使用 /sbin/init
ENTRYPOINT ["/entrypoint.sh"]
