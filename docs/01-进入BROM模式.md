# 01 · 进入 BROM 模式（最容易失败的一步）

BROM（Boot ROM）是 MTK 芯片的最高权限恢复模式，绕过系统一切限制。**写分区、解锁 BL、备份，全部依赖它。**

## 操作步骤（实测顺序，别改）

> 关键是**顺序**：USB 全程连着不动，先通电、再按四键。**不是**"先按住再插线"。

1. **机器断电**，保持 **10 秒以上**（让电容放干净，断得不够久进不去）
2. **USB 线接好** —— 电脑端和机器端都插上，全程不拔
3. 打开 **MTKClient**，准备接收
4. **插电**（机器上电）
5. 通电后**立刻按住 4 个实体键不松手** —— CC7 上是：`音量+`、`音量−`、`静音`、`电源`
6. 屏幕亮一次，**响一声**
7. 过一会儿屏幕**再亮一次**，**再响一声**
8. 抬头看 MTKClient：**能读到芯片信息 = 成功进入 BROM**，此时才松手

**松手的信号是「MTKClient 读到芯片」，不是「听到两声」**。两声只是过程，真正进没进以软件读到为准。

> 若失败：**重新断电 10 秒以上，再走一遍**。USB 别拔、别插拔数据线换顺序 —— 这套流程的有效性就建立在 USB 全程连着、按键时机卡在通电后。

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
| 4 | **断电时间不够** | 拔电后至少要 10 秒，电容没放干净进不去 |
| 5 | 按键没按全 / 松手太早 | 四键全部按住，**等到 MTKClient 读到芯片才松**（不是听见两声就松） |
| 6 | USB 口问题 | 换主板后置 USB 2.0 口，别用前面板或 HUB |

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
