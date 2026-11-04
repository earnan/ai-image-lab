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
echo "--- 软链入口 ---"
for x in sd-webui comfyui draw-things; do
  t="$AIIL_ROOT/apps/$x"
  if [ -L "$t" ] && [ -e "$t" ]; then echo "✅ apps/$x -> $(readlink "$t")"
  else echo "❌ apps/$x 失效"; fail=$((fail+1)); fi
done
for m in legacy-sd15 diffusion_models text_encoders unet vae; do
  t="$AIIL_ROOT/models/$m"
  if [ -L "$t" ] && [ -e "$t" ]; then echo "✅ models/$m -> $(readlink "$t")"
  else echo "❌ models/$m 失效"; fail=$((fail+1)); fi
done

echo
if [ "$fail" -eq 0 ]; then echo "✅ 全部有效（0 处悬空）"; exit 0
else echo "⚠️  $fail 处失效，检查卷是否挂载"; exit 1; fi
