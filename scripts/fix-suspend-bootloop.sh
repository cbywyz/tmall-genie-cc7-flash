#!/system/bin/sh
# fix-suspend-bootloop.sh
# 用途：设备卡在开机 logo（system_server 因 HOME 候选包被挂起而无限崩溃）时，
#      从 root shell 清除全部 package suspension 标记，无损修复。
#
# 为什么能修：
#   adbd 与 Magisk 的 root 在 system_server 启动之前就已就绪。
#   所以即使框架层死循环，仍可进入 root shell 直接改 /data。
#   不需要 recovery、不需要 BROM、不需要恢复出厂。
#
# 用法 A（推荐，直接由电脑执行）：
#   adb shell su -c 'sh /data/local/tmp/fix-suspend-bootloop.sh'
#
# 用法 B（无脚本时手工执行同理的 5 步）：
#   stop zygote
#   cp /data/system/users/0/package-restrictions.xml /data/local/tmp/pr.orig.xml
#   sed 's/ suspended="true"//g' /data/local/tmp/pr.orig.xml > /data/local/tmp/pr.fixed.xml
#   cat /data/local/tmp/pr.fixed.xml > /data/system/users/0/package-restrictions.xml
#   sync; reboot
#
# 关键：用 cat 原地覆盖，保留 inode / 属主 / SELinux 上下文。
#       用 mv / sed -i / adb push 新建文件会破坏属性，system_server 读不了。

PR=/data/system/users/0/package-restrictions.xml
TS=$(date +%Y%m%d-%H%M%S)
LOG=/data/local/tmp/fix-suspend-$TS.log

exec > $LOG 2>&1
echo "===== fix-suspend start $(date) ====="

# 0. 前置检查
if [ ! -f "$PR" ]; then
  echo "FATAL: $PR 不存在，本脚本不适用"
  exit 1
fi

BEFORE=$(grep -o 'suspended="true"' "$PR" | wc -l)
echo "修复前 suspended 标记数: $BEFORE"

if [ "$BEFORE" -eq 0 ]; then
  echo "没有 suspended 标记，问题不在这里。请检查 dropbox 里的崩溃堆栈："
  ls -t /data/system/dropbox/ 2>/dev/null | head -5
  exit 2
fi

# 1. 停框架，防止 system_server 重启时用内存态覆盖修改
stop zygote
sleep 1

# 2. 备份
cp -f "$PR" /data/local/tmp/pr.orig.xml
echo "已备份到 /data/local/tmp/pr.orig.xml ($(wc -c < /data/local/tmp/pr.orig.xml) 字节)"

# 3. 生成清理版
sed 's/ suspended="true"//g' /data/local/tmp/pr.orig.xml > /data/local/tmp/pr.fixed.xml

# 4. 原地写回（保留 inode / 属主 / 上下文）
cat /data/local/tmp/pr.fixed.xml > "$PR"

# 5. 校验
AFTER=$(grep -o 'suspended="true"' "$PR" | wc -l)
echo "修复后 suspended 标记数: $AFTER"
ls -l "$PR"

if [ "$AFTER" -ne 0 ]; then
  echo "FATAL: 清理后仍有标记，中止（未重启）。可从 /data/local/tmp/pr.orig.xml 恢复"
  exit 3
fi

sync
echo "===== 修复完成，即将重启 ====="
echo "日志: $LOG"
echo "如需手动重启请执行 reboot"
reboot
