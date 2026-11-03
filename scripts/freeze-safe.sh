#!/bin/bash
# freeze-safe.sh
# 分批冻结预装包，每批重启并校验开机状态；任一批失败立即停止（避免连坐）。
#
# 设计原则（血泪教训）：
#   1. 冻结前逐个复查 HOME 声明，命中即跳过（防止手滑把桌面候选冻了 → 开机无限崩溃）
#   2. 每批做完立刻重启，校验 sys.boot_completed == 1 才继续下一批
#   3. 只信 package-restrictions.xml 里的 suspended 计数，不信 cmd 的回显
#
# 用法：
#   1. 先跑 check-home-packages.sh 确认候选包
#   2. 编辑下面的 BATCHES（格式："批次名|包1 包2 包3"）
#   3. bash freeze-safe.sh
#
# 出事救援：见 fix-suspend-bootloop.sh

set -u

ADB="${ADB:-adb}"
SERIAL="${SERIAL:-}"
ADB_TARGET=""
[ -n "$SERIAL" ] && ADB_TARGET="-s $SERIAL"

BOOT_TIMEOUT=180      # 每批重启后等待开机的秒数上限
POLL_INTERVAL=6

# ============ 需要你按实际情况编辑这里 ============
# 以下为天猫精灵 CC7（TG_S2B / alibaba Android 8.1）实测安全的 21 个包，
# 换设备/换固件必须重新跑 check-home-packages.sh 后再改这里。
BATCHES=(
  "批次1 视频音频|com.youku.iot com.ailabs.youku.iot com.youkuchild.android com.qiyi.video.speaker com.tencent.qqlive.audiobox"
  "批次2 阿里辅助|com.alibaba.ailabs.genie.browser com.alibaba.ailabs.genie.aicare com.alibaba.ailabs.genie.albums com.alibaba.ailabs.genie.infoplanet com.alibaba.ailabs.genie.guide com.alibaba.ailabs.genie.screensaver"
  "批次3 杂项工具|com.alibaba.ailabs.game.center com.alibaba.genie.widget.gallery com.alibaba.ailabs.ar.monitor com.aliyun.iotx.linkvisual com.alira.info com.aliyun.uuid com.ailabs.emode com.mediatek.mtklogger com.aligenie.networktestsdk com.alibaba.genie.aihuman"
)
# ==================================================

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

has_home() {
  local p="$1"
  local n
  n=$($ADB $ADB_TARGET shell "dumpsys package $p 2>/dev/null | grep -c 'android.intent.category.HOME'" 2>/dev/null | tr -d '\r\n')
  n=${n:-0}
  [ "$n" -gt 0 ] 2>/dev/null
}

wait_boot() {
  local i
  for i in $(seq 1 $((BOOT_TIMEOUT / POLL_INTERVAL))); do
    local bc
    bc=$($ADB $ADB_TARGET shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
    if [ "$bc" = "1" ]; then
      return 0
    fi
    sleep $POLL_INTERVAL
  done
  return 1
}

suspended_count() {
  $ADB $ADB_TARGET shell "su -c 'grep -c \"suspended=\\\"true\\\"\" /data/system/users/0/package-restrictions.xml'" 2>/dev/null | tr -d '\r\n' | tail -1
}

echo "=========== 冻结前基线 ==========="
echo "已挂起: $(suspended_count) 个"
$ADB $ADB_TARGET shell getprop sys.boot_completed | tr -d '\r'

FAILED=0
for entry in "${BATCHES[@]}"; do
  NAME="${entry%%|*}"
  PKGS="${entry#*|}"
  echo
  echo "==================== $NAME ===================="

  for p in $PKGS; do
    if has_home "$p"; then
      red "  [跳过-禁区] $p 声明了 HOME，冻结会导致开机循环"
      continue
    fi
    R=$($ADB $ADB_TARGET shell "su -c 'cmd package suspend $p'" 2>/dev/null | tr -d '\r' | tail -1)
    case "$R" in
      *"state: true"*) green "  [已冻结] $p" ;;
      "")              red   "  [失败-无响应] $p" ;;
      *)               yellow "  [重试中] $p -> $R"
                       sleep 2
                       R=$($ADB $ADB_TARGET shell "su -c 'cmd package suspend $p'" 2>/dev/null | tr -d '\r' | tail -1)
                       case "$R" in
                         *"state: true"*) green "  [已冻结] $p" ;;
                         *)               red   "  [失败] $p -> $R" ;;
                       esac
                       ;;
    esac
  done

  echo "--- 重启验证 ---"
  $ADB $ADB_TARGET shell "su -c reboot" >/dev/null 2>&1
  sleep 20
  if wait_boot; then
    green "  ✅ $NAME 开机正常 (boot_completed=1)"
  else
    red "  ❌ $NAME 开机失败！已停止后续批次"
    red "     → 立即执行 fix-suspend-bootloop.sh 回滚"
    FAILED=1
    break
  fi
done

echo
echo "=========== 结果 ==========="
echo "已挂起: $(suspended_count) 个"
if [ "$FAILED" -eq 1 ]; then
  red "有批次失败，请执行回滚脚本"
  exit 1
fi
green "全部批次完成"
