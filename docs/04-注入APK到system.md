# 04 · 注入 APK 到 system 分区

## 为什么塞 system 而不是直接安装

阿里的系统**阉割了「安装未知来源应用」入口**，`adb install` 在 adb 解封前也用不了。把 APK 放进 `system/app/` 是绕过这个限制最直接的办法 —— 系统开机自动扫描并安装。

## 操作流程（CRBuilder v2.21b）

1. 把 `backup/system.bin` 复制一份到工作目录（**别直接改备份原件**）
2. 打开 **CRBuilder**，选择「解包 system.img」
3. 解包完成后，把 APK **平铺**放进 `system/app/` 目录：

```
system/app/
├── dangbei.apk          # 当贝桌面
├── easytouch.apk        # 悬浮球
├── es.apk               # ES 文件管理器
└── qxg.apk              # 权限狗
```

> 注意是**平铺放 `system/app/` 下**，不是每个 APK 一个子目录。CC7 的系统能识别这种布局。

4. 打包回 `system.img`

### 关键参数

| 项 | 值 | 说明 |
|---|---|---|
| 镜像大小 | **保持默认 1.34 GB** | ⚠️ 改成别的值会导致开机进 fastboot |
| 打包输出 | `Projects/CRB_PROJECT/Output/system.img` | 产物路径 |

## 一个踩过的坑：Magisk 不要塞 system

我们最初把 Magisk 也塞进 `system/app`，**实测两次都失败**：

- Magisk 能启动，但**授权弹窗不出现**
- 「超级用户」页面灰色不可用
- 结果：装了个假的 Magisk，root 拿不到

**正确做法**：Magisk 只注入 `boot` 分区（见 [05](05-Magisk修补boot.md)），APK 等 adb 解封后用 `adb install` 装成**普通应用**（见 [07](07-安装Magisk获取root.md)）。

最终注入 system 的是 **4 个 APK**：当贝桌面 / 悬浮球 / ES / 权限狗。

## 写回 system

```
MTKClient → Write Partition → system → 选择新打包的 system.img
```

- 1.34 GB 写入需要几分钟，**中途绝对不能断线断电**
- 写完后**先别写 boot**，分开验证更安全（见 [05](05-Magisk修补boot.md) 末尾）

## 验证注入是否成功

开机后通过 adb 检查：

```bash
adb shell ls /system/app/
adb shell pm list packages | grep -E "dangbei|easytouch|estrongs"
```

能看到对应包名 = 注入成功。

---

下一步 → [05 · Magisk 修补 boot](05-Magisk修补boot.md)
