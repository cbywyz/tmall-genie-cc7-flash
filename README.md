# 天猫精灵 CC7（TG_S2B）刷机全流程

> 一台阿里云 OS 定制音箱盒子，从「进不了 brom」到「拿到 root + 换第三方桌面 + 预装精简」的完整实战记录。
> 全程真实操作，含两次翻车与排障过程，所有结论都有设备侧证据（日志 / dumpsys / 崩溃堆栈）。

[![Device](https://img.shields.io/badge/Device-天猫精灵%20CC7%20(TG_S2B)-blue)]()
[![SoC](https://img.shields.io/badge/SoC-MT8167-orange)]()
[![Android](https://img.shields.io/badge/Android-8.1-green)]()
[![Root](https://img.shields.io/badge/Root-Magisk%20v25.2-red)]()

---

## 这套流程解决了什么

| 问题 | 官方途径 | 本仓库做法 |
|---|---|---|
| 装第三方 APK | 无「未知来源」入口 | 直接把 APK 塞进 `system/app` |
| 调试设备 | 开发者选项只有 WAFT，`adbd` 协议层阉割 | 改 `build.prop` + `prop.default` 解封 adb shell |
| 拿 root | 无 | Magisk 修补 boot 分区 |
| 干掉卡顿预装 | 无 | `cmd package suspend` 冻结 + HOME 候选白名单 |
| 刷坏了 | 无 | Magisk root shell 直接修 `/data`，不用 recovery / BROM |

---

## 目录

### 准备

- [00 · 设备信息与工具清单](docs/00-设备与工具.md)

### 主流程

| # | 步骤 | 关键点 |
|---|---|---|
| 1 | [进入 BROM 模式](docs/01-进入BROM模式.md) | 四键 + 两声提示音；Zadig 装 WinUSB 根治重连卡死 |
| 2 | [解锁 BootLoader](docs/02-解锁BootLoader.md) | MTKClient 写 `seccfg` |
| 3 | [全量分区备份](docs/03-分区备份.md) | 17 个分区，**唯一的救砖后悔药** |
| 4 | [注入 APK 到 system](docs/04-注入APK到system.md) | CRBuilder 解包 → `system/app/` 平铺 → 重打包 |
| 5 | [Magisk 修补 boot](docs/05-Magisk修补boot.md) | 架构必须选 **arm**，选错即砖 |
| 6 | [解封 adb](docs/06-解封adb.md) | 三轮刷机才搞定，阿里的 `persist.sys.adb.enabled` 是关键 |
| 7 | [安装 Magisk 拿到 root](docs/07-安装Magisk获取root.md) | 必须装成**普通应用**，塞 system 里 root 必坏 |

### 优化与自救

- [08 · 系统优化：冻结预装](docs/08-系统优化-冻结预装.md) — 实测 CPU 空闲 50% → 77%
- [09 · 开机循环救援（重点）](docs/09-开机循环救援.md) — system_server 崩溃循环时怎么救
- [10 · 踩坑合集](docs/10-踩坑合集.md)

### 实战记录（原始报告）

- [开机循环事故复盘](reports/开机循环事故复盘.md) — 完整崩溃堆栈、8 分钟无损修复过程
- [优化最终状态](reports/优化最终状态.md) — 优化清单、实测数据、三档回滚手册

### 脚本

- [`scripts/check-home-packages.sh`](scripts/check-home-packages.sh) — 冻结前必跑：扫描哪些包是 HOME 候选
- [`scripts/freeze-safe.sh`](scripts/freeze-safe.sh) — 分批冻结 + 每批重启验证
- [`scripts/fix-suspend-bootloop.sh`](scripts/fix-suspend-bootloop.sh) — 开机循环救援
- [`scripts/99-dangbei-home.sh`](scripts/99-dangbei-home.sh) — 开机自动拉起第三方桌面

---

## 一句话总结每一条教训

1. **备份没做完，不许写任何分区。**
2. **Magisk 塞进 `system/app` = root 必坏**，必须当普通应用装。
3. **冻结预装前必须查 `android.intent.category.HOME`**，冻到桌面候选就是开机无限重启。
4. **改 `/data/system` 下的文件用 `cat` 原地覆盖**，`mv`/重新 push 会破坏属主与 SELinux 上下文。
5. **`system_server` 崩了不等于砖** —— 这台设备的 adbd + Magisk root 在框架之前就绪，永远有救。

---

## 备份存档位置（救砖时来这里找）

本流程对应设备的 17 个分区备份，**长期存档只在私有云盘**。本机那份是归档时的中转目录，校验通过后即可删除，不作为存放点。

| 位置 | 路径 | 性质 |
|---|---|---|
| 私有云盘 | `/AI空间/第三方智能体/<专属目录名>/天猫精灵CC7分区备份-20261103` | **唯一长期存档**，2026-11-03 上传归档 |
| 本机（临时） | `D:\...\Desktop\tmjl\backup\` | MTKClient 备份落盘 + 上传中转，归档已校验，可随时删除 |

归档校验（实际执行结果，非估算）：

| 项目 | 结果 |
|---|---|
| 文件数 | 17 / 17 |
| 总字节 | 1,533,542,400（1.43 GB） |
| 逐项比对 | 无缺失、无多余、无大小不符 |

> `<专属目录名>` 是移动云盘账号下由第三方智能体创建的目录名，因人而异，这里做占位处理。该目录位于**私有空间**，需对应账号授权才能访问。本仓库只记录归档位置，不含任何凭据、账号、文件名或固件二进制。

**找回方式**：云盘 App / 网页端直接下载对应 `.bin`，或按 [03 · 全量分区备份](docs/03-分区备份.md) 的「恢复方式」章节回写。若只需救一个分区（如 `boot` 刷坏），只下载那一个文件即可，不必整盘回滚。

> **删本地之前请确认**：云盘那份已通过逐项字节比对（见上表）。云盘是账号内的在线存储，账号异常、误删、限流都可能拿不到文件 —— 手头若还有 U 盘 / 移动硬盘，建议再留一份离线副本，容量只要 1.4 GB。

### 刷机工具与 APK 存档（不进本仓库）

按上面流程要用的工具和 APK，同样归档在私有云盘的另一个目录，**本仓库不收录二进制**（版权与分发风险）：

| 类型 | 文件 | 字节 |
|---|---|---:|
| 桌面 | `dangbei.apk`（当贝桌面） | 9,201,063 |
| 工具 | `easytouch.apk`（悬浮球） | 4,595,133 |
| 工具 | `ES.apk`（ES 文件管理器） | 4,826,567 |
| root | `magisk.apk` | 11,278,270 |
| 工具 | `qxg.apk`（权限狗） | 1,438,313 |
| 桌面 | `aerial-standard.apk` | 3,138,037 |
| 桌面 | `aerial-guard.apk`（带桌面守护） | 3,137,955 |
| 打包 | `crb_v221b.zip`（CRBuilder） | 82,418,933 |
| 驱动 | `zadig.exe`（USB 驱动） | 5,334,088 |

- 云端路径：`/AI空间/第三方智能体/<专属目录名>/CC7刷机工具与APK-20261103`
- 合计 9 个文件 / 125,368,359 字节，已逐项字节比对（无缺失、无多余、无大小不符）
- 只有两个 Aerial 版本可用：[Aerial](https://github.com/pengchujin/aerial-tv) 是开源项目，请从官方 Release 下载；其余 APK 的版本号未见得一致，**照抄文件名不等于照抄版本**，优先用自己确认过的来源

---

## 风险声明

- 这是**非官方破解流程**，会失去保修，存在变砖可能。
- 唯一救援依赖第 3 步的分区备份，**请务必另存一份到离线介质**。
- 不同批次/固件版本的 CC7 可能存在差异，操作前先确认自己的 `Build` 指纹（见 [00 · 设备信息](docs/00-设备与工具.md)）。
- 仓库不含任何第三方 APK / 固件二进制，避免版权与分发问题。

---

## 设备指纹（用于比对）

```
alps/full_ailabs_s1l_8b/ailabs_s1l_8b:6.1.8-RS-20240326.2006/O11019/1711454715:user/test-keys
```

若你的设备 `Build` 与此一致，本仓库流程可直接参考。

---

## License

文档采用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.zh)，脚本采用 [MIT](LICENSE)。
