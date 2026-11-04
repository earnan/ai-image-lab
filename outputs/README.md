# outputs/ —— 运行产物落点

本目录**不入 git**（见根目录 `.gitignore`）。此 README 是唯一入库的文件。

## 目录语义

| 子目录 | 来源 | 写入配置点 |
|---|---|---|
| `drawthings/` | L1 Draw Things CLI | `scripts/start-drawthings.sh` 的 `--output`（`$AIIL_OUT_DT`） |
| `comfyui/` | L2 ComfyUI | `scripts/start-comfyui.sh` 的 `--output-directory`（`$AIIL_OUT_COMFY`） |
| `sd-webui/` | L3 stable-diffusion-webui | `webui-user.sh` 的 `--outdir=`（`$AIIL_OUT_SD`） |
| `archive/` | 人工归档的历史产物 | 手工移动 |

产物由三处**各自**配置、互不感知。产物落到意料之外的目录时，查 `docs/runbook.md` §排查 4。

## 为什么不入库

- 体积：当前约 30M，且每次出图都会增长；工作流固定时，相同参数可复现同一图，图片二进制本身没有版本比对价值。
- 可复现的是参数，不是像素：生成参数记录在 `workflows/`（ComfyUI 工作流 JSON）与 `scripts/` 里，这些**已入库**。
- 例外判断：若某张图成为文档或对比结论的依据（如 `docs/research/` 里的实测），把**那张图**单独复制进 docs 对应目录，而不是放开整个 outputs。

## 清理

本目录可整体重建，删前确认：
1. `docs/` 中没有文档引用其中文件（`scripts/check-docs.sh` 会报断链）；
2. 需要留的图已归档到 `archive/` 或 docs。

清理台账格式参考 `docs/archive/清理台账-20261104-可重建残渣.md`。
