#!/bin/bash
# diy-part1.sh - add third-party feeds (runs inside openwrt/ before feeds update)
#
# v12 (2026-11-15): PassWall2 feeds. PassWall2 is NOT in the official
# ImmortalWrt feeds, so both feeds below are required:
# - passwall2: luci-app-passwall2 itself
#   (new org: Openwrt-Passwall/openwrt-passwall2, was xiaorouji/openwrt-passwall2)
# - passwall_packages: its dependencies not in official feeds
#   (chinadns-ng, tcping, geoview, and the sing-box/xray helper packages)
#   https://github.com/xiaorouji/openwrt-passwall-packages.git;main
# 2026-11-16 借鉴同型号库的钉版本做法：两个 feed 不再跟 main 浮动，钉到 2026-11-16
# 当天的 HEAD 快照（passwall2 9ea760ff、passwall_packages efc4093b），可复现、
# 上游改动不会悄悄破坏编译；该快照尚未在 B 库上编过，首编验证。
# The workflow then runs `./scripts/feeds update -a && ./scripts/feeds install -a`,
# so these feeds are picked up automatically. The grep guards make the
# script idempotent if it ever runs twice.
grep -q '^src-git passwall_packages ' feeds.conf.default || echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;efc4093be1477b66b95a33ca00e7a9d819ebc8fb' >> feeds.conf.default
grep -q '^src-git passwall2 ' feeds.conf.default || echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git;9ea760ffdee3fd8735df6a5bee842b3dd654be86' >> feeds.conf.default
