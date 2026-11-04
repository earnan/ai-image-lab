# 运维手册

**更新**：2026-11-04
**前提**：本机需挂载 `<HDD卷>`（逻辑根 + 产物）与 `<SSD卷>`（引擎 + 权重）。文档中绝对路径均以「挂载后」为前提。任一卷缺失时所有启动器打印 `[SKIP]` 并退出 0。

## 服务清单

| 层 | 服务 | 端口 / 形态 | 启动 | 产物落点 | 日志 |
|---|---|---|---|---|---|
| L1 | Draw Things CLI | 一次性进程（非常驻） | `scripts/start-drawthings.sh` | `outputs/drawthings/` | 直接打印到终端 |
| L2 | ComfyUI | `127.0.0.1:8188` | `scripts/start-comfyui.sh` | `outputs/comfyui/` | 终端 |
| L3 | stable-diffusion-webui | `127.0.0.1:7860`（`--api` 已开） | `cd $AIIL_APP_SDWEBUI && ./webui.sh` | `outputs/sd-webui/` | `_sdwebui-backup/run.log`（双击 .app 时） |
| L4 | 云端 API | 出网调用 | `scripts/gen_cloud.py` | `outputs/` | 终端 |

配置文件位置（本文不复制内容，改配置去这两处）：
- 路径总表：`PATHS.env`
- L3 命令行参数：`<HDD卷>/work/projects/stable-diffusion-webui/webui-user.sh`
- L2 外部权重挂载：`$AIIL_APP_COMFY/extra_model_paths.yaml`（`legacy_a1111.base_path`）

## 启动

```bash
cd <项目根>

# 0. 先自检（换盘/重启/动了软链之后必跑）
scripts/check-paths.sh

# 1. L1 一次性出图（默认 512x512 4 步，实测 33s 含模型加载）
scripts/start-drawthings.sh
DT_PROMPT="a red teapot" DT_STEPS=4 DT_W=1024 DT_H=1024 scripts/start-drawthings.sh

# 2. L2 常驻服务（Ctrl+C 停止）
scripts/start-comfyui.sh            # 已在跑则直接打开浏览器

# 3. L3
cd <HDD卷>/work/projects/stable-diffusion-webui && ./webui.sh

# 4. L4（需先配 KEY）
cp scripts/.env.example scripts/.env   # 填入 API KEY
scripts/gen_cloud.py --help
```

## 排查

### 1. `check-paths.sh` 报 ❌

先看是哪条：`❌ AIIL_...` 说明该变量指向的路径不存在。
- 整片 ❌ 且提示 `未挂载` → **卷没挂上**，重新挂载后重跑；不是配置错误。
- 只有 `apps/*` 或 `models/*` 软链 ❌ → 实体还在但软链断了。重建：`ln -sfn "$AIIL_WEIGHTS/<子目录>" models/<子目录>`。**不要**直接 `cp` 实体过去。
- 只有 `AIIL_W_LEGACY_SD15` ❌ → 该目录曾被改名；确认 `$AIIL_WEIGHTS/legacy-sd15` 是否存在，若名字不同就改 `PATHS.env` 一处。

### 2. ComfyUI 启动但模型列表是空的

L2 通过 `extra_model_paths.yaml` 的 `legacy_a1111.base_path` 挂 A1111 的老库。该值若指向旧路径（曾为 `<SSD卷>/<旧权重目录>`），列表就空。

```bash
grep base_path "$AIIL_APP_COMFY/extra_model_paths.yaml"
# 应为 <SSD卷>/ai-image-lab/models/legacy-sd15/
```

### 2.1 loader 节点返回 500（配置已对、进程还在读旧值）

**症状**：ComfyUI 界面能开、`8188` 在监听，但 `VAELoader` / `CheckpointLoaderSimple` / `LoraLoader` / `UpscaleModelLoader` 一用就报错；查接口是 500：

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8188/object_info/VAELoader
# 200 = 正常；500 = 进程内部的目录列表还是旧的
```

日志里的真实原因（`/tmp/comfyui_restart.log`）：

```text
FileNotFoundError: [Errno 2] No such file or directory: '<SSD卷>/<旧权重目录>/Lora'
  at folder_paths.py get_filename_list -> os.path.getmtime(folder)
```

**根因**：`extra_model_paths.yaml` 只在**进程启动时**读一次，之后 `get_filename_list()` 用内存缓存。改配置后不重启，进程仍按旧路径枚举，目录已被改名就抛 `FileNotFoundError`。

**处理**：先确认配置本身对，再重启进程。

```bash
grep -E "base_path|checkpoints|vae|loras|upscale_models" "$AIIL_APP_COMFY/extra_model_paths.yaml"
# 期望 base_path: <SSD卷>/ai-image-lab/models/ 与 .../models/legacy-sd15/
# 逐个确认子目录存在（含 legacy_a1111 的 ESRGAN —— 空目录也算存在，缺目录才会 500）
scripts/start-comfyui.sh      # 重启后才生效
```

**规则**：改 `extra_model_paths.yaml`、加删模型目录 → **必须重启**。判断「是不是这个坑」，先看 `/object_info/<loader>` 是不是 500，而不是去看配置文件。当日实测：重启后 10s 就绪，6 类 loader 全 200。

### 3. L3 启动报找不到项目 / 路径错乱

A1111 用 `install_dir` + `clone_dir` **拼接**出项目路径（见 `webui-user.sh`）。所以：
- 不能改目录名 `stable-diffusion-webui`
- 不能把它挪出 `<HDD卷>/work/projects`
- 不能动 `venv`（41 个文件含绝对路径）

要挪，只能改 `install_dir`/`clone_dir` 后重建 venv。

### 4. 出图落到了意料之外的目录

产物由**三处**各自配置，互不感知：

| 层 | 配置点 | 期望值 |
|---|---|---|
| L1 | `start-drawthings.sh` 的 `--output` | `$AIIL_OUT_DT` |
| L2 | `start-comfyui.sh` 的 `--output-directory` | `$AIIL_OUT_COMFY` |
| L3 | `webui-user.sh` 的 `--outdir=` | `$AIIL_OUT_SD` |

只改了其中一处时，那一层会把产物写到默认目录。发现「产物又散了」先查这张表。

### 5. 权重两侧不一致

```bash
scripts/sync-models.sh --check    # 退出码 0 = 一致
scripts/sync-models.sh --dry-run   # 看将要补什么，不动手
scripts/sync-models.sh             # 备份 → 运行副本，只增不删
```

**永不反向**。SSD 上有临时试验权重，反向会把垃圾写进基准，基准一污染就失去比对价值。

### 6. 卷没挂 / 盘掉线

| 现象 | 原因 | 处理 |
|---|---|---|
| 脚本打印 `[SKIP] 未挂载或不存在` | 卷缺失，脚本按设计跳过 | 挂载后重跑，非故障 |
| `sync-models.sh` 退出码 3 | 前置卷检查未过 | 同上 |
| 磁盘写入报 `Read-only file system` | 外置盘掉线后 macOS 重挂为只读 | 卸载重挂，不要强行写 |

## 回滚

| 改了什么 | 怎么回滚 |
|---|---|
| L3 命令行参数（`--outdir`） | `cp webui-user.sh.bak-before-outdir webui-user.sh` |
| `PATHS.env` 路径 | 改回对应一行，然后 `scripts/check-paths.sh` 验证 |
| 某脚本写坏 | `git checkout -- scripts/<脚本名>`，从入库版本恢复；坏版本另存 `docs/archive/scripts-broken-20261104/` 备查 |
| 文档 / 工作流改坏 | `git checkout -- docs/ workflows/`；整片改动都不想要就 `git restore .` |
| 改了但还没提交 | `git diff` 看清再决定；`git restore <文件>` 丢弃单个文件 |

本项目已纳入 git，并推送到 GitHub 公开仓 `earnan/ai-image-lab`（2026-11-04；初始 54 文件 / 16 软链，经当次脱敏重写后为 42 文件、软链改为本机生成不入库）。根提交哈希每次历史重写都会变，用 `git rev-list --max-parents=0 HEAD` 查，别抄文档里的旧值。入库范围与排除项见根目录 `.gitignore` 与 `outputs/README.md`。

**公开仓 ≠ 权重备份**：仓里只有文档、脚本与工作流，权重实体的唯一副本仍在 HDD 备份侧，靠 `scripts/sync-models.sh` 维护。`git checkout` 只挡"手滑改坏"，挡不了整盘丢失。

## 挂载依赖提醒

本项目跨两块**可卸载卷**。迁移项目根或换盘时，必须同步三处，漏一处就会「跑的还是旧目录」：
1. `PATHS.env` 里的卷与根变量
2. 任何定时任务 / launchd plist 里的路径
3. 文档中的绝对路径（`MAP.md` §二、本文件）
