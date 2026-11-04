# ai-image-lab — 本地出图工作区

M2 Mac mini 16GB 的统一出图中枢。三套引擎共用一套模型、一套产物、一套脚本。

## 目录职责

| 目录 | 内容 |
| --- | --- |
| `apps/` | 各引擎工作区软链（ComfyUI user 目录、Draw Things 数据目录等），程序本体不放这里 |
| `workflows/` | ComfyUI 工作流 JSON，按用途命名，可纳入 git |
| `scripts/` | 批量出图、参数扫参、后处理脚本 |
| `presets/` | 提示词模板、采样参数预设、负面词库 |
| `outputs/` | 出图结果，按 `YYYY-MM-DD_用途/` 分目录 |
| `docs/` | 踩坑记录、模型清单、性能实测数据 |

## 三卷分工（2026-11-04 实测）

| 卷 | 介质 | 可用 | 顺序读 | 职责 |
| --- | --- | --- | --- | --- |
| Macintosh HD `/` | 内置 SSD | 22 GB | — | 引擎程序本体 + Python venv（启动快，小文件随机读最优） |
| `<SSD卷>` | 外置 SSD (APFS, 可写) | 252 GB | 328 MB/s | **全部模型权重**，各引擎软链共享 |
| `<HDD卷>` | 外置机械盘 | 672 GB | 92 MB/s | 出图产物、备份、冷数据 |

内置盘不得放模型。HDD 不得放模型（92MB/s 加载 11GB 权重需 2 分钟，拖死首帧）。

## 模型共享根

统一本体目录：`<SSD卷>/热数据/ai-models/`

```
ai-models/
├── checkpoints/        # SD1.5 / SDXL 主模型
├── diffusion_models/   # Flux / Qwen Image 等 DiT 主干
├── text_encoders/      # CLIP / T5
├── vae/
├── loras/
├── controlnet/
├── upscale_models/
└── embeddings/
```

各引擎指认方式：
- **A1111** — `models/*` 建软链指向上述子目录；升级切 tag 后须复查软链是否被 git 重建为实体目录
- **ComfyUI** — `extra_model_paths.yaml` 指定 `base_path` 与各子目录
- **Draw Things** — 导入模型时指向同一目录（或复制，DT 有自己的模型管理）

一套权重三处复用，禁止复制多份。

## 引擎分层

| 层 | 引擎 | 定位 |
| --- | --- | --- |
| L1 快速 | Draw Things | 原生 Metal，秒级出草稿稿 |
| L2 主力 | ComfyUI | 工作流编排、多模型串联、批量 |
| L3 质量/兼容 | A1111 v1.10.1 | LoRA 生态、老工作流、中文 UI |

## 性能实测基线（M2 16GB）

- A1111 SD1.5 512×512 / 20 步：约 30 s/张（首张 93 s）
- Flux.2 Klein 4B q4_0 512×512 / 4 步：约 61 s，峰值内存 5 GB
- Qwen Image 2.1 Q4 GGUF 512×512：约 4 min（内存吃紧，走 swap）

## 约束

- MPS 无 CUDA，FP8 不可用；GGUF 只用 Q4_0/Q4.1/Q5_0，K_M 量化出坏图
- 编辑类任务加 `--cpu-vae`，避免 VAE 精度导致成品发灰/污染
- 模型不入 git；工作流、脚本、预设入 git
