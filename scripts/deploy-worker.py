#!/usr/bin/env python3
"""山夏摄影 — Cloudflare Worker 部署脚本"""
import json, sys
from pathlib import Path
import urllib.request
import urllib.error

# === 读取配置 ===
cred_path = Path.home() / ".hermes" / "credentials.json"
if not cred_path.exists():
    print("❌ 找不到凭据文件: ~/.hermes/credentials.json")
    sys.exit(1)

creds = json.loads(cred_path.read_text())
api_token = creds.get("cloudflare")
account_id = creds.get("cloudflare_account_id")

if not api_token or not account_id:
    print("❌ 凭据文件中缺少 cloudflare 或 cloudflare_account_id")
    sys.exit(1)

# === 读取 Worker 代码 ===
script_path = Path(__file__).resolve().parent / "cloudflare-worker.js"
worker_code = script_path.read_text()

print(f"📄 读取 Worker 代码: {len(worker_code)} 字符")

# === 部署 Worker ===
worker_name = "shanxia-questionnaire"
base_url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/scripts/{worker_name}"
headers = {
    "Authorization": f"Bearer {api_token}",
    "User-Agent": "ShanxiaBot/2.0",
}

# 1. 先检查是否已存在
req = urllib.request.Request(f"{base_url}", headers=headers, method="GET")
try:
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        if result.get("success"):
            print(f"📋 Worker '{worker_name}' 已存在，准备更新...")
        else:
            print(f"🆕 Worker '{worker_name}' 不存在，准备创建...")
except urllib.error.HTTPError as e:
    print(f"🆕 Worker '{worker_name}' 不存在（{e.code}），准备创建...")

# 2. 上传 Worker 脚本
# Cloudflare API 需要 multipart/form-data 格式
boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
body_parts = [
    f"--{boundary}\r\n"
    f'Content-Disposition: form-data; name="metadata"\r\n'
    f"Content-Type: application/json\r\n\r\n"
    f'{json.dumps({"body_part": "script", "main_module": "worker.js"})}\r\n',
    f"--{boundary}\r\n"
    f'Content-Disposition: form-data; name="worker.js"; filename="worker.js"\r\n'
    f"Content-Type: application/javascript+module\r\n\r\n"
    f"{worker_code}\r\n",
    f"--{boundary}--\r\n",
]
body = "".join(body_parts).encode("utf-8")

print("⏳ 正在上传 Worker 脚本...")

req = urllib.request.Request(
    f"{base_url}",
    data=body,
    headers={
        **headers,
        "Content-Type": f"multipart/form-data; boundary={boundary}",
    },
    method="PUT",
)

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read())
        if result.get("success"):
            print("✅ Worker 部署成功！")
        else:
            errors = result.get("errors", [])
            print(f"❌ 部署失败: {json.dumps(errors, ensure_ascii=False)}")
            sys.exit(1)
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"❌ HTTP {e.code}: {body[:500]}")
    sys.exit(1)

# 3. 获取 Worker 子域名
subdomain_url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/subdomain"
req = urllib.request.Request(subdomain_url, headers=headers, method="GET")
try:
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        if result.get("success"):
            subdomain = result["result"]["subdomain"]
            worker_url = f"https://{worker_name}.{subdomain}.workers.dev"
            print(f"\n🌐 Worker URL: {worker_url}")
        else:
            print("\n⚠️  无法获取子域名，请到 Cloudflare Dashboard 查看 Worker URL")
except:
    print("\n⚠️  无法获取子域名，请到 Cloudflare Dashboard 查看 Worker URL")

# 4. 提醒设置环境变量
print(f"""
────────────────────────────────────────
⚠️  还需设置环境变量（Dashboard 操作）：

1. 打开 https://dash.cloudflare.com → Workers & Pages → {worker_name}
2. 进「设置」→「环境变量」
3. 添加这两个变量：

   变量名: DISCORD_WEBHOOK_URL
   值:    你的 Discord webhook URL

   变量名: AUTH_TOKEN
   值:    用下面命令生成:
          python3 -c "import secrets; print(secrets.token_urlsafe(32))"

4. 点「保存并部署」
────────────────────────────────────────
""")

print("✅ 部署完成！记得去 Dashboard 设置环境变量才能正常使用～")
