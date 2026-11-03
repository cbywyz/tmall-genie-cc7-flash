#!/system/bin/sh
# 99-dangbei-home.sh
# 用途：开机后把第三方桌面拉到前台，绕开厂商系统强行拉起的原生桌面（可能卡死并吞掉触摸）。
#
# ⚠️ 本流程最终没有采用这个脚本（2026-11-03 实测结论）：
#    原桌面卡死只是 dexopt 期间的暂时现象，为它长期养一个第三方桌面不划算 ——
#    第三方桌面会自启约 130MB 的后台进程，还会把语音/儿童模式/IoT 入口盖住。
#    取舍详见 docs/08-系统优化-冻结预装.md。下面保留安装方法，供确实需要的人取用。
#
# 安装：
#   adb push 99-dangbei-home.sh /data/local/tmp/
#   adb shell su -c 'cp /data/local/tmp/99-dangbei-home.sh /data/adb/service.d/'
#   adb shell su -c 'chmod 755 /data/adb/service.d/99-dangbei-home.sh'
#
# 撤销：删除该文件即可，无需其它操作
#   adb shell su -c 'rm /data/adb/service.d/99-dangbei-home.sh'
#
# 说明：Magisk 的 service.d 脚本在系统启动过程中以 root 执行，
#       所以这里先等 sys.boot_completed，再等桌面进程就绪，然后 start。
#       sleep 秒数按设备启动速度调整（慢设备可加大）。

TARGET="com.dangbei1.tvlauncher/com.dangbei.launcher.ui.main.MainActivity"

# 1. 等系统启动完成
i=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 3
  i=$((i + 1))
  [ "$i" -gt 200 ] && exit 1     # 最多等 10 分钟，超时放弃
done

# 2. 留出时间让原生桌面先完成它自己的启动流程，避免互相抢焦点
sleep 12

# 3. 拉起目标桌面
am start -n "$TARGET" >/dev/null 2>&1

# 4. 12 秒后再确认一次（原生桌面可能又抢回前台）
sleep 12
CUR=$(dumpsys window 2>/dev/null | grep mCurrentFocus | head -1)
case "$CUR" in
  *dangbei*) : ;;                                  # 已在目标桌面
  *) am start -n "$TARGET" >/dev/null 2>&1 ;;       # 再拉一次
esac
