# 工作流就绪状态

**更新**：2026-11-04　**核实方式**：逐个比对 JSON 与 `models/` 下实体文件，非依据文档描述。

## 总览

7 个 ComfyUI 工作流，**2 个真就绪，5 个缺模型**。项目 `workflows/L2-comfyui/` 与 ComfyUI 前端 `user/default/workflows/` 各 7 个，内容一致。

> 2026-11-04 复测补充：**模型引用齐备 ≠ 能跑。** 还需引擎侧 `loader` 节点可枚举（`/object_info/VAELoader` 为 200）。核验口径见 [四层可用性核验](四层可用性核验.md)。

## 就绪（可直接跑）

| 工作流 | 路径 | 依赖 |
|---|---|---|
| Flux2 Klein 4B 文生图 | `L2-comfyui/txt2img/01-flux2-klein-4b-t2i.json` | `unet/flux-2-klein-4b-Q4_0.gguf` 2.3G + `text_encoders/Qwen3-4B-Q5_0.gguf` + `vae/flux2-vae.safetensors` |
| Flux2 Klein 4B 图生图（蒸馏） | `L2-comfyui/img2edit/01-flux2-klein-4b-edit-distilled.json` | 同上 |

## 缺模型（跑不起来）

| 工作流 | 缺什么 | 缺的目录当前状态 |
|---|---|---|
| `txt2img/02-qwen-image-2.1-turbo-t2i.json` | Qwen Image 2.1 全套 | 需另下（7B + 8B TE，全套 int8 约 15.8G，16GB 内存极勉强） |
| `img2edit/02-flux2-klein-4b-edit-base.json` | Flux2 Klein **base**（非蒸馏）4B | 需另下 |
| `img2edit/03-qwen-image-edit-2511.json` | Qwen Image Edit | 需另下 |
| `controlnet/01-qwen-image-controlnet.json` | ControlNet 模型 + qwen_image | `models/controlnet/` **0 项 0B** |
| `upscale/01-gan-upscaler.json` | GAN/ESRGAN 放大模型 | `models/upscale_models/` **0 项 0B** |

## 空目录说明（不是遗漏）

| 目录 | 为什么空 |
|---|---|
| `workflows/L1-drawthings/` | L1 是 CLI 一次性调用，不产生 JSON 工作流 |
| `workflows/L3-a1111/` | L3 用 webui 自己的 UI 与参数，工作流不落此 |
| `workflows/L4-cloud/` | L4 是 prompt 模板文本，不是节点图 |

## 模型仓实况（13 子目录，7 个为空）

| 目录 | 项数 | 体积 |
|---|---|---|
| `unet` | 1 | 2.3G（Q4_0 GGUF） |
| `text_encoders` | 2 | 10G（GGUF Q5_0 + fp16） |
| `vae` | 1 | 321M |
| `diffusion_models` | 1 | 7.2G（fp16 全量，GGUF 稳定后可考虑删） |
| `drawthings` | — | 7.3G（L1 专用格式） |
| `legacy-sd15` | 30 文件 | 12G（L3 老库） |
| `controlnet` `upscale_models` `loras` `embeddings` `clip_vision` `gguf` `checkpoints` | 0 | 0B |

**注意**：`gguf/` 是空目录，但 GGUF 权重实际放在 `unet/` 下。两者别混淆——ComfyUI 的 GGUF 节点读 `unet/`。

## 解析工作流时的两个坑（2026-11-04 实测）

1. **subgraph 结构**：新版 ComfyUI 导出的工作流把采样链封进子图，顶层 `nodes` 只有 `SaveImage`、`PrimitiveStringMultiline` 和两个 UUID 类型的子图实例。模型引用藏在 `definitions.subgraphs[].nodes[].widgets_values` 里，**只解析顶层会得到"引用 0 个模型"的假阴性**。
   - 做法：对整份 JSON 递归收集所有字符串值，按扩展名（`.safetensors/.gguf/.ckpt/.pt/.pth/.bin`）筛，再与模型仓文件名比对。
2. **注释节点会混入 URL**：`MarkdownNote` 节点里写着 HuggingFace 下载链接，同样以 `.safetensors` 结尾，会被当成模型引用。比对时把 `http…` 开头的条目排除，否则"缺失数"虚高（如 `01-flux2-klein-4b-t2i.json` 实际只缺 base 版 1 个，不排除 URL 会算成缺 2 个）。

## 引擎侧前置

| 检查 | 命令 | 期望 |
|---|---|---|
| 服务在 | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8188/system_stats` | 200 |
| loader 可枚举 | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8188/object_info/VAELoader` | 200（500 需重启，见 runbook §2.1） |
| GGUF 节点在 | `/object_info/UnetLoaderGGUF` 返回含 `flux-2-klein-4b-Q4_0.gguf` | 存在 |

2026-11-04 实测：重启前 4 类通用 loader 因旧路径缓存返回 500；确认重启（10s 就绪）后 6 类 loader 全 200，GGUF 侧可见（`UnetLoaderGGUF` 列出 Q4_0、`CLIPLoaderGGUF` 列出 Q5_0/fp16），flux2-klein-4b 蒸馏分支实测出图 81.2s。
