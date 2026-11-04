
# 项目状态

**更新**：2026-11-04
**负责人**：earnan

## 一句话

四层出图链路全部可用，结构整理已完成（索引优先方案落地）；当前唯一未通的是 L4 云端缺 API KEY，其余按需使用即可。

## 阶段进度

| 阶段 | 状态 | 关键结果 | 详细文档 |
|---|---|---|---|
| 1 四层落地 | done | L1 33s / L2 54s / L3 ~30s 均实测可用，L4 脚本就绪待 KEY | [overview](overview.md) |
| 2 结构整理 | done | 索引 + 单向同步 + 产物归一 + 残渣清理，释放约 577M | [design/02](design/02-索引优先整理方案.md) |
| 3 日常使用 | wip | 按任务选层出图 | — |
| 4 文档骨架 | done | 按 `~/base/doc-structure-guide` 初始化：README 指针化 + overview/runbook/design×2/research/reference×2 + `check-docs.sh` 自检全绿 | [docs/README](README.md) |

## 当前阻塞

- [ ] **L4 云端未通**：`scripts/gen_cloud.py` 就绪，`.env` 缺 API KEY。不做也能用 L1–L3，故不阻塞其他工作。

## 健康检查（三条命令）

```bash
scripts/check-paths.sh          # 全部路径有效吗
scripts/sync-models.sh --check  # 权重两侧一致吗
du -sh outputs/*                # 产物分布
```

2026-11-04 实测：路径 0 处悬空；权重两侧一致（`README-*.md` 按设计排除）；产物池 comfyui 7 / drawthings 4 / sd-webui 33 个文件。

## 技术栈

| 层 | 方案 | 选型理由 |
|---|---|---|
| L1 | Draw Things CLI | 33s 最快，苹果原生 Metal → [design/01](design/01-四层架构选型.md) |
| L2 | ComfyUI + GGUF | 节点流 + 量化让 16GB 跑 Flux → [design/01](design/01-四层架构选型.md) |
| L3 | stable-diffusion-webui | 老 SD1.5 生态兼容 |
| L4 | 云端 API | 突破本机算力上限 |

## 在观察什么

- **引擎留在机械盘**的代价：启动读一次约 500MB 小文件，可接受；但若将来出现"每次出图都重读引擎"的场景，此前提就失效，需重新评估。
- **权重仓单点**：全部权重集中在 `<SSD卷>`，该卷故障时无在线副本，只能从 `<HDD卷>/work/data/models/sd-webui` 恢复（legacy-sd15 部分）。

## 上次文档验证
2026-11-04（`scripts/check-docs.sh` 全绿）
