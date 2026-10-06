#!/bin/bash
# diy-part1.sh — 克隆源码后、feeds 更新前运行
# 作用：把第三方 feeds 源追加到 openwrt/feeds.conf.default
#       （必须先于 feeds update 执行，否则新源拉不到）

# ---- iStore 应用商店（linkease 官方源） ----
echo "src-git istore https://github.com/linkease/istore.git" >> feeds.conf.default
echo "src-git istore_ui https://github.com/linkease/istore-ui.git" >> feeds.conf.default

echo "diy-part1: istore feeds added."
