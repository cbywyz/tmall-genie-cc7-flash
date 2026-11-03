# 07 · 安装 Magisk 获取 root

前面 [05](05-Magisk修补boot.md) 只做了「boot 分区注入」，Magisk 的真正管理界面还没装。这一步才是 root 闭环。

## 关键结论先讲

> 🔴 **Magisk 必须装成普通应用，塞进 `system/app` 会导致 root 完全失效。**
> 实测两次都失败：授权弹窗不出现、「超级用户」页面灰色。

原因：Magisk 的授权机制依赖 `/data/adb` 下的运行时状态和 zygote 注入时序，作为 system 预装应用启动路径不对，守护进程起不来。

## 操作步骤

### 1. adb install 装成普通应用

此时 adb 已解封（见 [06](06-解封adb.md)），可以直接装：

```bash
adb install -r Magisk-v25.2.apk
```

> 阿里阉割了「安装未知来源应用」的 UI 入口，但**系统级 `adb install` 不受这个限制**。这也是必须先解封 adb 的原因。

### 2. 首次打开，按提示「修复运行环境」

打开 Magisk，会提示：

```
需要修复运行环境
```

点确定 → 选择 **「直接安装（推荐）」**

### 3. 等待自动重启

Magisk 会自己完成 boot 修补链路的收尾并重启设备。**重启后不要慌，第一次会比较慢。**

### 4. 验证 root

重启后：

```bash
adb shell su -c id
```

如果返回：

```
uid=0(root) gid=0(root) groups=0(root)
```

说明 Magisk daemon 正常。

如果返回 `Permission denied`，**大概率不是失败**，而是 Magisk 默认不给 adb 授权：

### 5. 打开 ADB 的超级用户权限（必须手动做）

在设备上操作：

1. 打开 **Magisk** → 右上角 **齿轮（设置）**
2. 找到 **「超级用户访问权限」**（Superuser Access）
3. 从「仅应用程序」改成 **「应用程序和 ADB」**
4. 顺便把「超级用户请求超时时间」调长一点（如 30 秒）

改完再跑一次 `adb shell su -c id` —— 设备上可能会弹授权框，点**允许**即可。

> 这一步是很多人卡住的地方：以为 root 没成功，其实是 Magisk 的默认策略不给 adb。

### 6. 用权限狗验证 root 链路

打开 **权限狗** → 切到 root 模式 → 会弹 Magisk 授权 → **允许** → 能正常读取权限列表即闭环成功。

## 失败排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 提示需要修复环境但点不动 | Magisk 装在 system 里 | 重刷不回 Magisk 的 system，改用 adb install |
| `su` 一直 Permission denied | 超级用户访问权限只给了「应用程序」 | 按上面第 5 步改设置 |
| 授权弹窗从不出现 | Magisk daemon 未运行 | 检查 `ps \| grep magisk`；必要时「修复运行环境」重做 |
| 开机后 Magisk 图标消失 | `/data` 被清 | root 还在（boot 分区），重装 APK 即可 |

## root 之后能做什么

- 冻结 / 卸载预装（见 [08](08-系统优化-冻结预装.md)）
- 读写 `/data`、`/system`
- 直接修 `/data/system` 下的框架状态文件（见 [09](09-开机循环救援.md)）
- 装 Magisk 模块（开机脚本，例如自动拉起第三方桌面）

---

下一步 → [08 · 系统优化：冻结预装](08-系统优化-冻结预装.md)
