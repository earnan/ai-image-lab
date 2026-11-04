#!/usr/bin/env python3
"""L4 层：云端 API 出图兜底（本地跑不动或需要更高质量时使用）

用法:
    cp .env.example .env      # 填入至少一个 KEY
    python gen_cloud.py "一只红陶茶壶，木质桌面，晨光"
    python gen_cloud.py "..." --provider siliconflow --size 1024x1024 --n 2

支持 provider:
    dashscope   —— 阿里云百炼（通义万相），国内直连
    siliconflow —— 硅基流动（Kolors / FLUX），国内直连
    openai      —— OpenAI images，需外网
"""
import os
import sys
import json
import time
import base64
import argparse
import urllib.request
from pathlib import Path

ENV_PATH = Path(__file__).parent / ".env"


def load_env():
    if not ENV_PATH.exists():
        return
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip())


def post_json(url, payload, headers, timeout=180):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data,
                                 headers={"Content-Type": "application/json", **headers})
    return json.load(urllib.request.urlopen(req, timeout=timeout))


def save_image(url_or_b64, out_dir, idx, prefix="cloud"):
    out_dir.mkdir(parents=True, exist_ok=True)
    p = out_dir / ("%s_%03d.png" % (prefix, idx))
    if url_or_b64.startswith("http"):
        urllib.request.urlretrieve(url_or_b64, p)
    else:
        p.write_bytes(base64.b64decode(url_or_b64))
    return p


def gen_openai(prompt, size, n, out_dir):
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        sys.exit("缺少 OPENAI_API_KEY")
    base = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
    r = post_json(base + "/images/generations",
                  {"model": os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1"),
                   "prompt": prompt, "size": size, "n": n},
                  {"Authorization": "Bearer " + key})
    return [save_image(d.get("b64_json") or d.get("url"), out_dir, i)
            for i, d in enumerate(r.get("data", []))]


def gen_siliconflow(prompt, size, n, out_dir):
    key = os.environ.get("SILICONFLOW_API_KEY")
    if not key:
        sys.exit("缺少 SILICONFLOW_API_KEY")
    r = post_json("https://api.siliconflow.cn/v1/images/generations",
                  {"model": os.environ.get("SILICONFLOW_IMAGE_MODEL", "Kwai-Kolors/Kolors"),
                   "prompt": prompt, "image_size": size, "batch_size": n},
                  {"Authorization": "Bearer " + key})
    data = r.get("images") or r.get("data") or []
    return [save_image(d["url"], out_dir, i) for i, d in enumerate(data)]


def gen_dashscope(prompt, size, n, out_dir):
    key = os.environ.get("DASHSCOPE_API_KEY")
    if not key:
        sys.exit("缺少 DASHSCOPE_API_KEY")
    model = os.environ.get("DASHSCOPE_IMAGE_MODEL", "wan2.5-t2i")
    hdr = {"Authorization": "Bearer " + key, "X-DashScope-Async": "enable"}
    r = post_json("https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis",
                  {"model": model, "input": {"prompt": prompt},
                   "parameters": {"size": size.replace("x", "*"), "n": n}}, hdr, timeout=60)
    task_id = r["output"]["task_id"]
    print("  任务已提交: " + task_id)
    for _ in range(60):
        time.sleep(3)
        req = urllib.request.Request("https://dashscope.aliyuncs.com/api/v1/tasks/" + task_id,
                                     headers={"Authorization": "Bearer " + key})
        st = json.load(urllib.request.urlopen(req, timeout=30))
        status = st["output"]["task_status"]
        if status == "SUCCEEDED":
            return [save_image(x["url"], out_dir, i)
                    for i, x in enumerate(st["output"]["results"])]
        if status in ("FAILED", "CANCELED"):
            sys.exit("任务失败: %s" % st)
        print("  " + status + " ...")
    sys.exit("轮询超时")


PROVIDERS = {"openai": gen_openai, "siliconflow": gen_siliconflow, "dashscope": gen_dashscope}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt")
    ap.add_argument("--provider", default=None, choices=list(PROVIDERS))
    ap.add_argument("--size", default="1024x1024")
    ap.add_argument("--n", type=int, default=1)
    ap.add_argument("--out", default=str(Path(__file__).parent.parent / "outputs"))
    a = ap.parse_args()

    load_env()
    provider = a.provider or os.environ.get("IMAGE_PROVIDER", "dashscope")
    out_dir = Path(a.out)
    print("[L4 云端] provider=%s size=%s n=%d" % (provider, a.size, a.n))
    files = PROVIDERS[provider](a.prompt, a.size, a.n, out_dir)
    print("完成:")
    for f in files:
        print("  ", f)


if __name__ == "__main__":
    main()
