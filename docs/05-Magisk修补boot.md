# 05 · Magisk 修补 boot 分区

原理：Magisk 不修改 `system`，而是给 `boot` 分区的 ramdisk 加一层 hook，在系统启动前接管、挂载自己的 overlay。所以 **boot 是唯一需要动的分区**。

## 操作（MagiskPatcher）

| 参数 | 必须选 | 选错的后果 |
|---|---|---|
| 架构 | **arm**（第 2 项） | 选 arm64 → 开机黑屏/砖 |
| Magisk 版本 | v25.2 | — |
| 保持 dm-verity 验证 | ✅ 勾选 | 不勾可能 BL 校验失败 |
| 保持强制加密 | ✅ 勾选 | 不勾 `/data` 解密异常 |
| 修补 vbmeta 标志 | ✅ 勾选 | 不勾可能开机进 fastboot |

输入 `backup/boot.bin` → 输出修补后的 `boot_patched.bin`。

> ⚠️ CC7 是 **armeabi-v7a**，`getprop ro.product.cpu.abi` 可确认。别想当然选 arm64。

## 写回

```
MTKClient → Write Partition → boot → 选择 boot_patched.bin
```

### 顺序建议：system 与 boot 分开写

| 做法 | 优点 | 缺点 |
|---|---|---|
| 一次性全写 | 快 | 出问题分不清是哪个分区的锅 |
| **分开写 + 分别开机验证**（推荐） | 出问题能立刻定位 | 多刷一次 BROM |

本仓库采用：先写 `system` → 开机确认能正常启动 → 再写 `boot`。

## 首次开机

- 会比平时**慢很多**（首次挂载 Magisk overlay + 重新编译）
- **不要中途断电**，等到出现桌面
- 如果卡超过 5 分钟：重新进 brom 写回 `backup/boot.bin` 排除 boot 的问题

## 验证 Magisk 已注入

```bash
adb shell "ls /data/adb"            # 应有 magisk 相关目录（首次开机后生成）
adb shell "getprop | grep magisk"   # 可能为空，正常
```

更可靠的验证：开机后桌面出现 **Magisk 应用图标**（即使还未装 APK，Magisk 会在首次启动后提示安装）。

## 常见失败

| 现象 | 原因 | 处理 |
|---|---|---|
| 开机黑屏 / 卡 logo | 架构选错（arm64） | 写回原 `boot.bin`，重选 arm |
| 开机进 fastboot | vbmeta 标志没修补 | 写回原 boot，重做时勾上修补 vbmeta |
| 开机后 `/data` 无法解密 | 没保持强制加密 | 同上，重做时勾上 |
| Magisk 能开但授权弹窗不出 | Magisk 被塞进了 `system/app` | 换普通应用安装方式（见 07） |

---

下一步 → [06 · 解封 adb](06-解封adb.md)
