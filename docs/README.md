
# 文档导航

## 我想知道...

| 问题 | 去哪里 |
|---|---|
| 这套系统由什么组成、实体在哪、怎么启动 | [../MAP.md](../MAP.md) |
| 现在什么状态、卡在哪、还健康吗 | [STATUS.md](STATUS.md) |
| 怎么启动某个引擎 | [runbook.md](runbook.md) §启动 |
| 出图跑不起来 / 产物跑丢了 | [runbook.md](runbook.md) §排查 |
| 这个项目到底在解决什么问题（给新人看） | [overview.md](overview.md) |
| 为什么分四层、为什么不合并成一个引擎 | [design/01-四层架构选型.md](design/01-四层架构选型.md) |
| 为什么引擎能留机械盘、权重为什么必须放 SSD | [design/01](design/01-四层架构选型.md) §决策 |
| 2026-11-04 那次大整理到底改了什么 | [design/02-索引优先整理方案.md](design/02-索引优先整理方案.md) |
| 那些性能数字是怎么测的 | [research/01-磁盘与加载性能实测.md](research/01-磁盘与加载性能实测.md) |
| 有没有删掉不该删的东西 | [archive/清理台账-20261104-可重建残渣.md](archive/清理台账-20261104-可重建残渣.md) |
| 旧版 README 讲了什么 | [archive/README.old.md](archive/README.old.md) |

## 目录结构

| 路径 | 职责 |
|---|---|
| `STATUS.md` | 项目状态单页，唯一高频更新文件 |
| `runbook.md` | 运维操作：启动 / 排查 / 回滚 |
| `overview.md` | 项目全貌，给第一次接触的人 |
| `design/` | 设计推理链与方案选型（编号，只留最新版） |
| `research/` | 技术调研与实测对比 |
| `reference/` | 参考资料（少量外部 .docx/.pdf 可放此） |
| `inbox/` | 未归类笔记，永久保留 |
| `archive/` | 历史，只增不改 |

## 约定

- `docs/` 只放 `.md`。二进制文件按类型分流：设计素材 → 项目根 `archive/`，运行时资源 → 跟代码走。
- 废弃文档移入 `archive/YYYY-MM/`，顶部加一行 `> 原路径:`。
- 归档文件内的相对链接不再维护，断链检查豁免 `archive/`。
