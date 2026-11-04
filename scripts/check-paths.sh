#!/bin/sh
# check-paths.sh — 校验 PATHS.env 里每条路径是否真实存在
# 用途：拔盘后/重启后/改结构后，一条命令确认整套系统没有悬空引用。
# 退出码：0 全部有效，1 存在失效路径

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SELF_DIR/../PATHS.env" || { echo "❌ 找不到 PATHS.env"; exit 2; }

fail=0
printf '%-28s %-8s %s\n' "变量" "状态" "路径"
printf '%s\n' "--------------------------------------------------------------------"

check() {
  name="$1"; path="$2"; kind="${3:-d}"
  if [ "$kind" = "l" ]; then
    [ -L "$path" ] || [ -e "$path" ]
  else
    [ -d "$path" ]
  fi
  if [ $? -eq 0 ]; then
    printf '%-28s %-8s %s\n' "$name" "✅" "$path"
  else
    printf '%-28s %-8s %s\n' "$name" "❌缺失" "$path"
    fail=$((fail+1))
  fi
}

check AIIL_ROOT           "$AIIL_ROOT"
check AIIL_OUTPUTS        "$AIIL_OUTPUTS"
check AIIL_OUT_COMFY      "$AIIL_OUT_COMFY"
check AIIL_OUT_DT         "$AIIL_OUT_DT"
check AIIL_OUT_SD         "$AIIL_OUT_SD"
check AIIL_WEIGHTS        "$AIIL_WEIGHTS"
check AIIL_W_LEGACY_SD15  "$AIIL_W_LEGACY_SD15"
check AIIL_W_DRAWTHINGS   "$AIIL_W_DRAWTHINGS"
check AIIL_APP_SDWEBUI    "$AIIL_APP_SDWEBUI"
check AIIL_APP_COMFY      "$AIIL_APP_COMFY"
check AIIL_APP_DT         "$AIIL_APP_DT"
check AIIL_BACKUP_MODELS  "$AIIL_BACKUP_MODELS"

echo
echo "--- 软链入口（AIIL_LINK_MAP 全量）---"
for entry in "${AIIL_LINK_MAP[@]}"; do
  link=${entry%%|*}; t="$AIIL_ROOT/$link"
  if [ -L "$t" ] && [ -e "$t" ]; then
    echo "✅ $link -> $(readlink "$t")"
  else
    cur=$(readlink "$t" 2>/dev/null)
    echo "❌ $link 失效（当前指向: ${cur:-未建链} → 应为 ${entry#*|}）"; fail=$((fail+1))
  fi
done

echo
if [ "$fail" -eq 0 ]; then echo "✅ 全部有效（0 处悬空）"; exit 0
else echo "⚠️  $fail 处失效，检查卷是否挂载"; exit 1; fi
