
# 变更日志

格式：每次变更记 **版本 / 日期 / Why / 做了什么**。Why 必填——只记做了什么，半年后没人知道为什么。

## v0.2.1 — 2026-11-04 — 纳入 git 版本管理

**Why**
两天里两次"改坏只能手工救"：脚本被覆盖后靠 `.bak` 抢回来，文档重写后靠 `docs/archive/` 手抄留档。而 runbook 回滚段一直写着「或 `git checkout`（若已入库）」——一条悬空的逃生路线，因为项目根本不在 git 里。趁文档骨架刚立完、工作区是干净基线，把版本管理补上，这条路线才成立；顺带修掉 runbook 里那句带括号的不确定表述。

**做了什么**
- `git init -b main`，根提交 `7248621`：54 文件 / 19718 行，`.git` 456K
- 新增 `.gitignore`：`outputs/**`（只留 README）、`scripts/.env`（L4 API KEY 实体）、`_sdwebui-backup/`、`__pycache__`、`.DS_Store`
- 新增 `outputs/README.md`：四个子目录的来源与写入配置点、产物不入库的依据、清理前检查项
- `apps/` 3 个 + `models/` 13 个软链入库（mode 120000，git 只存指向字符串，不递归外部实体）
- `docs/runbook.md` 回滚段：悬空表述改为确定命令，补"文档/工作流改坏""未提交改动"两行，并写明"本地 git ≠ 备份"

**边界**
未设 remote。本地提交只能挡手滑改坏，挡不了整盘丢失——权重唯一副本仍在 HDD 备份侧，由 `scripts/sync-models.sh` 维护。

## v0.2.0 — 2026-11-04 — 文档结构立骨架

**Why**
目录实体已就位（MAP.md、PATHS.env、软链、产物归一都已落地），但文档层仍是单份 README 硬扛。新人（或新 AI 会话）读一份 129 行 README 要自己摘出"现状"和"为什么"，而 README 每改一次现状就要整篇重写。按 `~/base/doc-structure-guide` 初始化，把"现状 / 决策 / 操作 / 事实"拆开，各归其位。

**做了什么**
- 新增 `docs/README.md`——问题驱动的文档索引（"我想知道 X → 去哪"）
- 新增 `docs/overview.md`——项目全貌：解决什么问题、核心概念、为什么值得搞；只写不变的东西
- 新增 `docs/runbook.md`——启动 / 6 类排查 / 回滚 / 挂载依赖
- 新增 `docs/design/01-四层架构选型.md`——四层为何并存、引擎为何可留 HDD、权重为何必须在 SSD
- 新增 `docs/design/02-索引优先整理方案.md`——为何否决"物理搬整齐"、采纳"索引优先"，四档执行结果
- 新增 `docs/research/01-磁盘与加载性能实测.md`——分级性能表 + L1 冷启动复测 + fp16 swap 发现；标注 A/B 数据等级
- 新增 `docs/reference/mps-量化格式限制.md`——GGUF 格式白名单、蒸馏步数、内存分水岭
- 新增 `docs/reference/workflows-就绪状态.md`——7 个工作流逐个核实：2 就绪 / 5 缺模型
- 重写 `README.md` 为指针式入口（原 129 行完整版归档至 `docs/archive/README-20261104-四层架构完整版.md`）
- `docs/` 按指南分层：`design/` `research/` `reference/` `inbox/` `archive/`

**Why 重写而非保留 README**
README 里混着三类内容：架构（不变）、性能数据（会变）、待办（天天变）。混在一起必然要么过时要么频繁重写。拆分后 README 只做一件事——指路。

## v0.1.0 — 2026-11-04 — 索引优先整理落地

**Why**
四层引擎能跑，但跑完找不回来：12G 老库不在项目树、产物散三处、脚本各自硬编码路径、4 个 0 字节空壳目录。初版方案想搬权重，评估后否决（跨卷 mv 是真拷贝，且打断两处引用）。

**做了什么**
- 建 `MAP.md`（一屏索引）+ `PATHS.env`（绝对路径唯一真相源）
- `apps/` `models/` 两层共 16 个软链，暴露 WIN11 侧实体，不动任何字节
- 权重仓同卷改名 `热数据/sd-webui-models` → `ai-image-lab/models/legacy-sd15`，只改 2 处引用
- 补 chilloutmix 缺失权重，两侧 32 文件对齐（md5 一致）
- 产物三处归一到 `outputs/`（30 文件），旧路径清空
- 清 venv.broken-*(322M)、broken-checkpoint(255M)，释放约 577M；`_sdwebui-backup/` 目录保留（launch 脚本要写 run.log）
- 启动器全部改走 `PATHS.env`；L1/L2 启动器此前全为注释无实代码，重写并实跑验证（L1 成功出图 33.24s）
