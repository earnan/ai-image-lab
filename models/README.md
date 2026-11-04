# models/

共享模型根的索引入口。**目录内的软链不入库**，由 `scripts/relink.sh` 在本机生成。

| 软链 | 层 | 指向 |
|---|---|---|
| `checkpoints` | L3 | `$AIIL_W_CHECKPOINTS` |
| `legacy-sd15` | L3 | `$AIIL_W_LEGACY_SD15` |
| `loras` | 通用 | `$AIIL_W_LORAS` |
| `vae` | 通用 | `$AIIL_W_VAE` |
| `embeddings` | 通用 | `$AIIL_W_EMBEDDINGS` |
| `controlnet` | 通用 | `$AIIL_W_CONTROLNET` |
| `clip_vision` | 通用 | `$AIIL_W_CLIP_VISION` |
| `text_encoders` | ComfyUI | `$AIIL_W_TEXT_ENCODERS` |
| `unet` | ComfyUI | `$AIIL_W_UNET` |
| `diffusion_models` | ComfyUI | `$AIIL_W_DIFFUSION_MODELS` |
| `upscale_models` | ComfyUI | `$AIIL_W_UPSCALE_MODELS` |
| `gguf` | ComfyUI | `$AIIL_W_GGUF` |
| `drawthings` | L1 | `$AIIL_W_DRAWTHINGS` |

变量定义见 `PATHS.env.example`，指向关系见其中的 `AIIL_LINK_MAP`。

## 为什么不入库

软链存的是目标字符串，而目标字符串就是本机的卷名与目录布局——入库等于公开磁盘结构。这里只留说明，唯一真相源是 `PATHS.env.example`。

## 铁律

**权重只放 SSD，绝不放机械盘。** GGUF 2.3GB 在 HDD 上加载需 25s+，SSD 上约 3s。存放位置由 `AIIL_WEIGHTS` 决定，不在这里重复声明。

软链是索引不是冗余，清理前先读 [MAP.md](../MAP.md) §五。
