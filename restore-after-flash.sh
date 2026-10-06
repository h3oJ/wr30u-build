#!/bin/sh
# ============================================================
# WR30U 刷官方 OpenWrt 24.10 定制固件后 · 一键恢复脚本
# 在路由器上执行（SSH 或 ttyd 网页终端）：
#     sh restore-after-flash.sh
# ============================================================

echo ">>> [1/5] 重建 4 条端口转发规则"

uci -q delete firewall.RDP_Home_PC
uci set firewall.RDP_Home_PC=redirect
uci set firewall.RDP_Home_PC.name='RDP_Home_PC'
uci set firewall.RDP_Home_PC.target='DNAT'
uci set firewall.RDP_Home_PC.src='wan'
uci set firewall.RDP_Home_PC.dest='lan'
uci set firewall.RDP_Home_PC.proto='tcp udp'
uci set firewall.RDP_Home_PC.src_dport='4712'
uci set firewall.RDP_Home_PC.dest_ip='10.10.10.75'
uci set firewall.RDP_Home_PC.dest_port='3389'

uci -q delete firewall.Route_Home
uci set firewall.Route_Home=redirect
uci set firewall.Route_Home.name='Route_Home'
uci set firewall.Route_Home.target='DNAT'
uci set firewall.Route_Home.src='wan'
uci set firewall.Route_Home.dest='lan'
uci set firewall.Route_Home.proto='tcp'
uci set firewall.Route_Home.src_dport='8088'
uci set firewall.Route_Home.dest_ip='10.10.10.1'
uci set firewall.Route_Home.dest_port='8088'

uci -q delete firewall.DDNSGO_HOME
uci set firewall.DDNSGO_HOME=redirect
uci set firewall.DDNSGO_HOME.name='DDNS-GO_HOME'
uci set firewall.DDNSGO_HOME.target='DNAT'
uci set firewall.DDNSGO_HOME.src='wan'
uci set firewall.DDNSGO_HOME.dest='lan'
uci set firewall.DDNSGO_HOME.proto='tcp'
uci set firewall.DDNSGO_HOME.src_dport='9876'
uci set firewall.DDNSGO_HOME.dest_ip='10.10.10.1'
uci set firewall.DDNSGO_HOME.dest_port='9876'

uci -q delete firewall.FEISHU_BOT
uci set firewall.FEISHU_BOT=redirect
uci set firewall.FEISHU_BOT.name='飞书IP机器人'
uci set firewall.FEISHU_BOT.target='DNAT'
uci set firewall.FEISHU_BOT.src='wan'
uci set firewall.FEISHU_BOT.dest='lan'
uci set firewall.FEISHU_BOT.proto='tcp udp'
uci set firewall.FEISHU_BOT.src_dport='5000'
uci set firewall.FEISHU_BOT.dest_ip='10.10.10.1'
uci set firewall.FEISHU_BOT.dest_port='5000'

uci commit firewall
/etc/init.d/firewall reload
echo ">>>     端口转发重建完成（4 条）"

echo ">>> [2/5] 恢复 IPv6 方案 B（wan 关 v6，wan6 独立走 PPPoE）"
uci set network.wan.ipv6='0'
uci -q delete network.wan6
uci set network.wan6=interface
uci set network.wan6.proto='dhcpv6'
uci set network.wan6.ifname='pppoe-wan'
uci set network.wan6.reqaddress='try'
uci set network.wan6.reqprefix='auto'
uci commit network
echo ">>>     wan6 配置已提交（网络重启见 [5/5]）"

echo ">>> [3/5] ddns-go 配置目录"
mkdir -p /etc/ddns-go
/etc/init.d/ddns-go enable
echo ">>>     刷机前先把配置备份到电脑："
echo ">>>       scp root@10.10.10.1:/root/.ddns_go_config.yaml ."
echo ">>>     刷机后放回路由器："
echo ">>>       scp .ddns_go_config.yaml root@10.10.10.1:/etc/ddns-go/"
echo ">>>     然后 /etc/init.d/ddns-go start"

echo ">>> [4/5] 飞书机器人（手动部署）"
echo ">>>     刷机前备份：scp root@10.10.10.1:/root/feishu_ip_bot.py ."
echo ">>>     刷机后部署："
echo ">>>       scp feishu_ip_bot.py root@10.10.10.1:/root/"
echo ">>>       nohup python3 /root/feishu_ip_bot.py > /tmp/feishu_bot.log 2>&1 &"
echo ">>>     加保活 cron：* * * * * netstat -tlnp | grep :5000 > /dev/null || /usr/bin/python3 /root/feishu_ip_bot.py > /tmp/feishu_bot.log 2>&1 &"

echo ">>> [5/5] 重启网络与防火墙，使全部配置生效"
/etc/init.d/network restart
sleep 5
/etc/init.d/firewall restart
echo ""
echo ">>> 完成！验证："
echo ">>>   - LuCI 状态页：wan6 显示 IPv6 地址（2408:8266:304:xxx 段）"
echo ">>>   - 网络->防火墙->端口转发：4 条规则齐全"
echo ">>>   - ddns-go 启动后：/etc/init.d/ddns-go start"
