# N60 Pro 标准版 (standard) — ImmortalWrt 24.10-6.6

基于 padavanonly/immortalwrt-mt798x-6.6（分支 openwrt-24.10-6.6）的定制固件，面向磊科 N60 Pro（512MB 内存 / 128MB 闪存），有线主路由用途，无线默认关闭。

## 一、固件配置

### 底版

- ImmortalWrt 24.10，内核 6.6 LTS，包管理 opkg
- MTK 闭源加速栈：HNAT + WARP + TurboACC-MTK（WARP_CHIPSET=mt7986）
- 闭源 mt_wifi 驱动（已装，默认关闭）

### 默认设置

- LAN：192.168.6.1/24，DHCP 默认（客户端 192.168.6.100–249）
- 无线：默认关闭（两个射频均 disabled；开无线在 LuCI 里启用并设 SSID/密码）
- root：无密码，首次进 LuCI 后立即设置
- 时区：Asia/Shanghai（CST-8），NTP 为国内服务器
- LuCI：Argon 主题，简体中文

### 文件说明

- `.github/workflows/build.yml`：GitHub Actions 工作流（仅手动触发）
- `n60-pro.config`：编译配置（目标机型 + 软件包清单，94 个包，SHA256 前 16 位 `a6f87c4d7b3e580b`）
- `diy-part1.sh`：第三方源（passwall2、passwall_packages）+ AdGuardHome LuCI clone
- `diy-part2.sh`：编译后处理（Rust 编译修复；NAS 菜单并入服务；mtwifi 生成默认禁用无线）
- `files/etc/uci-defaults/99-n60pro-defaults`：首次启动设置（LAN 6.1、关无线、Argon、中文、时区）

## 二、功能效果

| 功能 | 插件与效果 |
|---|---|
| 代理 | PassWall2 + sing-box（只留 sing-box 内核）；HAProxy 负载均衡已开，自动切换在 LuCI 里配 |
| 去广告 | AdGuardHome + LuCI（v1.8，diy-part1.sh 从上游 clone，24.10 feed 里没有该包） |
| 远程访问 | WireGuard（luci-proto-wireguard + wireguard-tools） |
| 动态域名 | DDNS |
| 限速 | eqos-mtk |
| 流量统计 | nlbwmon、vnstat2、statistics |
| 上网管控 | banip |
| IPTV | igmpproxy + udpxy |
| 端口转发 | UPnP（miniupnpd） |
| 唤醒 | WoL |
| 硬件加速 | TurboACC-MTK + HNAT + WARP、BBR |
| 无线 | mt_wifi + LuCI；默认关闭 |
| USB 存储 | diskman、USB2/3、ext4/vfat/exfat/NTFS3/F2FS、hd-idle、parted |
| USB 打印机 | p910nd（kmod-usb-printer），9100 端口共享 |
| 网页终端 | ttyd |
| 自定义命令 | luci-app-commands |
| 定时重启 | luci-app-autoreboot（默认不启用） |
| 断网自愈 | watchcat |
| 固定 IP | arpbind |
| 升级 | attendedsysupgrade、opkg 界面 |

效果说明：

- 去广告只留 AdGuardHome（DoH/DoT、查询日志、按客户端统计）。
- AdGuardHome 的 LuCI（v1.8）由 diy-part1.sh 从上游 clone；该 LuCI 包自带 `/etc/init.d/AdGuardHome`，与本体包的 init 脚本并存，刷后核查只启用一个。
- PassWall2 自动切换：负载均衡组（leastPing，设为默认节点）或主节点挂备用节点（auto_switch）；sing-box 自带 urltest 是另一条路。
- HNAT 硬件加速可能绕过 PassWall2 与 AdGuardHome，须实机验证。
- QoS 只留 eqos-mtk（SQM 启用前须关 HNAT，等于放弃硬件加速）。

## 三、使用方法

### 刷机

产物只有 sysupgrade `.bin`，走 U-Boot 网页恢复页直刷；没有 `.itb`。

刷机前备份节点（订阅链接/截图）与 LuCI 备份：旧 PassWall 配置不会自动迁移到 PassWall2，节点须重建；建议不保留设置。

### 刷后检查

1. 设管理员密码。
2. 确认无线两个射频均为禁用。
3. 服务菜单里应有“硬盘休眠”与“p910nd - 打印服务器”；不应再有顶级 NAS 菜单。
4. AdGuardHome 只启用一个 init 脚本。
5. PassWall2 自动切换在 LuCI 里配：负载均衡组（leastPing，设为默认节点）或给主节点挂备用节点开自动切换。
6. 测 HNAT 是否绕过 PassWall2 与 AdGuardHome。

### 注意事项

- 128MB 闪存：sing-box 约 30MB、AdGuardHome 约 40MB，/overlay 余量有限；空间紧张时插 USB 3.0 U 盘扩容 /overlay（USB 驱动已编进固件）。
- NTFS 靠内核 ntfs3；ntfs-3g 与之冲突，不得加回。
- 每次重新运行都会拉取最新源码和软件包。

## 四、配置调整变更历史

### 修订记录

| 时间 | 版本 | 变更内容 |
|---|---|---|
| 2026-11-16 21:03 | 社区版基线 #4 | B 库建库；基线编成（.bin 41,921KB，ImmortalWrt 24.10-SNAPSHOT r33648，内核 6.6.133） |
| 2026-11-18 11:13 | 标准版 #5 | 标准版首次编成（97 包，.bin 55,522,093 字节，SHA256 `a2ba92fb…`） |
| 2026-11-18 22:12 | 标准版 #6 | 编成（97 包，.bin 55,522,093 字节，SHA256 `d4997eb9…`）；NAS 菜单并入服务、无线默认关双保险 |
| 2026-11-18 22:47 | 标准版 #6（未重编） | 文件浏览器已删（配置 94 包，SHA256 `a6f87c4d…`），已推库 |
| 2026-11-18 23:58 | 标准版 #6（未重编） | README 按四类口径重写并增加修订记录（本条） |
| 2026-11-19 02:11 | 标准版 #7 | 编成（94 包，文件浏览器已删；.bin 48,046,893 字节，SHA256 `1fdfe433…`） |
| 2026-11-19 08:09 | 标准版 #7（未重编） | README 口径调整：删“未包含”与“当前构建”两节，历史记录只留修订记录；README 只说明当前版本 |
| 2026-11-20 10:40 | 标准版 #7（未重编） | README 修正：上网管控删 accesscontrol，只留 banip（#7 manifest 414 行核对无此包） |
