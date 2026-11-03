# 01 · 进入 BROM 模式（最容易失败的一步）

BROM（Boot ROM）是 MTK 芯片的最高权限恢复模式，绕过系统一切限制。**写分区、解锁 BL、备份，全部依赖它。**

## 操作步骤

1. 机器**断电**，USB 线**先不要插机器端**（电脑端可以先插好）
2. 按住机身**全部实体按键不松手** —— CC7 上是：`音量+`、`音量−`、`静音`、`电源`
3. 保持按住，把 Micro-USB 插入机器
4. 听到 **两声提示音** 即为进入成功
5. 松手

> 若失败：**秒重插数据线**往往比反复按键更有效。四键按住不放 + 快速拔插，成功率最高。

## 判定成败的唯一硬标准

**MTKClient 能读到芯片信息**。读不到就是没进 brom —— 界面出现「MediaTek USB Port」不代表进了，那可能只是 preloader。

## 驱动：先装 UsbDk，再用 Zadig 换 WinUSB

这是本流程中**最关键的一步优化**。不处理驱动，MTKClient GUI 会反复出现：

```
Reconnecting to preloader...
```

然后无限卡死，怎么重试都不动。

**根治办法**：

1. 先确认 UsbDk 已安装并生效（见 [00](00-设备与工具.md)）
2. 让设备进 brom，打开 **Zadig**
3. 菜单 `Options → List All Devices` 勾上
4. 在设备列表选中 `VID_0E8D & PID_2001`（也可能显示为 `MediaTek USB Port` / 未知设备）
5. 右侧驱动选择 **WinUSB**，点 `Replace Driver` / `Install Driver`
6. 完成后重新进一次 brom

处理后 MTKClient 一次握手成功，不再重连。

## 常见失败原因（按概率排序）

| 排名 | 原因 | 排查方法 |
|---|---|---|
| 1 | **数据线只能充电不能传数据** | 用同一根线接手机/U 盘验证。这是第一大坑 |
| 2 | UsbDk 未装 / 装了没重启 | `Get-Service UsbDk` 看服务状态 |
| 3 | BROM 驱动没换成 WinUSB | 设备管理器里看驱动类型 |
| 4 | 按键没按全 / 松手太早 | 四键全部按住，听到两声提示音再松 |
| 5 | USB 口问题 | 换主板后置 USB 2.0 口，别用前面板或 HUB |

## 设备状态对照

| Windows 显示的 VID:PID | 含义 |
|---|---|
| `0E8D:2001` | BROM 模式（可以刷写） |
| `0E8D:201C` | 正常开机 / adb 模式 |
| `0E8D:2000` | Preloader（还没到 BROM） |

用 PowerShell 快速确认当前处于哪种模式：

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_0E8D' } |
  Select-Object Status, Class, FriendlyName, InstanceId
```

---

下一步 → [02 · 解锁 BootLoader](02-解锁BootLoader.md)
