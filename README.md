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
- [旁路由配置（仅 bypass）](#旁路由配置仅-bypass)
- [Lucky（仅 bypass）](#lucky仅-bypass)
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
| 常用包 | `*-plus-*` | `192.168.1.1` | 2048 MiB | 在标准包基础上追加 `packages/plus.txt` |
| 旁路由包 | `*-bypass-*` | `10.11.11.3` | 4096 MiB | 作者自用包；在 plus 基础上追加 `packages/bypass.txt`、旁路由配置和 Lucky |

标准包保持精简；日常使用建议优先选择标准包或 `plus`。`bypass` 是作者固定旁路由环境的自用配置包，使用前请确认地址、网关、DNS 与自己的网络一致。

## 内置内容

### plus 和 bypass 共有

这些包维护在 [packages/plus.txt](packages/plus.txt)：

- `luci-theme-argon`
- `luci-app-argon-config`
- `luci-app-wol`
- `luci-app-openvpn-server`
- `kmod-zram` / `zram-swap`（尖峰内存兜底）

OpenVPN 说明（`plus` / `bypass`）：

- Luci 的 `luci-app-openvpn-server` 页面只会下载同一份 `client1` 配置。
- 固件默认开启 `duplicate_cn`（同证书多设备同时在线），方便个人一证多用。
- 首启脚本：[files/plus/etc/uci-defaults/98-openvpn-duplicate-cn](files/plus/etc/uci-defaults/98-openvpn-duplicate-cn)。
- 默认最多约 10 路并发（`max_clients`）；仅适合自用，证书泄露会影响所有共用设备。

zram 说明（`plus` / `bypass`）：

- 默认启用 **256 MiB** 压缩内存交换，仅在内存紧张发生换页时压缩，低负载几乎不占 CPU。
- 首启脚本：[files/plus/etc/uci-defaults/95-zram-swap](files/plus/etc/uci-defaults/95-zram-swap)。
- 这是防 OOM 的兜底，不是用来长期硬撑超大代理配置的。
- 压缩算法默认 **`lzo`**（与 LuCI 下拉选项一致；官方预编译 `kmod-zram` 通常只有 LZO，没有可用的 `lz4`/`zstd`）。若写成 `lzo-rle`，运行时可能仍有效，但 LuCI 会显示「-- 请选择 --」。

### 仅 bypass 内置

这些包维护在 [packages/bypass.txt](packages/bypass.txt)：

- `soho-sealhelper`
- `soho`
- `luci-app-soho`
- `kmod-inet-diag`

Soho 相关 APK 放在 [packages/local-apk](packages/local-apk)，只会进入 `bypass` 固件。Lucky 本地包放在 [packages/lucky](packages/lucky)，同样只会进入 `bypass` 固件。

## 旁路由配置（仅 bypass）

旁路由首启脚本位于 [files/bypass/etc/uci-defaults/99-bypass-router](files/bypass/etc/uci-defaults/99-bypass-router)，只会写入 `bypass` 固件。

NanoPi R2S 有两个千兆口：

| 板子丝印 | 内核网卡 | 硬件 | bypass 用途 |
| --- | --- | --- | --- |
| **WAN** | `eth0` | SoC 原生 GMAC | **旁路由上联（默认）** |
| **LAN** | `eth1` | USB RTL815x | 预留/禁用 |

`bypass` 固件默认把管理口 `lan`（`br-lan`）绑到原生 **`eth0`（WAN 口）**，并禁用逻辑 `wan/wan6`（停在 USB 的 `eth1` 上）。刷入后请把网线插在 R2S 的 **WAN** 口接主路由。

脚本带有首启标记 `r2s_bypass_defaults`。首次应用后会写入标记；后续通过 sysupgrade 并选择保留配置时，不会再次覆盖已经存在的网络配置。

默认旁路由参数：

| 项目 | 值 |
| --- | --- |
| 管理地址 | `10.11.11.3/24` |
| 网关 | `10.11.11.1` |
| DNS | `10.11.11.1`、`119.29.29.29` |
| 上联网口 | 原生 `eth0`（板子丝印 **WAN**） |
| DHCP | 关闭 LAN DHCP、DHCPv6 和 RA |
| WAN | 禁用 `wan/wan6`（逻辑接口停在 `eth1`） |
| LAN 防火墙 | 允许转发；开启 IP 动态伪装（masquerade） |
| 时区 | `Asia/Shanghai` |
| IPv4 转发 | 开启 |

开启 LAN masquerade 是为了让 OpenVPN 等客户端访问局域网其他设备时有正确回程：内网设备会把应答回给旁路由 `10.11.11.3`，而不是因不认识 `10.9.0.0/24` 而丢包。若主路由已为 VPN 网段配置了静态路由，也可自行关闭该选项。

该脚本不会修改 root 密码。

## Lucky（仅 bypass）

Lucky 只会内置到 `bypass` 固件。

| 项目 | 值 |
| --- | --- |
| 安装目录 | `/etc/lucky.daji` |
| 服务脚本 | `/etc/init.d/lucky.daji` |
| 启动方式 | `lucky -c /etc/lucky.daji/lucky.conf` |
| 默认后台 | `http://10.11.11.3:16601/` |
| 默认账号 | `666` |
| 默认密码 | `666` |

构建时直接使用 [packages/lucky](packages/lucky) 中的本地 arm64 包，不在 Actions 中实时下载。OpenWrt init 脚本来自 Lucky 安装包内置的 `scripts/luckyservice`，构建时复制为 `/etc/init.d/lucky.daji`。

## Mihomo 内核（仅 bypass）

`bypass` 固件会在 GitHub Actions 打包时自动查询 [Mihomo 最新稳定版](https://api.github.com/repos/MetaCubeX/mihomo/releases/latest)，下载 `linux-arm64` 官方压缩包，校验 GitHub API 返回的 SHA256 摘要，解压后内置到 `/usr/bin/mihomo`。设备首次启动不需要访问 GitHub；SOHO 内核页面仍可在设备运行后继续在线升级。

| 项目 | 值 |
| --- | --- |
| 文件 | `/usr/bin/mihomo` |
| 版本 | 每次打包时自动使用最新正式版 |
| 架构 | `linux arm64`（适配设备 `aarch64`） |
| 构建范围 | 仅 `bypass`；标准包和 `plus` 不包含 |

如果最新内核下载失败，`bypass` 构建会直接终止，避免把过期内核打进固件。

构建流程会在打包前检查下载资产的 SHA256 和 `mihomo -v` 版本，并在生成镜像后再次校验。每次构建的具体 Mihomo 版本和 SHA256 会显示在 Actions 日志中。

本项目会在首次启动且 root 密码仍为空时设置默认密码为 `password`。如果通过 sysupgrade 保留配置，或用户已经设置过 root 密码，则不会覆盖现有密码。

| 固件 | 地址 | 用户名 | 密码 |
| --- | --- | --- | --- |
| 标准包 | `http://192.168.1.1/` | `root` | `password` |
| `plus` | `http://192.168.1.1/` | `root` | `password` |
| `bypass` | `http://10.11.11.3/` | `root` | `password` |

首次登录后建议立即修改默认 root 密码。

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
- 更新 Mihomo 内核策略：workflow 每次自动下载最新稳定版，无需手动替换仓库文件。
- 更新 Soho 本地包：替换 [packages/local-apk](packages/local-apk) 中对应 APK，并确保同一包只保留一个版本。

## 保留配置升级（sysupgrade）

R2S 的 boot 分区只有约 **16MB**。升级并勾选「保留配置」时，OpenWrt 会把备份放到该分区，因此备份体积必须远小于 16MB。

### 为什么“保留配置”容易挂

历史上有两类故障：

1. **备份过大**：把 `/etc/soho/`（含 geo/日志）或 `/etc/lucky.daji/`（含 12MB 二进制）整目录保留，备份 40MB+，写不进 16MB boot，升级中断或恢复残缺。
2. **配置恢复不完整**：固件已写入，但 overlay/网络 UCI 未完整恢复，设备“像挂了”（其实可能已启动，只是管理地址不是 `10.11.11.3`）。`99-bypass-router` 在标记 `r2s_bypass_defaults=1` 后不会再次改网络，所以需要启动自救。

### 本仓库策略

| 组件 | 会保留 | 不会保留（体积过大或可由固件重建） |
| --- | --- | --- |
| Soho | `/etc/config/soho`、账号/会话等小状态文件（`account.enc`、`session.enc` 等） | `/etc/soho/geo/`、日志（`kernel.log`/`app.log` 等） |
| Lucky | 与 Lucky 官方导出一致：`lucky_*.lkcf`、`lucky.conf`（若存在）、`porttrapdb/`、`statushistorydb/` | `lucky` 二进制、`scripts/`、`ipdb/` 等 |
| 网络/系统 | 常规 OpenWrt 配置（network、firewall、dropbear 等） | — |

加固实现：

- [files/bypass/lib/upgrade/soho-conffiles.sh](files/bypass/lib/upgrade/soho-conffiles.sh)
- [files/lucky/lib/upgrade/lucky-conffiles.sh](files/lucky/lib/upgrade/lucky-conffiles.sh)
- 首启清理错误整目录规则：`96-bypass-sysupgrade`、`98-lucky-daji`
- 升级前自检：`/usr/sbin/r2s-check-sysupgrade`
- 推荐 CLI 升级包装：`/usr/sbin/r2s-sysupgrade`（升级前强制落盘证据）
- 诊断落盘：`/usr/sbin/r2s-upgrade-log`
- 启动管理地址自救：`/etc/init.d/r2s-mgmt-rescue`（lan 无 IPv4 时强制回 `10.11.11.3`）
- 每次开机快照：`/etc/init.d/r2s-diag`

### 升级失败落盘日志（下次可提取）

`logread` 在内存里，拔卡/断电就没了。本仓库会把**小体积证据**写到两处：

| 位置 | 路径 | 说明 |
| --- | --- | --- |
| **boot 分区**（优先） | `/mnt/mmcblk0p1/r2s-diag/` | 刷 rootfs 后仍在；读卡器上通常是第一分区 |
| overlay | `/etc/r2s-diag/` | root 可写时同步一份 |
| 当前运行 | `/tmp/r2s-diag/` | 仅当次开机 |

典型文件：

- `events.log`：时间线（preflight / pre-upgrade / post-boot / rescue）
- `pre-upgrade-meta.txt`：升级前备份体积、boot 剩余、固件路径
- `sysupgrade.conf` / `sysupgrade.list`：升级前保留列表
- `snap-*.txt` / `last-snapshot.txt`：网络、挂载、df、dmesg/logread 尾部、soho 包版本等
- 自救时额外：`snap-rescue-*.txt`、`snap-post-rescue-*.txt`

设备仍可 SSH 时：

```sh
r2s-upgrade-log show
ls -la /mnt/mmcblk0p1/r2s-diag/ /etc/r2s-diag/
```

设备挂了、TF 插读卡器时（Windows 常把 boot 分区分成可访问卷）：

1. 打开 boot 分区（约 16MB，含 `kernel.img` / `boot.scr`）
2. 进入 `r2s-diag/`
3. 把整个目录拷走分析

### 推荐升级步骤（bypass）

```sh
# 1) 升级前检查（必须 OK）
r2s-check-sysupgrade

# 2) 上传固件后保留配置升级（推荐包装命令，会先写 boot 证据）
r2s-sysupgrade -v /tmp/firmware.bin

# 3) 等待 1–2 分钟；若原地址不通，试：
#    http://10.11.11.3/   或  ssh root@10.11.11.3
```

> LuCI 网页升级不一定走 `r2s-sysupgrade`。网页升级前请先 SSH 执行一次  
> `r2s-check-sysupgrade && r2s-upgrade-log pre-upgrade /tmp/firmware.bin`  
> 再在 LuCI 点升级；开机后仍会有 `r2s-diag` 的 post-boot 快照。

手动估体积（应远小于约 5–6MB）：

```sh
sysupgrade -l | while read -r f; do
  [ -e "$f" ] || continue
  wc -c < "$f"
done | awk '{s+=$1} END{printf "%.2f MB\n", s/1024/1024}'
```

若曾手动在 `/etc/sysupgrade.conf` 写入 `/etc/soho/` 或 `/etc/lucky.daji/`，请删除这两行后再升级。

**更稳妥的两次法（推荐生产环境）：**

1. 先用 LuCI/CLI **导出备份**（确认约 1–2MB）
2. **不保留配置**刷入新固件
3. 能上 `10.11.11.3` 后，再 **恢复备份**

这样即使 keep-config 路径异常，也不会“整机不可达”。

## 注意事项

- 请确认设备是 NanoPi R2S，不要刷入到 NanoPi R2S Plus 或其他相近设备。
- `bypass` 固件会禁用逻辑 WAN/WAN6，并固定使用原生 **WAN 口（eth0）** 作为旁路由上联；板子丝印 LAN 口（USB eth1）默认不使用。
- `bypass` 固件默认管理地址为 `10.11.11.3`，刷写前请确认不会和现有网络冲突。
- 首次启动时会为仍为空的 root 密码设置默认值 `password`；首次登录后请立即修改。
- 刷写、升级或扩容前请自行备份配置和重要数据。
- 保留配置升级时不要把整个 `/etc/soho/` 或 `/etc/lucky.daji/` 写入 `sysupgrade.conf`，否则备份会撑爆 boot 分区导致升级失败。

## 上游与许可证

本项目构建所使用的固件源码、ImageBuilder、软件源和基础包来自 ImmortalWrt 官方发布资源。请遵循 ImmortalWrt 及各软件包上游项目的许可证。

本仓库当前未声明独立许可证。仓库中引用或内置的软件包、固件组件分别遵循其上游项目许可证。
