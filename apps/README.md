# apps/

运行时引擎的索引入口。**目录内的软链不入库**，由 `scripts/relink.sh` 在本机生成。

| 软链 | 指向 |
|---|---|
| `comfyui` | `$AIIL_APP_COMFY` |
| `draw-things` | `$AIIL_APP_DT` |
| `sd-webui` | `$AIIL_APP_SDWEBUI` |

## 为什么不入库

软链存的是目标字符串，而目标字符串就是本机的卷名与目录布局——入库等于公开磁盘结构。所以这里只留说明，指向关系全部收敛到 `PATHS.env.example` 的 `AIIL_LINK_MAP`。

换机或卷名变更后：

```sh
cp PATHS.env.example PATHS.env    # 改顶部两行卷名
scripts/relink.sh                 # 按 AIIL_LINK_MAP 重建，幂等
scripts/check-paths.sh            # 复核
```

目标目录不存在时 `relink.sh` 跳过而不是造坏链；同名实体目录不会被覆盖。
