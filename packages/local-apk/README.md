# 本地 APK 包

此目录存放官方 ImmortalWrt 软件源里没有、但需要随固件构建内置的 APK。当前这些包只通过 [../bypass.txt](../bypass.txt) 进入 `bypass` 固件，标准包和 `plus` 包不会包含。

构建流程会在 ImageBuilder 开始打包前，把匹配的 APK 复制到 ImageBuilder 的本地 `packages/` 目录，并让 ImageBuilder 在构建阶段安装，避免开机后再执行 `apk add --allow-untrusted`。源文件名如果使用 `name_version_arch.apk` 形式，复制时会转换为 APK 仓库可取包的 `name-version.apk` 形式。

Soho 官方 APK 安装顺序为 `soho-sealhelper`、`soho`、`luci-app-soho`。

更新规则（推荐）：

1. 直接替换本目录中的 APK 文件
2. 每个包只保留**一个**版本（workflow 会检查数量，多版本会构建失败）
3. 无需改 workflow 中的版本号；匹配规则按文件名自动识别
4. `soho-sealhelper` 支持两种文件名：
   - 无架构后缀：`soho-sealhelper-<version>.apk`（当前官方包）
   - 带架构后缀：`soho-sealhelper_<version>_<ARCH_PACKAGES>.apk` 或 `soho-sealhelper-<version>_<ARCH_PACKAGES>.apk`（架构必须匹配 ImageBuilder）
5. `soho` / `luci-app-soho` 为通用包：`soho-<version>.apk`、`luci-app-soho-<version>.apk`

当前文件：

| 包 | 文件 | 说明 |
| --- | --- | --- |
| `soho-sealhelper` | `soho-sealhelper-2.0.16-r1.apk` | 架构相关包；当前官方文件名未标注架构 |
| `soho` | `soho-2.0.16-r1.apk` | 通用包 |
| `luci-app-soho` | `luci-app-soho-2.0.16-r1.apk` | LuCI 界面包 |
