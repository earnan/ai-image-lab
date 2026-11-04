#!/bin/bash
# ComfyUI 启动器（L2 层）
# 路径全部来自 ../PATHS.env，本文件不含任何 /Volumes 字面量。
# 卷缺失时打印 [SKIP] 并退出 0（区分「跳过」与「故障」，见 MAP.md §七）。
set -euo pipefail
source "$(dirname "$0")/../PATHS.env"

for p in "$AIIL_VOL_SSD" "$AIIL_APP_COMFY"; do
  [ -d "$p" ] || { echo "[SKIP] 未挂载或不存在: $p" >&2; exit 0; }
done
[ -d "$AIIL_WEIGHTS" ] || { echo "[SKIP] 权重仓缺失: $AIIL_WEIGHTS" >&2; exit 0; }

PORT="${AIIL_PORT_COMFY:-8188}"
mkdir -p "$AIIL_OUT_COMFY"

if curl -sf "http://127.0.0.1:${PORT}/" -o /dev/null 2>/dev/null; then
  echo "[INFO] ComfyUI 已在 127.0.0.1:${PORT} 运行，直接打开"
  open "http://127.0.0.1:${PORT}" 2>/dev/null || true
  exit 0
fi

cd "$AIIL_APP_COMFY"
[ -x .venv/bin/python ] || { echo "[FAIL] venv 缺失: $AIIL_APP_COMFY/.venv" >&2; exit 1; }

echo "[INFO] 启动 ComfyUI  port=$PORT  out=$AIIL_OUT_COMFY"
echo "[INFO] 浏览器打开 http://127.0.0.1:${PORT}（Ctrl+C 停止）"
exec .venv/bin/python main.py \
  --listen 127.0.0.1 \
  --port "$PORT" \
  --output-directory "$AIIL_OUT_COMFY"
