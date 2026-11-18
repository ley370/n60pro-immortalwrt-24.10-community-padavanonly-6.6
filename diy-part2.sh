#!/bin/bash
# diy-part2.sh - post-config tweaks (runs inside openwrt/ after .config is loaded)
# Wireless-off + Argon default theme + Chinese UI are set by
# files/etc/uci-defaults/99-n60pro-defaults on first boot.
#
# Rust host build fix (2026-11-15, build #2 failed on this):
# The host rustc (1.96.0) tries to download a prebuilt LLVM from Rust CI
# (`download-ci-llvm`), but that CI artifact URL returns 404, so the whole
# build fails with "ERROR: failed to download llvm from ci".
# Fix: force the Rust package to build LLVM from source instead.
# (Known upstream issue: https://github.com/immortalwrt/packages/issues/1854)
# Side effect: LLVM compiles from source, adding roughly 1 hour to the build.
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile
if grep -q 'ci-llvm=false' feeds/packages/lang/rust/Makefile; then
  echo "diy-part2: rust download-ci-llvm disabled"
else
  echo "diy-part2: WARNING: ci-llvm pattern not found in feeds/packages/lang/rust/Makefile"
fi

# 2026-11-18: NAS 菜单并入服务（用户要求；标准版 #5 实测：NAS 下只有硬盘休眠与 p910nd 两项）。
# hd-idle 与 p910nd 的 menu.d 把入口注册在 admin/nas 下；改到 admin/services 后 NAS 一级菜单自动消失。
# 注意：menu.d 在 feeds 安装后才存在，必须放 diy-part2.sh（diy-part1.sh 时还没有）。
sed -i 's|"admin/nas/hd_idle"|"admin/services/hd_idle"|' feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json
sed -i 's|"admin/nas/p910nd"|"admin/services/p910nd"|' feeds/luci/applications/luci-app-p910nd/root/usr/share/luci/menu.d/luci-app-p910nd.json
if grep -q '"admin/services/hd_idle"' feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json && grep -q '"admin/services/p910nd"' feeds/luci/applications/luci-app-p910nd/root/usr/share/luci/menu.d/luci-app-p910nd.json; then
  echo "diy-part2: NAS menu merged into Services (hd-idle, p910nd)"
else
  echo "diy-part2: WARNING: NAS menu move failed (menu.d pattern not found)"
fi

# 2026-11-18: 无线默认关闭（标准版 #5 实测：99-n60pro-defaults 没关掉无线）。
# 根因：mt_wifi 的 detect_mtwifi() 生成的 wifi-device 节区名是 l1util 给的
# MT7986_1_1 / MT7986_1_2，不是 radio0/radio1；99 脚本里 radio0/radio1 的
# uci set 静默失败（uci -q），所以无线一直开着。
# 双保险：① 这里让 detect 生成的配置天生就是 disabled=1；
# ② 99-n60pro-defaults 改成遍历全部 wifi-device 节区关掉（见该文件）。
# 注意：mtwifi.sh 在源码树 package/mtk/applications/mtwifi-cfg/files/ 下，不是 feed。
if grep -q 'set wireless.${dev}.serialize=1' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh; then
  sed -i 's|set wireless.${dev}.serialize=1|set wireless.${dev}.serialize=1\n\t\t\t\t\tset wireless.${dev}.disabled=1|' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
  if grep -q 'set wireless.${dev}.disabled=1' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh; then
    echo "diy-part2: mtwifi detect now generates disabled radios"
  else
    echo "diy-part2: WARNING: mtwifi disabled patch did not apply"
  fi
else
  echo "diy-part2: WARNING: mtwifi.sh anchor not found, wireless detect not patched"
fi
