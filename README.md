
# ai-image-lab

M2 Mac mini 16GB 上的本地 AI 出图环境。四层引擎分工，跨两块外置盘，以本目录为唯一逻辑根。

## 一句话

按任务选层出图——日常 L1、图生图 L2、老模型 L3、高画质 L4；产物统一落 `outputs/`，权重统一在 SSD，路径统一在 `PATHS.env`。

## 快速开始

```bash
cd <HDD卷>/work/projects/ai-image-lab
scripts/check-paths.sh        # 先自检：盘挂好了吗、软链断了吗
scripts/start-drawthings.sh   # L1 出图（实测 33s）
scripts/start-comfyui.sh      # L2 服务，浏览器开 127.0.0.1:8188
```

## 去哪看

| 想知道 | 文件 |
|---|---|
| 由什么组成、实体在哪、怎么启动、有什么禁忌 | [MAP.md](MAP.md) |
| 现在什么状态、卡在哪 | [docs/STATUS.md](docs/STATUS.md) |
| 怎么启动 / 排查 / 回滚 | [docs/runbook.md](docs/runbook.md) |
| 这些设计为什么这么定 | [docs/design/](docs/design/) |
| 文档索引 | [docs/README.md](docs/README.md) |
| AI 协作规则 | [CLAUDE.md](CLAUDE.md) |

## 工作区约定

1. **路径只写在 `PATHS.env`**——脚本 `source` 它。脚本里出现 `/Volumes/...` 字面量即为待清理的技术债。
2. **权重放 SSD，产物放 HDD**——权重每张图都可能重读，引擎只在启动时读一次（[依据](docs/research/01-磁盘与加载性能实测.md)）。
3. **单向同步**：`备份仓 → 运行副本`，只增不删。永不反向。
4. **`apps/` 与 `models/` 下的软链是索引**，不是冗余，清理前先读 [MAP.md](MAP.md) §五。
5. **`docs/` 只放 `.md`**。

## 前置条件

需挂载 `<HDD卷>` 与 `<SSD卷>`。任一卷缺失时脚本打印 `[SKIP]` 并按设计退出，不是故障。
