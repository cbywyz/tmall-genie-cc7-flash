# 02 · 解锁 BootLoader

CC7 的 BootLoader 状态记录在 `seccfg` 分区。MTK 平台解锁不需要官方账号，直接改写 `seccfg` 即可。

## 为什么必须解锁

- 未解锁时，写入未经厂商签名的 `boot`（Magisk 补丁版）会被 BL 拒绝，或者开机进入 fastboot / 黑屏
- 未解锁时，`system` 分区校验可能失败

## 操作

用 **MTKClient** 的解锁功能写 `seccfg`：

- GUI 版：`MTKClientV2.0.exe` → `Unlock Bootloader`
- CLI 版：`mtkclient` 的 `unlock` 相关命令

> ⚠️ 不同版本的 MTKClient 按钮/命令名略有差异，按你手上版本的「Unlock / Lock Bootloader」选项操作即可，不用记死命令。

## 判断是否成功

解锁后重新进 brom，读 `seccfg` 应显示为 **unlocked** 状态。部分 MTKClient 版本会直接打印：

```
Bootloader is unlocked
```

## 顺序问题：先解锁还是先备份？

两种做法都有人用：

| 顺序 | 优点 | 缺点 |
|---|---|---|
| **先解锁再备份** | 流程顺畅，解锁后读写的分区状态一致 | 解锁动作本身有极小概率失败 |
| **先备份再解锁** | 更保守，出问题至少有原始镜像 | 解锁前的 `seccfg` 状态与解锁后不同，`seccfg` 需单独再备份一次 |

本仓库实践采用**先解锁、再全量备份**，并在备份中单独保留 `seccfg.bin`，这样以后可以随时回到「已解锁」或「未解锁」任一状态。

---

下一步 → [03 · 全量分区备份](03-分区备份.md)
