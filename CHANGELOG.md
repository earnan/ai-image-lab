# 变更日志

格式：每次变更记 **版本 / 日期 / Why / 做了什么**。Why 必填——只记做了什么，半年后没人知道为什么。

## v0.2.3 — 2026-11-04 — 公开仓脱敏：剥离 AIGC 元数据与本地磁盘布局

**Why**
仓已推为公开仓，但入库内容里同时带着两类不该外露的东西：平台自动注入的 AIGC front-matter（生产者/内容 ID/传播码等字段，纯噪声且带平台追踪串），以及真实绝对路径（本机卷名、用户目录、软链指向）——后者等于把磁盘结构公开。

**做了什么**
- 21 份文档删除 AIGC front-matter 与重复的 AI 生成声明尾注
- 文档内的本机绝对路径统一替换为占位符：外置 SSD 卷名 → `<SSD卷>`、机械盘卷名 → `<HDD卷>`、用户目录 → `<用户目录>`、项目根 → `<项目根>`
- `PATHS.env` 拆成两件：`PATHS.env.example`（占位符模板，入库）+ `PATHS.env`（本机真实值，已入 `.gitignore`）。模板只改顶部两行卷名，其余变量全部由其派生
- **16 条软链从索引摘除**：软链存的是目标字符串，而目标字符串就是本机卷名与目录布局，入库等于公开磁盘结构。改由 `relink.sh` 按 `AIIL_LINK_MAP` 在本机生成，`apps/` 与 `models/` 只留说明 README
- 全历史重写（`git filter-repo --blob-callback`）抹掉旧提交里的真实路径、平台追踪串与 AIGC 块；旧哈希全部失效。文档里原本写死的根提交哈希改为运行时查询，免得每次重写后又失效一遍

**代价**
旧提交哈希不可再引用；换机流程多一步 `cp PATHS.env.example PATHS.env`。

## v0.2.2 — 2026-11-04 — 四层可用性复测：修正"全部可用"的结论

**Why**
STATUS 原写着"四层出图链路全部可用"，但那是凭"端口在、文件在、脚本在"得出的。本轮按逐层实证复测，发现两处不成立：L2 的 4 类 loader 接口返回 500（实际不可用），L4 仍缺 KEY。一句话结论若不修正，下次会话会照着错的前提干活。

**做了什么**
- 新增 `docs/reference/四层可用性核验.md`：每层两条证据的核验口径、三个"看起来正常实则不可用"的坑、本轮实测数据与根因
- `docs/STATUS.md`：一句话改为"L1/L3 可用、L2 待重启、L4 缺 KEY"；阻塞清单补 L2 一条；健康检查加 loader 探活命令；观察项加"配置热改无效"
- `docs/runbook.md`：新增 §2.1 —— loader 返回 500 的定位与处理（配置只在启动时读一次，改完必须重启）
- `docs/reference/workflows-就绪状态.md`：补"模型齐备 ≠ 能跑"的引擎侧前置；记录解析工作流的两个坑（subgraph 嵌套、MarkdownNote 里的 URL 混入）
- `docs/README.md`：导航补四层核验入口

**复测数据**
- L1 `flux_2_klein_4b_q6p.ckpt` 512×512/4 步：`Total generation time 29.49s`（采样均值 4.10s/步）
- L2：`8188` 在监听、GGUF 模型可见，但 `VAELoader`/`CheckpointLoaderSimple`/`LoraLoader`/`UpscaleModelLoader` 均 500，根因为进程内缓存旧路径 `<SSD卷>/<旧权重目录>/*`
- L3：`/sdapi/v1/sd-models` 200，已加载 `chomni`、`CounterfeitV25_25`
- L4：`scripts/.env` 不存在，未通

**L2 修复（经确认后执行）**
旧 PID 64531 → 新 79432，重启 10s 就绪。`VAELoader` / `CheckpointLoaderSimple` / `LoraLoader` / `UpscaleModelLoader` / `UnetLoaderGGUF` / `CLIPLoaderGGUF` 全部 200；模型可见性恢复（VAE 3 项、ckpt 3 项含 legacy-sd15、LoRA 5 项）。复跑 flux2-klein-4b 蒸馏分支 512×512 / 4 步，出图 **81.2s**（首次含加载），产物 `outputs/comfyui/verify_L2_20261104_00001_.png`。

**边界**
L4 仍未通（无 API KEY）。L1 / L2 / L3 本轮均有当日实测产物，可视为当前基线。

## v0.2.1 — 2026-11-04 — 纳入 git 版本管理

**Why**
两天里两次"改坏只能手工救"：脚本被覆盖后靠 `.bak` 抢回来，文档重写后靠 `docs/archive/` 手抄留档。而 runbook 回滚段一直写着「或 `git checkout`（若已入库）」——一条悬空的逃生路线，因为项目根本不在 git 里。趁文档骨架刚立完、工作区是干净基线，把版本管理补上，这条路线才成立；顺带修掉 runbook 里那句带括号的不确定表述。

**做了什么**
- `git init -b main`，根提交：54 文件 / 19718 行，`.git` 456K（该哈希已随 v0.2.3 的历史重写失效，当前根提交用 `git rev-list --max-parents=0 HEAD` 查询）
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
