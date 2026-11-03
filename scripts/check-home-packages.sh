#!/bin/bash
# check-home-packages.sh
# 冻结/禁用系统包之前的强制体检：扫描哪些包声明了 android.intent.category.HOME
#
# 用法：
#   bash check-home-packages.sh com.foo com.bar ...
#   bash check-home-packages.sh            # 不带参数 = 扫描所有已安装包（较慢）
#
# 判据来源：ActivityManagerService.startHomeActivityLocked() 在 HOME 候选包被挂起时
#          会因 ComponentInfo.applicationInfo == null 抛 NPE，导致 system_server 无限崩溃。
#          → 返回 >0 的包，绝对禁止 suspend/disable。

set -u

ADB="${ADB:-adb}"
SERIAL="${SERIAL:-}"
ADB_TARGET=""
if [ -n "$SERIAL" ]; then
  ADB_TARGET="-s $SERIAL"
fi

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

# 取包列表
if [ "$#" -gt 0 ]; then
  PKGS="$*"
else
  echo "未指定包名，扫描全部已安装包（可能较慢）..."
  PKGS=$($ADB $ADB_TARGET shell pm list packages 2>/dev/null | sed 's/^package://' | tr -d '\r')
fi

FORBIDDEN=""
TOTAL=0
SAFE=0

for p in $PKGS; do
  [ -z "$p" ] && continue
  TOTAL=$((TOTAL + 1))
  N=$($ADB $ADB_TARGET shell "dumpsys package $p 2>/dev/null | grep -c 'android.intent.category.HOME'" 2>/dev/null | tr -d '\r\n')
  N=${N:-0}
  if [ "$N" -gt 0 ] 2>/dev/null; then
    red "⛔ 禁区   $p   (HOME 命中 $N)"
    FORBIDDEN="$FORBIDDEN $p"
  else
    green "✅ 可冻   $p"
    SAFE=$((SAFE + 1))
  fi
done

echo
echo "==================== 汇总 ===================="
echo "共检查 : $TOTAL"
echo "可冻结 : $SAFE"
echo -n "禁  区 : "
if [ -n "$FORBIDDEN" ]; then
  red "$(echo $FORBIDDEN | wc -w) 个"
  for p in $FORBIDDEN; do echo "    - $p"; done
else
  echo "0 个"
fi
