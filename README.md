# N60 Pro 标准版（standard）— ImmortalWrt 24.10-6.6 社区版

状态：SUGGESTED（2026-11-18）。用户定：“功能要全、插件不重复、都要有 LuCI、
PassWall2 自动切换”，并说“先分析做好配置文件，待我通知后编译”“就在原社区版库维护编译”。
本目录只备好 6 个文件，不推库、不触发编译，等用户一句话再动手。

## 与简洁版 / 丰富版的关系

- 底版 = 丰富版（99 个包）去重后 97 个包（2026-11-18 用户决定加回 statistics、加 USB 打印机共享、文件浏览器、定时重启、自定义命令）；简洁版是其子集。
- 去重删了 13 行（见 `n60-pro.config` 文末注释与对照文档）：
  adblock×3、SmartDNS×3、mcproxy、ntfs-3g、SQM×4、luci-i18n-adguardhome-zh-cn。
- 保留丰富版新增：PassWall2 HAProxy、NTFS 内核驱动、F2FS、硬盘休眠、分区工具、
  vnstat2、banip。

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
- **文件浏览器、定时重启**：2026-11-18 用户决定都加。文件浏览器（filebrowser + LuCI）
  在 LuCI 里直接管理路由器上的文件；定时重启（luci-app-autoreboot）刷后在 LuCI 里
  设时间，默认不启用。
- **自定义命令**：2026-11-18 用户决定加 luci-app-commands + 中文包，在 LuCI 里存
  常用 shell 命令，一点就跑。
- **不补的**（沿用已定口径）：Samba/Transmission（NAS 已有）、QoSmate（与 HNAT 互斥）、
  OpenClash/Nikki/HomeProxy（不换代理核心）。

## 文件

- `n60-pro.config` — 97 个包 `=y`，SHA256 前 16 位 `77bb1ed4c87da918`（本地实测）
- `diy-part1.sh` — passwall 双 feed + AdGuardHome LuCI clone；`bash -n` 通过
- `diy-part2.sh`、`files/etc/uci-defaults/99-n60pro-defaults` — 与丰富版相同
  （LAN 192.168.6.1，无线默认关）
- `.github/workflows/build.yml` — 与三库相同（仅 workflow_dispatch）

## 编译后验收（待用户通知后执行）

推到 B 库 `ley370/n60pro-immortalwrt-24.10-community-padavanonly-6.6` →
触发 workflow → 每小时检查 → 产物 `.bin` 约 47–48MB（预估，未实测）→
SHA256 对 sha256sums、`.manifest` 核对 PassWall2/sing-box/AdGuardHome/
luci-app-adguardhome/TurboACC/diskman/arpbind 在位。
