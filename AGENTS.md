> 本文件是 CLAUDE.md 的同源副本，给非 Claude 的 AI 工具读。**改规则请改 CLAUDE.md 再同步过来**，不要只改这里。

# ai-image-lab

**AI 协作入口**。本文件定义规则与导航；具体事实见 [MAP.md](MAP.md)，不在此复制。

## 项目定位

macOS（M2 Mac mini 16GB）本机本地出图环境：一套四层架构（L1–L4），按任务复杂度选用不同引擎。物理上跨两块外置卷，逻辑上以 HDD 侧为唯一根。

## 阶段规划

| 阶段 | 目标 | 状态 | 关键产出 |
|---|---|---|---|
| 1 四层落地 | L1–L4 全部可用 | done | 四层实测通过，L4 待填 KEY |
| 2 结构整理 | 索引优先：一屏索引 + 单向同步 + 产物归一 | done | MAP.md / PATHS.env / check-paths.sh / sync-models.sh |
| 3 日常使用 | 按任务选层出图，产物归档 | wip | — |

## 技术栈

| 层 | 方案 | 选型理由 |
|---|---|---|
| L1 | Draw Things CLI（Metal） | 苹果原生，23s 最快，日常首选 → [overview](docs/overview.md) |
| L2 | ComfyUI + GGUF 量化 | 节点流灵活，GGUF 让 16GB 能跑 Flux → [overview](docs/overview.md) |
| L3 | stable-diffusion-webui | 老 SD1.5 生态兼容（chilloutmix 等） |
| L4 | 云端 API | 本机算力上限之外的 4K 复杂构图 |

## 目录结构

```
<项目根>/     ← 唯一逻辑根
├── MAP.md              一屏索引（组成/实体位置/启动/禁忌）
├── PATHS.env           绝对路径唯一真相源，脚本 source 它
├── README.md           项目入口与工作区约定
├── CLAUDE.md / AGENTS.md  本文件（AI 契约）
├── CHANGELOG.md        变更史
├── apps/               引擎统一寻址（3 个软链，实体不动）
├── models/             权重统一寻址（13 个软链，实体在 WIN11）
├── workflows/          L1–L4 工作流文件
├── outputs/            唯一产物池（comfyui/drawthings/sd-webui/archive）
├── scripts/            启动器 + 同步 + 自检
└── docs/               文档区（只放 .md）
    ├── README.md       文档索引（问题驱动：我想知道 X → 去哪）
    ├── STATUS.md       状态单页（唯一高频更新）
    ├── overview.md     项目全貌（只写不变的东西）
    ├── runbook.md      启动 / 排查 / 回滚
    ├── design/         设计选型（编号，只留最新版）
    ├── research/       性能实测（数字必须标 A/B/C 数据等级）
    ├── reference/      MPS 格式限制、工作流就绪状态
    ├── inbox/          未归类笔记（永久保留，不清理）
    └── archive/        历史（只增不改）
```

## 当前任务

阶段 2 已完成。后续按任务选层使用；L4 需填入 API KEY 才可用。

## 快速导航

| 我想知道... | 去哪里 |
|---|---|
| 这套系统由什么组成、实体在哪、怎么启动 | [MAP.md](MAP.md) |
| 现在什么状态、卡在哪 | [docs/STATUS.md](docs/STATUS.md) |
| 怎么启动 / 怎么排障 / 怎么回滚 | [docs/runbook.md](docs/runbook.md) |
| 这个项目到底在解决什么问题 | [docs/overview.md](docs/overview.md) |
| 为什么这么分层、为什么引擎留在机械盘 | [docs/design/](docs/design/) |
| 性能数字是怎么测出来的 | [docs/research/](docs/research/) |
| GGUF 能用哪些量化格式、为什么不在 MPS 上用 Q4_K_M | [docs/reference/mps-量化格式限制.md](docs/reference/mps-量化格式限制.md) |
| 哪几个工作流现在真能跑 | [docs/reference/workflows-就绪状态.md](docs/reference/workflows-就绪状态.md) |
| 有哪些绝对不能动的 | [MAP.md](MAP.md) §六 |

## 文档维护规则

### 何时更新

| 触发条件 | 需要更新的文件 |
|---|---|
| 路径 / 盘位 / 引擎位置变化 | `PATHS.env` + `MAP.md`，并跑 `check-paths.sh` |
| 新增引擎或换模型库 | `MAP.md` §一/§二 + `docs/STATUS.md` |
| 启动方式变化 | `docs/runbook.md` |
| 做出技术决策 | `docs/design/` + `docs/STATUS.md` |
| 阶段进度变化 | `docs/STATUS.md` |
| 废弃方案 | 移到 `docs/archive/YYYY-MM/` |

### 检查清单（收尾前过一遍）

- [ ] 改了 `CLAUDE.md` → `AGENTS.md` 同步了吗？
- [ ] 改了路径 → `PATHS.env` 是唯一改动点吗？脚本里还有硬编码的 `/Volumes/...` 吗？
- [ ] 新增了目录 → `MAP.md` 或 `docs/STATUS.md` 有对应条目吗？
- [ ] 有二进制文件混进 `docs/` 吗？→ 分离到 `archive/` 或跟对应 .md 放
- [ ] 有废弃方案 → 移到 `docs/archive/` 了吗？
- [ ] `check-paths.sh` 通过吗？

## 约束红线

1. **权重必须放最快的盘**——每张图都可能重读 3–8GB；实测 GGUF 2.3GB 从 HDD 加载 25s+，从 SSD 约 3s。放到慢盘不是"稍微慢点"，是把 23s 的出图变成 48s。
2. **禁止反向同步权重**——单向 rsync（备份→运行副本）是有意设计。反向写会把 SSD 上的临时试验权重污染基准仓，基准被污染后就没有可信比对源。
3. **禁止迁移 A1111 目录或其 venv**——41 个文件含绝对路径，动了就坏（详见 [MAP.md](MAP.md) §六）。
4. **禁止在脚本里硬编码绝对路径**——路径散落是这次整理的根因。新脚本一律 `source ../PATHS.env`；硬编码会让改卷、换盘时漏改，形成「跑的是旧目录」的双源。
5. **软链不是冗余**——`apps/` 和 `models/` 下的软链是统一寻址，有语义。清理"无用软链"会拆掉索引的物理层。
6. **`docs/` 只放 .md**——二进制无法 diff，且消费者不同（图片给浏览器，md 给人/AI）。混入后 docs/ 会逐渐失去纯文档语义。

## 知识提取规则

本项目可复用知识分流到 `~/base` 七仓（按知识性质，不按来源）：

- **操作性做法 / 踩坑** → `~/base/common-knowledge/knowledge/<主题域>/`（四要素：结论 / 做法 / 为什么 / 来源）
- **设计模式 / 灵感** → `~/base/oss-patterns/patterns/<域>/`（五要素：模式 / 适用场景 / 要点 / 边界 / 来源）

一条规则：会话结束时自问——本次有没有「重新推导成本高、换项目仍成立」的发现？有就直接写正式条目（status: draft），一次 1–3 条，宁缺毋滥。

**不写入** Marvis 自身知识库；"沉淀到知识库"一律指 `~/base`。

## 通用知识

本项目：本地 AIGC 出图环境的物理落地与运维——磁盘带宽分层、引擎与权重分离、软链统一寻址、可卸载卷上的路径策略。

- 检索操作性做法/踩坑：`grep -r "" ~/base/common-knowledge/knowledge/`
- 检索设计灵感：`grep -r "" ~/base/oss-patterns/patterns/`

## 文档结构自举

本项目文档结构由 `~/base/doc-structure-guide` 初始化。该指南有自举机制（`docs/principles.md` §五）：被用于服务外部项目时自检一次，**递归深度上限 1**。

若在服务本项目时发现指南存在真实盲区（而非本项目的特殊情况），按指南 §5.3 终止条件修订指南并在其 CHANGELOG 留痕——不要在项目会话里反复迭代指南。
