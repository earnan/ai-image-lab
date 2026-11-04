#!/bin/bash
# Draw Things CLI 启动器（L1 层，苹果原生 Metal）
# 用法：直接跑用默认参数；或用环境变量覆盖：
#   DT_MODEL / DT_PROMPT / DT_STEPS / DT_W / DT_H / DT_SEED / DT_NAME / DT_IMAGE / DT_STRENGTH
# 例：DT_PROMPT="a red teapot" DT_STEPS=4 ./start-drawthings.sh
set -euo pipefail
source "$(dirname "$0")/../PATHS.env"

CLI="$AIIL_APP_DT/draw-things-cli"
[ -x "$CLI" ] || { echo "[SKIP] draw-things-cli 不可用: $CLI（WIN11 卷挂载了吗？）" >&2; exit 0; }
[ -d "$AIIL_W_DRAWTHINGS" ] || { echo "[SKIP] 模型目录缺失: $AIIL_W_DRAWTHINGS" >&2; exit 0; }
mkdir -p "$AIIL_OUT_DT"

MODEL="${DT_MODEL:-flux_2_klein_4b_q6p.ckpt}"
PROMPT="${DT_PROMPT:-a red ceramic teapot on wooden table, soft daylight}"
STEPS="${DT_STEPS:-4}"
W="${DT_W:-512}"; H="${DT_H:-512}"
NAME="${DT_NAME:-dt_$(date +%Y%m%d_%H%M%S).png}"

ARGS=(generate --model "$MODEL" --prompt "$PROMPT"
      --models-dir "$AIIL_W_DRAWTHINGS"
      --width "$W" --height "$H" --steps "$STEPS"
      --output "$AIIL_OUT_DT/$NAME")
[ -n "${DT_SEED:-}" ] && ARGS+=(--seed "$DT_SEED")
[ -n "${DT_IMAGE:-}" ] && ARGS+=(--image "$DT_IMAGE" --strength "${DT_STRENGTH:-0.5}")

echo "[INFO] L1 出图 model=$MODEL  ${W}x${H}  steps=$STEPS"
echo "[INFO] 输出 $AIIL_OUT_DT/$NAME"
cd "$AIIL_APP_DT"
exec "$CLI" "${ARGS[@]}"
