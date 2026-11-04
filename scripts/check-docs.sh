#!/usr/bin/env bash
# 文档结构自检：断链 + 必需文件 + docs 分层合规
# 用法: scripts/check-docs.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
say() { printf '%s\n' "$*"; }
bad() { printf '  ❌ %s\n' "$*"; fail=1; }
ok()  { printf '  ✅ %s\n' "$*"; }

say "=== 1. 必需文件 ==="
for f in README.md MAP.md PATHS.env CLAUDE.md AGENTS.md CHANGELOG.md \
         docs/README.md docs/STATUS.md docs/overview.md docs/runbook.md; do
  [ -f "$f" ] && ok "$f" || bad "$f 缺失"
done

say ""
say "=== 2. 断链检查 ==="
say "  (排除第三方代码目录：apps/ venv/ node_modules/ repositories/)"
python3 - <<'PY'
import os, re, glob
link_re = re.compile(r'\[[^\]]*\]\(([^)]+)\)')
EXCLUDE_PATH = ("apps/", "venv/", "node_modules/", "repositories/", ".git/")
EXEMPT_LINK = ("docs/archive/", "docs/inbox/")
bad = ok = skip = 0
for md in glob.glob("**/*.md", recursive=True):
    if any(p in md for p in EXCLUDE_PATH):
        continue
    exempt = any(md.startswith(e) for e in EXEMPT_LINK)
    for m in link_re.finditer(open(md, encoding="utf-8", errors="ignore").read()):
        t = m.group(1).split("#")[0].strip()
        if not t or t.startswith(("http://", "https://", "mailto:", "/")):
            continue
        p = os.path.normpath(os.path.join(os.path.dirname(md), t))
        if os.path.exists(p):
            ok += 1
        elif exempt:
            skip += 1
        else:
            print(f"  ❌ {md} -> {t}"); bad += 1
print(f"  有效 {ok} / 断链 {bad} / 豁免区跳过 {skip}")
raise SystemExit(1 if bad else 0)
PY
[ $? -ne 0 ] && fail=1

say ""
say "=== 3. docs 分层合规 ==="
# docs 下只允许 md 与文档子目录；二进制不该出现在 docs
stray=$(find docs -maxdepth 1 -type f ! -name '*.md' 2>/dev/null)
[ -z "$stray" ] && ok "docs/ 顶层只有 .md" || bad "docs/ 顶层有非 md 文件: $stray"

# 必需子目录
for d in docs/design docs/research docs/reference docs/inbox docs/archive; do
  [ -d "$d" ] && ok "$d/" || bad "$d/ 缺失"
done

say ""
say "=== 4. STATUS 时效 ==="
age=$(( ( $(date +%s) - $(stat -f %m docs/STATUS.md 2>/dev/null || echo 0) ) / 86400 ))
if [ "$age" -le 14 ]; then
  ok "STATUS.md 上次更新 ${age} 天前"
else
  say "  ⚠️  STATUS.md 已 ${age} 天未更新，确认是否已过时"
fi

say ""
if [ "$fail" -eq 0 ]; then say "全部通过。"; else say "存在问题，见上方 ❌。"; fi
exit "$fail"
