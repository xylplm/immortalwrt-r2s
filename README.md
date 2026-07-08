# ImmortalWrt NanoPi R2S 自动构建

基于官方 ImmortalWrt `25.12` 系列的 `rockchip/armv8` ImageBuilder，为 FriendlyElec NanoPi R2S 生成固件。R2S 已经在 ImmortalWrt 官方支持列表中，本仓库直接使用官方 profile：`friendlyarm_nanopi-r2s`。

## 固件变体

同一次构建会发布三个变体。标准包不带特殊后缀，另外两个变体用后缀区分用途。

| 文件名 | 用途 | rootfs 分区 | 内容 |
| --- | --- | --- | --- |
| 无特殊后缀 | 标准包 | 1280 MiB | 官方 NanoPi R2S profile 默认包，不写入旁路由配置 |
| `*-plus.img.gz` | 常用包 | 2048 MiB | 在标准包基础上追加 `packages/plus.txt` |
| `*-bypass.img.gz` | 自用旁路由包 | 4096 MiB | 在 `plus` 基础上追加 `packages/bypass.txt`、旁路由首启配置和 Lucky |

`bypass` 是维护者自用旁路由配置包，会把管理地址改为 `10.11.11.3/24`。其他用户建议使用标准包或 `plus` 包。

## 内置包

标准包保持精简，不额外添加常用包。

`plus` 和 `bypass` 都会额外内置：

- `luci-theme-argon`
- `luci-app-argon-config`
- `luci-app-wol`
- `luci-app-openvpn-server`

只有 `bypass` 会额外内置：

- `soho-sealhelper`
- `soho`
- `luci-app-soho`

常用包维护在 [packages/plus.txt](packages/plus.txt)，只属于旁路由模式的包维护在 [packages/bypass.txt](packages/bypass.txt)。Soho 相关包来自本仓库的 [packages/local-apk](packages/local-apk) 本地 APK，只会进入 `bypass` 固件。

## 旁路由配置（仅 bypass 固件）

旁路由首启脚本位于 [files/bypass/etc/uci-defaults/99-bypass-router](files/bypass/etc/uci-defaults/99-bypass-router)，只会进入 `bypass` 固件。

NanoPi R2S 的 LAN 口是原生千兆口，本仓库的 `bypass` 固件固定使用官方 `lan` 接口作为旁路由接入口，并禁用 `wan/wan6`。刷入后建议把网线接在 R2S 的 LAN 口。

脚本会设置：

- 静态管理地址：`10.11.11.3/24`
- 网关：`10.11.11.1`
- DNS：`10.11.11.1`、`119.29.29.29`
- 关闭 LAN DHCP、DHCPv6 和 RA
- 禁用 WAN/WAN6 接口
- LAN zone 放行 input/output/forward
- 时区：`Asia/Shanghai`
- 开启 IPv4 forwarding

脚本不会修改 root 密码。

## Lucky 内置说明（仅 bypass 固件）

只有 `bypass` 固件内置 Lucky，标准包和 `plus` 都不内置。

- 安装目录：`/etc/lucky.daji`
- 服务脚本：`/etc/init.d/lucky.daji`
- 启动方式：`lucky -c /etc/lucky.daji/lucky.conf`
- 默认后台地址：`http://10.11.11.3:16601/`
- 默认账号和密码：`666` / `666`

构建时会从 [packages/lucky](packages/lucky) 使用本地 Lucky arm64 包，不再实时下载。

## 默认登录信息

本仓库不写入或修改 root 密码。官方 ImmortalWrt 默认 root 密码字段为空时，本仓库构建出的固件也保持为空。

| 固件 | 默认管理地址 | 用户名 | 默认密码 |
| --- | --- | --- | --- |
| 标准包 | `http://192.168.1.1/` | `root` | 空密码 |
| `plus` | `http://192.168.1.1/` | `root` | 空密码 |
| `bypass` | `http://10.11.11.3/` | `root` | 空密码 |

首次登录后建议立即设置 root 密码。

## 自动构建

GitHub Actions 每周五北京时间 09:20 自动运行一次，并发布到 Releases。

也可以在 Actions 页面手动运行 **Build ImmortalWrt NanoPi R2S**：

- `version`：ImmortalWrt 25.12 发布版本；留空时自动使用最新 25.12 稳定版。
- `variants`：选择本次要构建的固件变体，默认“全部变体”。
- `extra_packages`：临时追加到 `plus` 和 `bypass` 的软件包，多个包用空格分隔；一般留空。
- `publish_release`：选择发布到 GitHub Releases，或只生成 Actions Artifacts。
- `prerelease`：选择正式发布或标记为预发布。

校验文件为 `sha256sums.txt`。分区配置记录在 `rootfs-partsize.txt`。
