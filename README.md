# N60 Pro 标准版（standard）— ImmortalWrt 24.10-6.6 社区版

状态：已推 B 库并编译成功（run #5，2026-11-18 11:13，耗时 2h38m51s；`.bin` 55,522,093 字节，
SHA256 `a2ba92fb74795cc37d110d4f13fe48c1a131f3e89d0d9f063b6120ba6b3bd858`）。
用户定：“功能要全、插件不重复、都要有 LuCI、PassWall2 自动切换”，“就在原社区版库维护编译”。
2026-11-18 晚：标准版 #5 两项实测反馈待修（已改，待用户确认后重编 run #6）：
① NAS 菜单并入服务（hd-idle、p910nd 从 admin/nas 改到 admin/services）；
② 无线默认关未生效——根因是 wifi-device 节区名是 MT7986_1_1/2，不是 radio0/radio1，
99 脚本的 uci set 静默失败；#6 改成遍历全部 wifi-device 节区关掉，并让 mtwifi 的
detect 生成的配置天生就是 disabled=1。
2026-11-18 晚：用户决定删文件浏览器（filebrowser + LuCI + 中文包三行），已推库；暂不重编（用户 22:46 定），下一轮编时再触发。

## 与简洁版 / 丰富版的关系

- 底版 = 丰富版（99 个包）去重后 94 个包（2026-11-18 用户决定加回 statistics、加 USB 打印机共享、定时重启、自定义命令；文件浏览器 2026-11-18 晚用户决定删）；简洁版是其子集。
- 去重删了 13 行（见 `n60-pro.config` 文末注释与对照文档），另删文件浏览器 3 行（2026-11-18 晚用户决定删）：
  adblock×3、SmartDNS×3、mcproxy、ntfs-3g、SQM×4、luci-i18n-adguardhome-zh-cn。
- 保留丰富版新增：PassWall2 HAProxy、NTFS 内核驱动、F2FS、硬盘休眠、分区工具、
  vnstat2、banip。

## 功能插件说明（94 个包 `=y`，配置 SHA256 前 16 位 `a6f87c4d7b3e580b`）

| 功能 | 插件 | 说明 |
|---|---|---|
| 界面 | LuCI + Argon 主题 | 中文界面；主菜单、防火墙中文包 |
| 代理 | PassWall2 + sing-box | VLESS/Socks 节点，nftables 透明代理；HAProxy 负载均衡，刷后在 LuCI 里配自动切换（leastPing 均衡组 / 备用节点 auto_switch） |
| 去广告 | AdGuardHome + LuCI（v1.8） | DoH/DoT、查询日志、按客户端统计；24.10 feed 里没有它的 LuCI 界面，diy-part1.sh 从上游 clone |
| 远程访问 | WireGuard | 在“网络 → 接口”里配，手机在外连回家 |
| 动态域名 | DDNS | 域名自动指向家里公网 IP |
| 限速 | eqos-mtk | 按设备限速；SQM 已删（要开 SQM 得先关 HNAT） |
| 流量统计 | nlbwmon、vnstat2、statistics | 每台设备流量、接口总量、CPU/内存/流量历史曲线 |
| 上网管控 | accesscontrol、banip | 按时间管设备上网；封禁 IP 段 |
| IPTV | igmpproxy + udpxy | 组播转单播 |
| 端口转发 | UPnP（miniupnpd） | 刷后在“服务 → UPnP”里启用；双 NAT 下只开 N60 这一层 |
| 唤醒 | WoL | 远程唤醒局域网电脑 |
| 硬件加速 | TurboACC-MTK + HNAT + WARP、BBR | MTK 闭源加速栈；注意：HNAT 可能绕过 PassWall2/AdGuardHome，刷后须实测 |
| 无线 | mt_wifi + LuCI | 功能在；默认关闭（#5 未生效：关无线脚本用的 radio0/radio1 节区名不对，实际是 MT7986_1_1/2；#6 已修，待验证）；要开时在 LuCI 里启用两个 radio、设 SSID/密码 |
| USB 存储 | diskman、USB2/3、ext4/vfat/exfat/NTFS3/F2FS、hd-idle、parted | U 盘扩容 /overlay、格式化、硬盘休眠 |
| USB 打印机 | p910nd | 9100 端口共享 USB 打印机 |
| 网页终端 | ttyd | 网页里开 SSH 终端 |
| 自定义命令 | luci-app-commands | LuCI 里存常用命令，一点就跑 |
| 定时重启 | luci-app-autoreboot | 刷后在 LuCI 里设时间，默认不启用 |
| 断网自愈 | watchcat | 断网自动重启恢复 |
| 固定 IP | arpbind | IP/MAC 绑定 |
| 升级 | attendedsysupgrade、opkg 界面 | 升级保留软件包；LuCI 里装包 |

不含的：iStore、adblock、SmartDNS、SQM、Samba/Transmission、QoSmate、OpenClash/Nikki/HomeProxy（原因见下面“不补的”）。

## 关键点

- **去广告只留 AdGuardHome**：DoH/DoT、查询日志、按客户端统计。adblock 只有
  dnsmasq 黑名单，功能重复，删。
- **AdGuardHome 的 LuCI 界面**：24.10 的 feed 里没有 luci-app-adguardhome，
  `diy-part1.sh` 把上游 rufengsuixing/luci-app-adguardhome（v1.8）直接 clone 进
  `package/`（作者文档的用法；跟 passwall feed 同样跟 master 浮动、不钉哈希）。
  中文是该包内置的，没有独立语言包。编译后以 `.manifest` 中
  `luci-app-adguardhome` 在位为准。刷机后核查只启用一个 AdGuardHome 服务
  （该 LuCI 包自带 `/etc/init.d/AdGuardHome`，与本体包的 init 脚本并存）。
- **PassWall2 自动切换**：HAProxy 已开。刷机后在 LuCI 里做两件事：
  ① PassWall2 → 负载均衡，新建均衡组（推荐 leastPing），把 4 个节点（BWG×3＋RN×1）
  加进去，设为默认节点；② 给主节点配备用节点（auto_switch，主节点挂了自动切备用）。
  sing-box 自带的 urltest 是另一条路，不用 HAProxy 也能跑。
- **QoS 只留 eqos-mtk**：SQM 启用前须关 HNAT/TurboACC，等于放弃硬件加速，标准版保
  HNAT。想控 bufferbloat 时再换 SQM（同时关 HNAT）。
- **流量统计 nlbwmon + vnstat2，系统历史曲线加回 statistics**：2026-11-18 用户决定加回
  luci-app-statistics（collectd + rrdtool），CPU/内存/流量随时间的图表。
- **USB 打印机共享**：2026-11-18 用户决定加 p910nd + LuCI（kmod-usb-printer），
  USB 打印机插上即全网共享，9100 端口 raw 打印。
- **定时重启**：2026-11-18 用户决定加（luci-app-autoreboot），刷后在 LuCI 里设时间，默认不启用。
- **文件浏览器已删**：2026-11-18 晚用户决定删（filebrowser + LuCI + 中文包三行），不编进固件。
- **自定义命令**：2026-11-18 用户决定加 luci-app-commands + 中文包，在 LuCI 里存
  常用 shell 命令，一点就跑。
- **不补的**（沿用已定口径）：Samba/Transmission（NAS 已有）、QoSmate（与 HNAT 互斥）、
  OpenClash/Nikki/HomeProxy（不换代理核心）。

## 文件

- `n60-pro.config` — 94 个包 `=y`，SHA256 前 16 位 `a6f87c4d7b3e580b`（本地实测）
- `diy-part1.sh` — passwall 双 feed + AdGuardHome LuCI clone；`bash -n` 通过
- `diy-part2.sh`、`files/etc/uci-defaults/99-n60pro-defaults` — 与丰富版相同
  （LAN 192.168.6.1；无线默认关——#5 未生效，#6 修：关无线改遍历节区名 + detect 生成即 disabled，待验证）
- `.github/workflows/build.yml` — 与三库相同（仅 workflow_dispatch）

## 编译后验收（已完成，2026-11-18 11:13）

已推到 B 库 `ley370/n60pro-immortalwrt-24.10-community-padavanonly-6.6` 并触发，
run #5 成功，耗时 2h38m51s；产物 `.bin` 55,522,093 字节，
SHA256 `a2ba92fb74795cc37d110d4f13fe48c1a131f3e89d0d9f063b6120ba6b3bd858`，
sha256sums 12/12 OK；`.manifest` 417 行，PassWall2/sing-box/AdGuardHome/
luci-app-adguardhome/TurboACC/diskman/arpbind/filebrowser/p910nd 九项全在位。
只有 `.bin`、没有 `.itb`，走 U-Boot 恢复页直刷。
