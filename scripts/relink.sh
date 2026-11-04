#!/bin/sh
# relink.sh — 按 PATHS.env 的 AIIL_LINK_MAP 批量重建 apps/ 与 models/ 下的 16 条软链
# 用途：换机 clone 后、卷名变更后、软链被误删后，一条命令恢复全部索引入口。
# 用法：
#   scripts/relink.sh             重建缺失或指向错误的软链；已正确则跳过（幂等）
#   scripts/relink.sh --check     只检查，不改动任何文件
#   scripts/relink.sh --dry-run   打印将要执行的 ln，不动手
# 退出码：0 全部就绪 / 1 存在无法恢复项
# 禁忌：目标目录不存在时不建链（避免造坏链）；存在同名实体目录时不覆盖（避免误伤真实数据）。

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SELF_DIR/../PATHS.env" || { echo "❌ 找不到 PATHS.env"; exit 2; }
ROOT=$(cd "$SELF_DIR/.." && pwd)

MODE=relink
case "$1" in
  --check|-c)   MODE=check ;;
  --dry-run|-n) MODE=dry-run ;;
  "")           ;;
  *) echo "用法: $0 [--check|--dry-run]"; exit 2 ;;
esac

fail=0; fixed=0; ok=0; skipped=0

printf '%-24s %-10s %s\n' "软链" "状态" "指向"
printf '%s\n' "----------------------------------------------------------------------"

for entry in "${AIIL_LINK_MAP[@]}"; do
  link=${entry%%|*}
  target=${entry#*|}
  target=${target%/}
  path="$ROOT/$link"

  # 已就绪：是软链、指向正确、且目标可达
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ] && [ -e "$path" ]; then
    printf '%-24s %-10s %s\n' "$link" "✅就绪" "$target"
    ok=$((ok+1)); continue
  fi

  # 目标实体不在：不建链
  if [ ! -d "$target" ]; then
    printf '%-24s %-10s %s\n' "$link" "⏭跳过" "目标不存在: $target"
    skipped=$((skipped+1)); fail=$((fail+1)); continue
  fi

  case "$MODE" in
    check)
      printf '%-24s %-10s %s\n' "$link" "❌需重建" "$target"
      fail=$((fail+1)) ;;
    dry-run)
      printf '%-24s %-10s %s\n' "$link" "→将建" "$target"
      fixed=$((fixed+1)) ;;
    relink)
      # 同名实体目录不覆盖
      if [ -e "$path" ] && [ ! -L "$path" ]; then
        printf '%-24s %-10s %s\n' "$link" "⚠️冲突" "存在同名实体目录，未覆盖"
        fail=$((fail+1)); continue
      fi
      mkdir -p "$(dirname "$path")"
      if ln -sfn "$target" "$path"; then
        printf '%-24s %-10s %s\n' "$link" "🔧已建" "$target"
        fixed=$((fixed+1))
      else
        printf '%-24s %-10s %s\n' "$link" "❌失败" "$target"
        fail=$((fail+1))
      fi
      ;;
  esac
done

echo
case "$MODE" in
  check)
    if [ "$fail" -eq 0 ]; then echo "✅ ${#AIIL_LINK_MAP[@]} 条软链全部就绪"; exit 0
    else echo "⚠️  $fail 条未就绪，跑 scripts/relink.sh 重建"; exit 1; fi ;;
  dry-run)
    echo "（dry-run）将新建/修正 $fixed 条，跳过 $skipped 条，本就就绪 $ok 条" ;;
  relink)
    if [ "$fail" -eq 0 ]; then echo "✅ 重建完成：$fixed 条新建/修正，$ok 条本就就绪"; exit 0
    else echo "⚠️  已处理 $fixed 条，仍有 $fail 条无法恢复（多为卷未挂载或实体缺失，先跑 check-paths.sh）"; exit 1; fi ;;
esac
