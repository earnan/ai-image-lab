
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

## 换机重建

仓库里存的是文档、脚本、工作流与 **16 条软链的指向**；引擎与权重在盘上，不在仓内。换一台机器按三步走：

```bash
# 1. 克隆（放哪都行，后面以 PATHS.env 为准）
git clone git@github.com:earnan/ai-image-lab.git ~/ai-image-lab && cd ~/ai-image-lab

# 2. 改 PATHS.env 顶部的卷与根变量，指向新机的实际路径
vi PATHS.env

# 3. 一行恢复全部 16 条软链（幂等；目标不存在则跳过，不造坏链）
scripts/relink.sh
scripts/check-paths.sh    # 复核：应 0 处悬空
```

`relink.sh --dry-run` 只看不改，`--check` 只报状态。它按 `PATHS.env` 的 `AIIL_LINK_MAP` 逐条建链，所以**增删模型目录只需改那一处**。

clone 之后软链本来就断（git 只存指向字符串），这不是故障；卷没挂载时 `relink.sh` 会全数跳过，挂上重跑即可。

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
