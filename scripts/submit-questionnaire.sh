#!/bin/bash
# 山夏摄影 — 问卷结果投递脚本（Shell 版）
# 适用于 Claude Code / Cline / Cursor 等偏好 Shell 的 runtime
#
# 零配置：脚本内置默认 Worker URL 和 Token，装好即用。
# 如需覆盖，设置环境变量：
#   export SHANXIA_WORKER_URL="..."
#   export SHANXIA_API_TOKEN="..."
#
# 用法:
#   bash submit-questionnaire.sh result.json
#   cat result.json | bash submit-questionnaire.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ====================================================================
# 默认投递配置（零配置入口）
# 山夏部署 Worker 后，把这些值换成实际的 Worker URL 和 Token
# ====================================================================
DEFAULT_WORKER_URL="https://shanxia-questionnaire.womenhaiyouxiwang.workers.dev"
DEFAULT_AUTH_TOKEN="UwwijxCyQpCrjklaQ-07pVGd8MVFKlbMc4FAaSIhOr0"
# ====================================================================

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- 初始化 ---
WORKER_URL=""
AUTH_TOKEN=""
WEBHOOK_URL=""

# --- 读取输入 ---
if [ $# -ge 1 ] && [ -f "$1" ]; then
    INPUT_FILE="$1"
    DATA=$(cat "$INPUT_FILE")
elif [ ! -t 0 ]; then
    DATA=$(cat)
else
    # 尝试默认路径
    DEFAULT="${SKILL_DIR}/status/latest-questionnaire.json"
    if [ -f "$DEFAULT" ]; then
        DATA=$(cat "$DEFAULT")
        INPUT_FILE="$DEFAULT"
        echo -e "${YELLOW}📄 读取默认文件: ${DEFAULT}${NC}" >&2
    else
        echo -e "${RED}❌ 没有输入数据。用法:${NC}" >&2
        echo "   $0 result.json" >&2
        echo "   cat result.json | $0" >&2
        exit 1
    fi
fi

# --- 保存本地副本 ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NAME=$(echo "$DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('customer',{}).get('name','unknown'))" 2>/dev/null || echo "unknown")

OUTPUT_DIR="${SKILL_DIR}/status/questionnaires"
mkdir -p "$OUTPUT_DIR"
LOCAL_PATH="${OUTPUT_DIR}/${TIMESTAMP}_${NAME}.json"
echo "$DATA" > "$LOCAL_PATH"
echo -e "${GREEN}✅ 本地已保存: ${LOCAL_PATH}${NC}" >&2

# --- 获取 webhook URL ---
WEBHOOK_URL=""

# 1. 环境变量
if [ -n "${SHANXIA_WORKER_URL:-}" ] && [ -n "${SHANXIA_API_TOKEN:-}" ]; then
    WORKER_URL="$SHANXIA_WORKER_URL"
    AUTH_TOKEN="$SHANXIA_API_TOKEN"
elif [ -n "${SHANXIA_WEBHOOK_URL:-}" ]; then
    WEBHOOK_URL="$SHANXIA_WEBHOOK_URL"
fi

# 2. 凭据文件
if [ -z "$WORKER_URL" ] && [ -z "$WEBHOOK_URL" ]; then
    if [ -f "$HOME/.hermes/credentials.json" ]; then
        CFG=$(python3 -c "
import json
with open('$HOME/.hermes/credentials.json') as f:
    d = json.load(f)
url = d.get('shanxia_worker_url') or ''
token = d.get('shanxia_api_token') or ''
wh = d.get('shanxia_webhook') or ''
print(f'{url}|{token}|{wh}')
" 2>/dev/null || true)
        IFS='|' read -r WORKER_URL AUTH_TOKEN WEBHOOK_URL <<< "$CFG"
    fi
fi

# 3. 本地配置
if [ -z "$WORKER_URL" ] && [ -z "$WEBHOOK_URL" ] && [ -f "${SKILL_DIR}/scripts/webhook_config.json" ]; then
    CFG=$(python3 -c "
import json
d = json.load(open('${SKILL_DIR}/scripts/webhook_config.json'))
url = d.get('worker',{}).get('url','') or d.get('url','')
token = d.get('worker',{}).get('token','') or d.get('token','')
wh = d.get('webhook_url','') or d.get('webhook','')
print(f'{url}|{token}|{wh}')
" 2>/dev/null || true)
    IFS='|' read -r WORKER_URL AUTH_TOKEN WEBHOOK_URL <<< "$CFG"
fi

# 4. 默认值（零配置）
if [ -z "$WORKER_URL" ] && [ -z "$WEBHOOK_URL" ]; then
    if [ -n "$DEFAULT_WORKER_URL" ] && [ -n "$DEFAULT_AUTH_TOKEN" ]; then
        WORKER_URL="$DEFAULT_WORKER_URL"
        AUTH_TOKEN="$DEFAULT_AUTH_TOKEN"
    fi
fi

# --- 投递 ---
if [ -z "$WORKER_URL" ] && [ -z "$WEBHOOK_URL" ]; then
    echo -e "${YELLOW}⚠️  未配置投递方式。问卷结果已保存到本地:${NC}" >&2
    echo "   ${LOCAL_PATH}" >&2
    echo "" >&2
    echo "配置方式: 修改脚本顶部的 DEFAULT_WORKER_URL 和 DEFAULT_AUTH_TOKEN" >&2
    exit 0
fi

# 用 Python 格式化 embed 并投递
EMBED_SCRIPT="${SKILL_DIR}/scripts/_embed_formatter.py"

if [ -n "$WORKER_URL" ]; then
    # 通过 Worker 代理投递
    PYTHON_RESULT=$(echo "$DATA" | python3 "$EMBED_SCRIPT" | python3 -c "
import json, sys, urllib.request
msg = json.load(sys.stdin)
req = urllib.request.Request(
    '$WORKER_URL',
    data=json.dumps(msg).encode('utf-8'),
    headers={
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $AUTH_TOKEN',
        'User-Agent': 'ShanxiaBot/2.0',
    },
    method='POST',
)
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        result = json.loads(resp.read().decode())
        if result.get('ok'):
            print('ok')
        else:
            print(f'error: {result.get(\"error\", \"unknown\")}')
except Exception as e:
    print(f'error: {e}')
" 2>/dev/null || echo "error: python_failed")
else
    # 直接投递到 webhook
    PYTHON_RESULT=$(echo "$DATA" | python3 "$EMBED_SCRIPT" | python3 -c "
import json, sys, urllib.request
msg = json.load(sys.stdin)
req = urllib.request.Request(
    '$WEBHOOK_URL',
    data=json.dumps(msg).encode('utf-8'),
    headers={
        'Content-Type': 'application/json',
        'User-Agent': 'ShanxiaBot/2.0',
    },
    method='POST',
)
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        if resp.status in (200, 204):
            print('ok')
        else:
            print(f'http_{resp.status}')
except Exception as e:
    print(f'error: {e}')
" 2>/dev/null || echo "error: python_failed")
fi

RESULT="$?"
if echo "$PYTHON_RESULT" | grep -q "^ok$"; then
    echo -e "${GREEN}✅ 已投递到山夏 Discord${NC}" >&2
    echo -e "   本地副本: ${LOCAL_PATH}" >&2
else
    echo -e "${RED}❌ 投递失败: ${PYTHON_RESULT}${NC}" >&2
fi
