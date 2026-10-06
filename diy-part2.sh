#!/bin/bash
# diy-part2.sh — 在 openwrt 源码目录内运行（workflow 已 cd openwrt）
# 用途：把官方源没有的 ddns-go 打进固件（二进制 + procd 启动脚本）
set -e

# ---------- 1. ddns-go 二进制（linux arm64 / aarch64） ----------
DDNS_VER="v6.17.5"
echo "Downloading ddns-go ${DDNS_VER} ..."
curl -fsSL -o /tmp/ddns-go.tar.gz \
  "https://github.com/jeessy2/ddns-go/releases/download/${DDNS_VER}/ddns-go_${DDNS_VER#v}_linux_arm64.tar.gz"
mkdir -p files/usr/bin
tar -xzf /tmp/ddns-go.tar.gz -C files/usr/bin/ ddns-go
chmod +x files/usr/bin/ddns-go

# ---------- 2. procd 守护脚本 ----------
mkdir -p files/etc/init.d
cat > files/etc/init.d/ddns-go <<'EOF'
#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROCD=1

PROG=/usr/bin/ddns-go

start_service() {
    procd_open_instance
    procd_set_param command "$PROG"
    procd_append_param command -c /etc/ddns-go/.ddns_go_config.yaml
    procd_set_param respawn 3600 5 5
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
EOF
chmod +x files/etc/init.d/ddns-go

# ---------- 3. 开机默认启用 ----------
mkdir -p files/etc/rc.d
ln -sf ../init.d/ddns-go files/etc/rc.d/S99ddns-go

echo "diy-part2: ddns-go ${DDNS_VER} bundled."
