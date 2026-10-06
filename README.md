# WR30U OpenWrt 24.10 定制固件编译包

用 **GitHub Actions 云编译**官方 OpenWrt 24.10，目标设备 **Xiaomi Mi Router WR30U**（mediatek/filogic, MT7981B）。

解决旧固件（bleachwrt mini）的痛点：
- ✅ **nlbwmon** 可用（内核含 `nf_conntrack_netlink` 模块）
- ✅ **zram swap** 可用（`kmod-zram` + `zram-swap`）
- ✅ **collectd + LuCI 统计**（官方 init 脚本正常，不再崩溃）
- ✅ **ddns-go** 直接打进固件（官方源没有此包）
- ✅ **iStore 应用商店**（`luci-app-store`，linkease 官方源）
- ✅ 完整官方 LuCI、无线 mt76 驱动、常用工具

---

## 一、使用方法（约 10 分钟）

1. 登录 GitHub，新建一个仓库（Public 或 Private 均可），例如 `wr30u-build`
2. 把本目录下的文件上传到仓库根目录（保持目录结构）：
   ```
   .config
   diy-part1.sh
   diy-part2.sh
   restore-after-flash.sh
   .gitattributes
   .github/workflows/build.yml
   README.md
   ```
3. 进入仓库 **Actions** 标签页 → 左侧选 **Build WR30U OpenWrt 24.10** → **Run workflow**
   （push 到 main 也会自动触发）
4. 等待约 **2~4 小时**（首次编译需下载工具链和源码）
5. 编译完成自动发布 Release：**Releases** 页面下载 `...-squashfs-sysupgrade.bin`

## 二、刷机（重要）

WR30U 当前已在 OpenWrt（bleachwrt）上，可直刷官方 OpenWrt sysupgrade 镜像：

```bash
# 保留配置升级风险高（跨固件不兼容），推荐不保留：
sysupgrade -n /tmp/xxx-squashfs-sysupgrade.bin
```

> ⚠️ 跨固件（bleachwrt → 官方）**不要保留配置**，刷完重新配置拨号、WiFi 等。
> 刷机前建议先备份现有配置：`sysupgrade -b /tmp/backup.tar.gz`（仅用于回滚参考）。

## 三、刷完后恢复（一键脚本）

`restore-after-flash.sh` 已包含：4 条端口转发规则、IPv6 方案 B、ddns-go 配置目录、飞书机器人部署提示。
刷完后 SSH 登录路由器执行：

```bash
sh restore-after-flash.sh
```

## 四、与旧固件（bleachwrt mini）的差异

| 功能 | 旧固件 | 本固件 |
|------|--------|--------|
| nlbwmon 分设备流量 | ❌ 缺模块 | ✅ 可用 |
| zram swap | ❌ 无 | ✅ 可用 |
| collectd 统计 | ❌ init 崩溃 | ✅ 正常 |
| 端口转发（4 条） | ✅ | ✅ 一键恢复 |
| turboacc 硬件加速 | ✅ hw_flow+sfe_flow+fullcone | ⚠️ 无 turboacc；官方替代为 LuCI「防火墙 → 硬件流量分载」（MTK PPE 硬件加速） |
| FullCone NAT | ✅ | ❌ 官方无（如需可后续加 nftables fullcone 补丁） |
| passwall / 科学上网 | 有（你未使用） | ❌ 无（官方源没有） |
| iStore 应用商店 | ❌ 无 | ✅ 编译进固件（LuCI → 服务 → iStore） |
| LuCI | 旧版 Lua | 新版 JS |

## 五、自定义（可选）

- 想加包：编辑 `.config`，加一行 `CONFIG_PACKAGE_xxx=y`，重新 push 即可
- 想预置飞书机器人等脚本：放到 `diy-part2.sh` 的 `files/` 目录逻辑中
- 想换版本：把 `build.yml` 里 `--branch openwrt-24.10` 改成 `--branch main` 或指定 tag

## 六、常见问题

- **编译失败**：Actions 日志里看 `===== BUILD FAILED =====` 后面的错误摘要；常见是网络拉取失败，重新 Run workflow 即可
- **固件太大**：WR30U 128MB NAND，本配置编译产物约 40~50MB，无容量问题
- **sysupgrade 校验失败**：确认下载的是 `squashfs-sysupgrade.bin` 且与设备型号一致
