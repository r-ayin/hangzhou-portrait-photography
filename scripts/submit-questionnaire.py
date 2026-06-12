#!/usr/bin/env python3
"""
山夏摄影 — 问卷结果投递脚本

将问卷生成的客户画像投递到山夏的 Discord。
支持两种投递方式：
  1. Cloudflare Worker（安全代理）— 默认方式，webhook URL 不暴露
  2. Discord Webhook（直接）— 备选

零配置：脚本自带默认 Worker URL 和 Token，装好即用。
如需覆盖默认配置，设置环境变量或编辑 webhook_config.json。

用法:
  # 从 JSON 文件投递
  python3 submit-questionnaire.py /path/to/questionnaire-result.json

  # 从 stdin 投递
  cat result.json | python3 submit-questionnaire.py

配置（按优先级）:
  1. 环境变量:
     export SHANXIA_WORKER_URL="..."
     export SHANXIA_API_TOKEN="..."
  2. 本地配置文件:
     scripts/webhook_config.json
  3. 脚本内置默认值（零配置）
"""

import json
import os
import sys
from pathlib import Path
from typing import Optional


SKILL_DIR = Path(__file__).resolve().parent.parent

# ====================================================================
# 默认投递配置（零配置入口）
# 山夏部署 Worker 后，把这些值换成实际的 Worker URL 和 Token
# 然后其他人 clone 这个 skill 就能直接用，不用额外配置
# ====================================================================
DEFAULT_WORKER_URL = "https://shanxia-questionnaire.womenhaiyouxiwang.workers.dev"
DEFAULT_AUTH_TOKEN = "UwwijxCyQpCrjklaQ-07pVGd8MVFKlbMc4FAaSIhOr0"
# ====================================================================


def load_webhook_url() -> Optional[str]:
    """优先级：参数 > 环境变量 > 凭据文件 > 本地配置"""
    
    # 1. 环境变量
    url = os.environ.get("SHANXIA_WEBHOOK_URL")
    if url:
        return url
    
    # 2. 凭据管理文件（Hermes 统一凭据系统）
    cred_paths = [
        Path.home() / ".hermes" / "credentials.json",
        Path.home() / ".hermes" / "credentials.yml",
        SKILL_DIR / "scripts" / "webhook_config.json",
    ]
    for cp in cred_paths:
        if cp.exists():
            try:
                data = json.loads(cp.read_text())
                url = data.get("shanxia_webhook") or data.get("webhooks", {}).get("shanxia")
                if url:
                    return url
            except (json.JSONDecodeError, KeyError):
                continue

    # 3. 尝试 cred 命令（Hermes 专用）
    import subprocess
    try:
        result = subprocess.run(
            ["python3", "-c", "import cred; print(cred.get('shanxia_webhook'))"],
            capture_output=True, text=True, timeout=5,
            env={**os.environ, "PYTHONPATH": str(Path.home() / ".hermes" / "scripts")}
        )
        if result.returncode == 0 and result.stdout.strip():
            url = result.stdout.strip()
            if url.startswith("http"):
                return url
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    return None
def load_worker_config() -> Optional[dict]:
    """加载 Cloudflare Worker 代理配置（优先级：环境变量 > 配置文件 > 默认值）"""
    url = os.environ.get("SHANXIA_WORKER_URL")
    token = os.environ.get("SHANXIA_API_TOKEN")
    if url and token:
        return {"url": url, "token": token}

    # 凭据文件
    cred_paths = [
        Path.home() / ".hermes" / "credentials.json",
        SKILL_DIR / "scripts" / "webhook_config.json",
    ]
    for cp in cred_paths:
        if cp.exists():
            try:
                data = json.loads(cp.read_text())
                url = data.get("shanxia_worker_url") or data.get("worker", {}).get("url")
                token = data.get("shanxia_api_token") or data.get("worker", {}).get("token")
                if url and token:
                    return {"url": url, "token": token}
            except (json.JSONDecodeError, KeyError):
                continue

    # 默认值（零配置）
    if DEFAULT_WORKER_URL and DEFAULT_AUTH_TOKEN:
        return {"url": DEFAULT_WORKER_URL, "token": DEFAULT_AUTH_TOKEN}

    return None


def format_discord_message(data: dict) -> dict:
    """将 JSON 画像格式化为 Discord webhook embed 消息"""
    from _embed_formatter import format_embed
    return format_embed(data)


def load_json(input_path: Optional[str] = None) -> dict:
    """从文件或 stdin 加载 JSON"""
    if input_path:
        return json.loads(Path(input_path).read_text(encoding="utf-8"))
    else:
        # 从 stdin 读取
        raw = sys.stdin.read()
        if not raw.strip():
            # 尝试读取默认输出路径
            default_path = SKILL_DIR / "status" / "latest-questionnaire.json"
            if default_path.exists():
                return json.loads(default_path.read_text(encoding="utf-8"))
            raise ValueError("没有输入数据，也没有找到默认输出文件")
        return json.loads(raw)


def save_local(data: dict):
    """保存本地副本"""
    output_dir = SKILL_DIR / "status" / "questionnaires"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    c = data.get("customer", {})
    name = c.get("name", "unknown").replace(" ", "_")
    output_path = output_dir / f"{timestamp}_{name}.json"
    
    output_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )
    print(f"✅ 本地已保存: {output_path}")
    return output_path


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="山夏摄影 — 问卷结果投递脚本"
    )
    parser.add_argument(
        "input", nargs="?", default=None,
        help="问卷结果 JSON 文件路径（缺省从 stdin 读取）"
    )
    parser.add_argument(
        "--webhook", "-w", default=None,
        help="Webhook URL（覆盖环境变量，仅测试用）"
    )
    parser.add_argument(
        "--save-only", action="store_true",
        help="仅保存本地，不投递"
    )
    parser.add_argument(
        "--local", action="store_true",
        help="仅保存到本地 status/questionnaires/ 目录"
    )
    args = parser.parse_args()

    # 1. 加载 JSON
    try:
        data = load_json(args.input)
    except (json.JSONDecodeError, ValueError) as e:
        print(f"❌ JSON 解析失败: {e}")
        sys.exit(1)

    # 2. 保存本地副本（总是执行）
    saved_path = save_local(data)

    # 3. 如果只保存不投递
    if args.save_only or args.local:
        return

    # 4. 获取投递配置（优先 Worker 代理，其次直接 webhook）
    message = format_discord_message(data)
    payload = json.dumps(message).encode("utf-8")

    worker_config = load_worker_config()
    if worker_config:
        # 通过 Cloudflare Worker 代理投递
        import urllib.request
        import urllib.error

        req = urllib.request.Request(
            worker_config["url"],
            data=payload,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {worker_config['token']}",
                "User-Agent": "ShanxiaBot/2.0",
            },
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                result = json.loads(resp.read().decode())
                if result.get("ok"):
                    print(f"✅ 已通过 Worker 投递到山夏 Discord")
                else:
                    print(f"⚠️  Worker 返回: {result.get('error', '未知错误')}")
        except urllib.error.HTTPError as e:
            print(f"❌ Worker 投递失败 (HTTP {e.code})")
            sys.exit(1)
        except urllib.error.URLError as e:
            print(f"❌ 网络错误: {e.reason}")
            sys.exit(1)
    else:
        # 直接投递到 Discord webhook
        webhook_url = args.webhook or load_webhook_url()
        if not webhook_url:
            print("⚠️  未配置投递方式。问卷结果已保存到本地:")
            print(f"   {saved_path}")
            print("")
            print("配置方式（任选其一）:")
            print("  1. Worker 代理（推荐）:")
            print("     export SHANXIA_WORKER_URL='https://your-worker.workers.dev/submit'")
            print("     export SHANXIA_API_TOKEN='xxx'")
            print("  2. 直接 webhook:")
            print("     export SHANXIA_WEBHOOK_URL='https://discord.com/api/webhooks/...'")
            sys.exit(0)
        
        import urllib.request
        import urllib.error

        req = urllib.request.Request(
            webhook_url,
            data=payload,
            headers={
                "Content-Type": "application/json",
                "User-Agent": "ShanxiaBot/2.0",
            },
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                if resp.status == 204 or resp.status == 200:
                    print(f"✅ 已投递到 Discord webhook")
                else:
                    print(f"⚠️  webhook 返回 {resp.status}: {resp.read().decode()}")
        except urllib.error.HTTPError as e:
            print(f"❌ 投递失败 (HTTP {e.code}): {e.read().decode()[:200]}")
            sys.exit(1)
        except urllib.error.URLError as e:
            print(f"❌ 网络错误: {e.reason}")
            sys.exit(1)

    print(f"   本地副本: {saved_path}")


if __name__ == "__main__":
    main()
