# ImmortalWrt NanoPi R2S 自动构建

[![Build ImmortalWrt NanoPi R2S](https://github.com/xylplm/immortalwrt-r2s/actions/workflows/build-immortalwrt.yml/badge.svg)](https://github.com/xylplm/immortalwrt-r2s/actions/workflows/build-immortalwrt.yml)
[![ImmortalWrt](https://img.shields.io/badge/ImmortalWrt-25.12-blue)](https://immortalwrt.org/)
[![Target](https://img.shields.io/badge/target-rockchip%2Farmv8-green)](https://downloads.immortalwrt.org/releases/)

面向 FriendlyElec NanoPi R2S 的 ImmortalWrt 固件自动构建项目。仓库基于官方 ImmortalWrt `25.12` 系列 `rockchip/armv8` ImageBuilder，使用官方设备 profile `friendlyarm_nanopi-r2s`，通过 GitHub Actions 生成标准包、常用包和旁路由包三种固件。

> 本项目不是 ImmortalWrt 官方项目。刷写固件存在风险，请确认设备型号为 NanoPi R2S，并提前准备好恢复方式。

## 目录

- [特性](#特性)
- [支持设备](#支持设备)
- [固件变体](#固件变体)
- [内置内容](#内置内容)
- [旁路由配置](#旁路由配置)
- [Lucky](#lucky)
- [默认登录信息](#默认登录信息)
- [使用方式](#使用方式)
- [仓库结构](#仓库结构)
- [自定义](#自定义)
- [注意事项](#注意事项)
- [上游与许可证](#上游与许可证)

## 特性

- 基于官方 ImmortalWrt `25.12` 系列构建。
- 使用官方 NanoPi R2S profile：`friendlyarm_nanopi-r2s`。
- 每次构建输出 `base`、`plus`、`bypass` 三种变体。
- `plus` 只加入通用常用插件。
- `bypass` 额外加入 Soho、旁路由默认配置和 Lucky。
- GitHub Actions 支持手动构建、定时构建、Artifacts 和 Releases 发布。
- 构建后校验固件内容，防止旁路由配置、Lucky、Soho 包泄漏到非 bypass 固件。

## 支持设备

| 项目 | 内容 |
| --- | --- |
| 设备 | FriendlyElec NanoPi R2S |
| SoC | Rockchip RK3328 |
| ImmortalWrt target | `rockchip/armv8` |
| ImmortalWrt profile | `friendlyarm_nanopi-r2s` |
| 默认版本系列 | `25.12` |

## 固件变体

| 变体 | 文件后缀 | 默认管理地址 | rootfs 分区 | 说明 |
| --- | --- | --- | --- | --- |
| 标准包 | 无特殊后缀 | `192.168.1.1` | 1280 MiB | 官方 profile 默认内容，不写入额外配置 |
| 常用包 | `*-plus.img.gz` | `192.168.1.1` | 2048 MiB | 在标准包基础上追加 `packages/plus.txt` |
| 旁路由包 | `*-bypass.img.gz` | `10.11.11.3` | 4096 MiB | 在 plus 基础上追加 `packages/bypass.txt`、旁路由配置和 Lucky |

标准包保持精简；日常使用建议优先选择标准包或 `plus`。`bypass` 是固定旁路由环境的自用配置包，使用前请确认地址、网关、DNS 与自己的网络一致。

## 内置内容

### plus 和 bypass 共有

这些包维护在 [packages/plus.txt](packages/plus.txt)：

- `luci-theme-argon`
- `luci-app-argon-config`
- `luci-app-wol`
- `luci-app-openvpn-server`

### 仅 bypass 内置

这些包维护在 [packages/bypass.txt](packages/bypass.txt)：

- `soho-sealhelper`
- `soho`
- `luci-app-soho`

Soho 相关 APK 放在 [packages/local-apk](packages/local-apk)，只会进入 `bypass` 固件。Lucky 本地包放在 [packages/lucky](packages/lucky)，同样只会进入 `bypass` 固件。

## 旁路由配置

旁路由首启脚本位于 [files/bypass/etc/uci-defaults/99-bypass-router](files/bypass/etc/uci-defaults/99-bypass-router)，只会写入 `bypass` 固件。

NanoPi R2S 的 LAN 口是原生千兆口，`bypass` 固件固定使用官方 `lan` 接口作为旁路由接入口，并禁用 `wan/wan6`。刷入 `bypass` 固件后，建议把网线接在 R2S 的 LAN 口。

默认旁路由参数：

| 项目 | 值 |
| --- | --- |
| 管理地址 | `10.11.11.3/24` |
| 网关 | `10.11.11.1` |
| DNS | `10.11.11.1`、`119.29.29.29` |
| DHCP | 关闭 LAN DHCP、DHCPv6 和 RA |
| WAN | 禁用 `wan/wan6` |
| 时区 | `Asia/Shanghai` |
| IPv4 转发 | 开启 |

该脚本不会修改 root 密码。

## Lucky

Lucky 只会内置到 `bypass` 固件。

| 项目 | 值 |
| --- | --- |
| 安装目录 | `/etc/lucky.daji` |
| 服务脚本 | `/etc/init.d/lucky.daji` |
| 启动方式 | `lucky -c /etc/lucky.daji/lucky.conf` |
| 默认后台 | `http://10.11.11.3:16601/` |
| 默认账号 | `666` |
| 默认密码 | `666` |

构建时直接使用 [packages/lucky](packages/lucky) 中的本地 arm64 包，不在 Actions 中实时下载。

## 默认登录信息

本仓库不写入或修改 root 密码。官方 ImmortalWrt root 密码字段为空时，本项目生成的固件也保持为空。

| 固件 | 地址 | 用户名 | 密码 |
| --- | --- | --- | --- |
| 标准包 | `http://192.168.1.1/` | `root` | 空密码 |
| `plus` | `http://192.168.1.1/` | `root` | 空密码 |
| `bypass` | `http://10.11.11.3/` | `root` | 空密码 |

首次登录后建议立即设置 root 密码。

## 使用方式

### 下载固件

构建产物发布在 GitHub Releases 中。每个 Release 通常包含：

- 标准包固件。
- `*-plus.img.gz` 常用包固件。
- `*-bypass.img.gz` 旁路由固件。
- `sha256sums.txt` 校验文件。
- `rootfs-partsize.txt` 分区配置记录。
- `variants.txt` 本次构建变体记录。

下载后建议先校验 SHA256，再刷写到设备。

### 手动构建

进入 GitHub Actions 页面，运行 **Build ImmortalWrt NanoPi R2S**。

| 输入项 | 说明 |
| --- | --- |
| `version` | ImmortalWrt `25.12` 发布版本。留空时自动使用最新 `25.12.x` 稳定版 |
| `variants` | 选择本次构建的固件变体，默认构建全部变体 |
| `extra_packages` | 临时追加到 `plus` 和 `bypass` 的软件包，多个包用空格分隔 |
| `publish_release` | 发布到 GitHub Releases，或只生成 Actions Artifacts |
| `prerelease` | 是否标记为预发布 |

首次验证建议选择“只生成 Actions Artifacts”，确认产物正常后再发布 Release。

### 定时构建

默认每周五北京时间 09:20 自动构建一次，并发布到 Releases。

## 仓库结构

```text
.
├── .github/workflows/          # GitHub Actions 构建流程
├── config/build.env            # 默认构建参数
├── files/plus/                 # plus 和 bypass 共用的文件覆盖
├── files/bypass/               # 仅 bypass 使用的旁路由配置
├── files/lucky/                # 仅 bypass 使用的 Lucky 服务文件
├── packages/base.txt           # 标准包附加软件包列表
├── packages/plus.txt           # plus 附加软件包列表
├── packages/bypass.txt         # bypass 附加软件包列表
├── packages/local-apk/         # bypass 使用的本地 APK
└── packages/lucky/             # bypass 使用的 Lucky 本地包
```

## 自定义

- 修改通用常用包：编辑 [packages/plus.txt](packages/plus.txt)。
- 修改 bypass 专用包：编辑 [packages/bypass.txt](packages/bypass.txt)。
- 修改旁路由默认地址、网关或 DNS：编辑 [99-bypass-router](files/bypass/etc/uci-defaults/99-bypass-router)。
- 更新 Lucky：替换 [packages/lucky](packages/lucky) 中的 tar.gz 文件，并同步 workflow 中的 `LUCKY_LOCAL_PACKAGE` 文件名。
- 更新 Soho 本地包：替换 [packages/local-apk](packages/local-apk) 中对应 APK，并确保同一包只保留一个版本。

## 注意事项

- 请确认设备是 NanoPi R2S，不要刷入到 NanoPi R2S Plus 或其他相近设备。
- `bypass` 固件会禁用 WAN/WAN6，并固定使用 LAN 口作为旁路由接入口。
- `bypass` 固件默认管理地址为 `10.11.11.3`，刷写前请确认不会和现有网络冲突。
- 本项目不设置 root 密码，首次登录后请立即设置。
- 刷写、升级或扩容前请自行备份配置和重要数据。

## 上游与许可证

本项目构建所使用的固件源码、ImageBuilder、软件源和基础包来自 ImmortalWrt 官方发布资源。请遵循 ImmortalWrt 及各软件包上游项目的许可证。

本仓库当前未声明独立许可证。仓库中引用或内置的软件包、固件组件分别遵循其上游项目许可证。
