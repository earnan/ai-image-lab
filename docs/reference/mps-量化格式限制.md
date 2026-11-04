
# Apple MPS 上的量化格式限制

**来源**：本项目 2026-11 实测（早期记录，迁移自 README）
**适用**：M2 Mac mini 16GB / macOS + ComfyUI / Draw Things

## 一、GGUF 量化格式白名单

| 格式 | MPS 可用 | 说明 |
|---|---|---|
| Q4_0 / Q4_1 | ✅ | 项目当前在用（unet `flux-2-klein-4b-Q4_0.gguf`） |
| Q5_0 | ✅ | 可用 |
| **Q4_K_M / Q5_K_M** | ❌ | **在 Apple MPS 上出坏图**（不是慢，是输出图像异常） |
| FP8 | ❌ | 不支持 |
| CUDA 专用优化 | ❌ | 无关 |

**踩坑点**：社区推荐列表里 Q4_K_M 往往是"性价比最优"，但在 MPS 上直接用会得到垃圾输出，且不报错——**静默出坏图**比报错更难排查。选 GGUF 时先确认是 `_0` / `_1` 系列，不是 `_K_M` 系列。

## 二、蒸馏模型的步数与 CFG

FLUX.2 Klein 4B **蒸馏版**：
- 最少 **4 步**
- CFG 固定 **1.0**（蒸馏模型不吃 CFG 引导，改高会过曝）

非蒸馏 base 版（需另下模型）：可调 CFG，画质更高但需 20+ 步。

## 三、内存分水岭

| 配置 | 结果 |
|---|---|
| GGUF Q4_0 全链路 | 正常驻留，可用 |
| fp16 全套 14.7GB | 占满 16GB 统一内存 → 触发 14.8GB swap → 慢 2.5 倍 |

**16GB 机器的结论**：量化不是可选优化，是前提条件。详见 [research/01](../research/01-磁盘与加载性能实测.md) §二。

## 四、其它

- `PYTORCH_ENABLE_MPS_FALLBACK=1`（L3 的 `webui-user.sh` 已设）：MPS 不支持的算子回退到 CPU 执行，避免直接崩，但会拖慢。
- L3 启动参数含 `--no-half-vae --upcast-sampling`：MPS 上 half 精度 VAE 会出黑图/色带，必须 upcast。
