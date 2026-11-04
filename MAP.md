# MAP — ai-image-lab 一屏索引

**更新**：2026-11-04　**用途**：任何一处打开，30 秒内回答「这套系统由什么组成、实体在哪、怎么启动」。
**本项目的物理根**：`<HDD卷>/work/projects/ai-image-lab`（唯一逻辑根）。WIN11 侧同名目录只是**权重实体仓**，不是第二个项目根。
**路径真相源**：[PATHS.env](PATHS.env)。任何脚本里的 `/Volumes/...` 字面量都是技术债，改路径只改 PATHS.env。

---

## 一、四层架构（一套系统，不是四套）

| 层 | 引擎 | 实体位置 | 启动 | 典型耗时 | 用途 |
|---|---|---|---|---|---|
| **L1** | Draw Things CLI | `<SSD卷>/ai-image-lab/apps/draw-things` | `scripts/start-drawthings.sh` | 33s | 日常快速出图，苹果原生 Metal |
| **L2** | ComfyUI + GGUF | `<SSD卷>/ai-image-lab/apps/ComfyUI` | `scripts/start-comfyui.sh` | 54s | 图生图 / ControlNet / 节点流 |
| **L3** | stable-diffusion-webui | `<HDD卷>/work/projects/stable-diffusion-webui` | 见 runbook | ~30s | 老 SD1.5 生态、chilloutmix 等 |
| **L4** | 云端 API | `scripts/gen_cloud.py` | 见 runbook | 10–30s | 4K 复杂构图，需 API KEY |

分层选用速记：**日常 L1 → 图生图 L2 → 老 SD1.5 L3 → 4K 复杂 L4**。

## 二、权重在哪（唯一硬约束）

权重是整套系统里**唯一必须放最快盘**的东西——每张图都可能重读，3–8GB 一次。

| 权重库 | 路径 | 体积 | 谁在用 |
|---|---|---|---|
| **legacy-sd15** | `WIN11/ai-image-lab/models/legacy-sd15` | 12G | L2 经 `legacy_a1111` 挂载、L3 经 `models` 软链 |
| diffusion_models | `WIN11/ai-image-lab/models/diffusion_models` | 7.2G | L2（Flux 全量） |
| text_encoders | `WIN11/ai-image-lab/models/text_encoders` | 10G | L2 |
| unet（GGUF） | `WIN11/ai-image-lab/models/unet` | 2.3G | L2 |
| vae | `WIN11/ai-image-lab/models/vae` | 321M | L2 |
| drawthings | `WIN11/ai-image-lab/models/drawthings` | 7.3G | L1（原生格式，不可拆） |

**备份仓**：`<HDD卷>/work/data/models/sd-webui`（只读基准，31 文件）。
**同步方向恒定单向**：备份 → 运行副本，只增不删不覆盖。跑 `scripts/sync-models.sh`，**绝不反向**。
**为什么必须单向**：SSD 上有临时试验权重，反向同步会把垃圾写进基准；基准一旦被污染，就没有可信的比对源了。

## 三、产物去哪

唯一产物池：`outputs/`，按来源四子目录分治。**不存在第二个产物目录。**

| 子目录 | 来源 | 配置方式 |
|---|---|---|
| `outputs/comfyui/` | L2 | `start-comfyui.sh` 传 `--output-directory` |
| `outputs/drawthings/` | L1 | 启动器导出 `OUT_DIR` |
| `outputs/sd-webui/` | L3 | `webui-user.sh` 的 `--outdir=` |
| `outputs/archive/` | 手动归档 | — |

## 四、启动与自检

```bash
cd <HDD卷>/work/projects/ai-image-lab
scripts/check-paths.sh        # 先跑这个：全部路径有效吗？换盘/重启后必跑
scripts/start-drawthings.sh   # L1
scripts/start-comfyui.sh      # L2
scripts/sync-models.sh --check  # 权重两侧一致吗？
```

## 五、软链的意义（别当冗余清掉）

`apps/` 和 `models/` 下共 16 个软链。它们的目的**不是防拔盘冗余**，而是**统一寻址**——索引的物理化。

有了它，你打开项目根就能看见「L3 的引擎、L2 的引擎、A1111 的模型库」都在眼前，而不必记住六个物理位置。

**约束**：软链只出现在 `apps/` 和 `models/` 两层入口，**不往深处套第二层**。深层再套软链会让 `find`、`rsync`、备份全部变味。

## 六、三条不能动的禁忌

| 对象 | 为什么动了就坏 |
|---|---|
| **A1111 目录名与位置** | `webui-user.sh` 用 `install_dir` + `clone_dir` 拼路径，改名或移位会让 `webui.sh` 找不到项目 |
| **A1111 的 venv** | `venv/bin` 与 `pyvenv.cfg` 内 **41 个文件**含绝对路径 |
| **`_sdwebui-backup/` 目录本身** | `.app` 双击启动器的 `launch` 脚本把它当日志目录写 `run.log`，整目录删会让日志写入失效 |

## 七、挂载依赖（可卸载卷闸）

本项目**跨两块外置卷**，文档里的绝对路径视为「挂载后可解析」，而非恒定事实：

- `<HDD卷>`（机械盘，~92MB/s）：逻辑根、产物、文档、备份
- `<SSD卷>`（外置 SSD，APFS ~328MB/s）：权重实体、L1/L2 引擎

**盘没挂时**：`check-paths.sh` 会逐条报 ❌ 并给出退出码 1；`sync-models.sh` 会前置检查两侧卷并退出码 3。两者都能区分「跳过」与「故障」。

→ 操作细节见 [docs/runbook.md](docs/runbook.md)　→ 状态见 [docs/STATUS.md](docs/STATUS.md)
