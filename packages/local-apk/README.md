# 本地 APK 包

此目录存放官方 ImmortalWrt 软件源里没有、但需要随固件构建内置的 APK。当前这些包只通过 [../bypass.txt](../bypass.txt) 进入 `bypass` 固件，标准包和 `plus` 包不会包含。

构建流程会在 ImageBuilder 开始打包前，把匹配的 APK 复制到 ImageBuilder 的本地 `packages/` 目录，并让 ImageBuilder 在构建阶段安装，避免开机后再执行 `apk add --allow-untrusted`。源文件名如果使用 `name_version_arch.apk` 形式，复制时会转换为 APK 仓库可取包的 `name-version.apk` 形式。

Soho 官方 APK 安装顺序为 `soho-sealhelper`、`soho`、`luci-app-soho`。`soho-sealhelper` 必须匹配目标架构；带架构后缀的文件名必须使用 ImageBuilder 的 `ARCH_PACKAGES`，当前官方包未带架构后缀。`soho` 和 `luci-app-soho` 是通用包，更新版本时保持每个包只保留一个 APK 文件。

当前文件：

| 包 | 文件 | 说明 |
| --- | --- | --- |
| `soho-sealhelper` | `soho-sealhelper-2.0.15-r1.apk` | 当前官方包未在文件名中标注架构 |
| `soho` | `soho-2.0.15-r1.apk` | 通用包 |
| `luci-app-soho` | `luci-app-soho-2.0.15-r1.apk` | LuCI 界面包 |

更新版本时请保持每个包只保留一个 APK 文件；workflow 会检查数量，避免误把旧版本一起打进固件。
