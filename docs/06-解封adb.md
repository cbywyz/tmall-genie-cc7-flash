# 06 · 解封 adb（本流程最难的一步）

## 现象

设备正常开机、USB 能识别、`adb devices` 能看到设备，但是：

```
$ adb shell
error: closed
```

端口开了、设备认到了，**shell 通道被协议层直接拒绝**。

## 这是阿里做的什么手脚

三个层次叠加：

| 层次 | 手段 | 表现 |
|---|---|---|
| 1 | 关闭 USB 调试 UI 入口 | 设置里根本没有开发者选项的调试开关 |
| 2 | `adbd` 二进制被改造 | 内置自定义总开关检查，不满足就拒绝 shell |
| 3 | 缺少 `ro.debuggable` / `ro.secure=0` | shell 拿不到权限 |

## 三轮实战过程（照着这个顺序走）

### 第一轮：常规手段 —— 不够

改 `system/build.prop`：

```properties
ro.adb.secure=0
persist.adb.tcp.port=5555
```

结果：**TCP 端口 5555 开了**（`adb connect IP:5555` 能连上），但 `adb shell` 依然 `error: closed`。

说明问题不在配置层，在 `adbd` 程序内部。

### 第二轮：逆向 `adbd` 找隐藏开关

`adbd` 是 ELF32 / ARM 的可执行文件，位于 `system/bin/adbd`。阿里在里面加了一段自定义逻辑：**读取一个隐藏属性，不满足就拒绝服务**。

定位方法（离线分析 system.img 里的 adbd）：

```bash
file adbd                     # ELF 32-bit LSB, ARM
readelf -l adbd               # 看 Program Headers 里的 PT_LOAD 段
strings -a -t x adbd | grep -i -E "persist\.|adb" | head -50
```

关键点：`strings` 输出的偏移是**文件偏移**，而 ARM 代码里引用字符串用的是**虚拟地址**。换算公式：

```
VA = p_vaddr - p_offset + file_offset
```

（对每个 PT_LOAD 段分别判断字符串落在哪个段里）

顺着交叉引用找过去，发现被读取的属性名：

```
persist.sys.adb.enabled
```

—— 这就是阿里的自定义总开关。默认不存在 = 关。

### 第三轮：把开关打开 + 补齐可调试标记 —— 成功

改 `system/build.prop`：

```properties
ro.adb.secure=0
persist.adb.tcp.port=5555
persist.sys.adb.enabled=1        # ← 决定性的一行
```

改 `system/etc/prop.default`（treble 设备这个文件优先级高于 build.prop）：

```properties
ro.secure=0
ro.debuggable=1
ro.adb.secure=0
```

重新打包 `system.img` → 写回 → 重启。

结果：

```
$ adb shell id
uid=2000(shell) gid=2000(shell)   # ✅ shell 通了
```

拿到 uid=2000 之后，`adb install`、`adb push`、`am`、`pm`、`dumpsys` 全部可用 —— **这是后续所有操作的基础**。

## 为什么必须改 prop.default

Android 8.1 起（treble），`prop.default` 在 `system/etc/` 下，且加载顺序晚于 `build.prop`，**同名属性以 prop.default 为准**。只改 build.prop 会出现「改完没效果」的假象。

## 修改方式

因为此时还没 root，**只能在离线状态改 system.img**：

1. CRBuilder 解包 `system.img`（就是你刚注入完 APK 的那个）
2. 编辑 `system/build.prop` 和 `system/etc/prop.default`（用 Notepad++ / VS Code，注意保持 **LF 换行**，不要变成 CRLF）
3. 重新打包 → 写回 → 重启

> 每次改动都要重新刷一次 system，所以三轮 = 三次刷写。建议一次性把四处改动都加上，减少刷写次数。

## 验证清单

```bash
adb shell id                                  # uid=2000(shell)
adb shell pm list packages | wc -l            # 能列包名
adb shell settings get global window_animation_scale   # 能读设置
adb shell am start -n com.dangbei1.tvlauncher/...      # 能启动应用
```

全部通过 = adb 完全解封。

## 顺带一提：解封后可以开 WiFi adb

`persist.adb.tcp.port=5555` 已生效，设备联网后可以直接：

```bash
adb connect <设备局域网IP>:5555
```

**注意**：这台设备的 WiFi adb 空闲久了会掉线（老 `adbd` 的已知毛病），掉线重连即用，不要当成故障。

---

下一步 → [07 · 安装 Magisk 获取 root](07-安装Magisk获取root.md)
