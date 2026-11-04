#!/bin/bash
# sync-models.sh — 权重单向同步：HDD 只读备份仓 → WIN11 SSD 运行副本
# 设计原则：
#   1. 方向恒定单向：备份 → 运行副本。绝不反向，避免把 SSD 上的临时试验权重污染备份。
#   2. 只增不删不覆盖（--ignore-existing）：脚本永远不做销毁性动作，可以随时安全重跑。
#   3. 备份仓是事实基准（32 个文件，含 chilloutmix_NiPrunedFp32Fix.safetensors）。
# 用法：
#   ./sync-models.sh              # 执行同步
#   ./sync-models.sh --dry-run    # 只看会补齐什么，不落盘
#   ./sync-models.sh --check      # 只比对差异，退出码 0=一致 1=有缺口

set -uo pipefail

# 路径真相源统一走 PATHS.env（2026-11-04 修：原先硬编码 RUNTIME 指向已改名的
# 旧路径 热数据/sd-webui-models，改名后本脚本 --check 直接 exit 3 失效）
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SELF_DIR/../PATHS.env" || { echo "❌ 找不到 PATHS.env"; exit 2; }

BACKUP="$AIIL_BACKUP_MODELS"
RUNTIME="$AIIL_W_LEGACY_SD15"
LOG_DIR="$AIIL_OUTPUTS"
LOG="$LOG_DIR/sync-models.log"

MODE="sync"
case "${1:-}" in
  --dry-run) MODE="dry" ;;
  --check)   MODE="check" ;;
  "")        ;;
  *) echo "未知参数：$1（可用：--dry-run / --check）" >&2; exit 2 ;;
esac

# ---- 前置：两侧卷必须都在 ----
for p in "$BACKUP" "$RUNTIME"; do
  if [ ! -d "$p" ]; then
    echo "❌ 路径不可用：$p" >&2
    echo "   请确认 HDD / WIN11 两个卷都已挂载。" >&2
    exit 3
  fi
done

count_backup=$(find "$BACKUP" -type f ! -name '.DS_Store' | wc -l | tr -d ' ')
count_runtime=$(find "$RUNTIME" -type f ! -name '.DS_Store' | wc -l | tr -d ' ')

echo "备份仓（基准）：$BACKUP  →  $count_backup 个文件"
echo "运行副本：      $RUNTIME  →  $count_runtime 个文件"
echo

if [ "$MODE" = "check" ]; then
  diff=$(rsync -rcn --delete --out-format='%i %n' \
          --exclude='.DS_Store' --exclude='README-*.md' \
          "$BACKUP/" "$RUNTIME/" 2>/dev/null)
  if [ -z "$diff" ]; then
    echo "✅ 一致，无缺口。"
    exit 0
  fi
  echo "⚠️  存在差异（*deleting 表示运行副本有备份仓里没有的文件，属正常，不会被脚本删除）："
  echo "$diff"
  exit 1
fi

# ---- 同步：只增不删不覆盖 ----
RSYNC_ARGS=(
  -a                  # 保留权限/时间戳
  --ignore-existing   # 关键：运行副本已有的文件一律不动
  --exclude='.DS_Store'
  --exclude='README-*.md'
  --itemize-changes
)

if [ "$MODE" = "dry" ]; then
  echo "🔍 DRY-RUN（不落盘）："
  rsync "${RSYNC_ARGS[@]}" --dry-run "$BACKUP/" "$RUNTIME/"
  echo
  echo "以上为待补齐清单。去掉 --dry-run 即可执行。"
  exit 0
fi

mkdir -p "$LOG_DIR"
{
  echo "===== $(date '+%Y-%m-%d %H:%M:%S') sync start ====="
  rsync "${RSYNC_ARGS[@]}" "$BACKUP/" "$RUNTIME/"
  echo "===== $(date '+%Y-%m-%d %H:%M:%S') sync end ====="
} 2>&1 | tee -a "$LOG"

count_after=$(find "$RUNTIME" -type f ! -name '.DS_Store' | wc -l | tr -d ' ')
echo
echo "完成。运行副本：$count_runtime → $count_after 个文件"
echo "日志：$LOG"
