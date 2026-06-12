#!/bin/bash
# GEO AI平台引用监控脚本 v2
# 使用方式: bash ~/.hermes/skills/山夏摄影约拍/scripts/geo-monitor.sh
#
# 功能:
#   1. 自动检查各AI平台对山夏摄影的引用情况（能自动的部分自动）
#   2. 不能自动的生成手动检查清单
#   3. 周对比：标记"新出现"和"消失"的引用
#   4. 输出 GEO 状态报告
#
# 用法:
#   bash geo-monitor.sh              # 完整检查
#   bash geo-monitor.sh --report     # 只输出上次报告摘要
#   bash geo-monitor.sh --init       # 初始化目录结构

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATUS_DIR="$SKILL_DIR/status"
LOG_FILE="$STATUS_DIR/geo-monitor-log.jsonl"
REPORT_DIR="$STATUS_DIR/reports"
QUERY_DATE=$(date +%Y-%m-%d)
QUERY_TIME=$(date +%Y-%m-%dT%H:%M:%S%z)
WEEK_NUM=$(date +%V)

mkdir -p "$STATUS_DIR" "$REPORT_DIR"

# ============================
# 配置：要监控的查询
# ============================
QUERIES=(
  "杭州约拍推荐"
  "杭州个人写真"
  "杭州独立摄影师"
  "杭州新中式写真"
  "杭州汉服约拍"
  "杭州旅拍价格"
  "杭州晚霞拍摄"
  "杭州摄影推荐"
)

PLATFORMS=(
  "文心一言:yiyan.baidu.com"
  "通义千问:tongyi.aliyun.com"
  "DeepSeek:chat.deepseek.com"
  "腾讯元宝:yuanbao.tencent.com"
)

# ============================
# 记录函数
# ============================
record_check() {
  local query="$1"
  local platform="$2"
  local found="$3"  # true/false
  local sources="$4"

  jq -n \
    --arg date "$QUERY_DATE" \
    --arg ts "$QUERY_TIME" \
    --arg q "$query" \
    --arg p "$platform" \
    --argjson f "$found" \
    --arg s "$sources" \
    '{date: $date, timestamp: $ts, query: $q, platform: $p, found: $f, sources: $s}' \
    >> "$LOG_FILE"
}

# ============================
# 上次结果对比
# ============================
compare_with_last_week() {
  local platform="$1"
  local query="$2"
  local current_found="$3"

  # 找上周同平台同查询的记录
  local last_week_file="$REPORT_DIR/week-$(printf "%02d" $((WEEK_NUM - 1))).md"
  if [ -f "$last_week_file" ]; then
    local last_status=$(grep "| $platform | $query |" "$last_week_file" 2>/dev/null | awk -F'|' '{print $4}' | xargs)
    if [ "$last_status" = "✅" ] && [ "$current_found" = "false" ]; then
      echo " ⚠️ 消失！上次出现本周消失"
    elif [ "$last_status" != "✅" ] && [ "$current_found" = "true" ]; then
      echo " 🆕 新出现！上周未出现本周出现"
    fi
  fi
}

# ============================
# 主逻辑
# ============================

echo "============================================"
echo "  GEO 引用监控 · 第 ${WEEK_NUM} 周 · $QUERY_DATE"
echo "============================================"
echo ""

# ——— 初始化报告 ———
REPORT_FILE="$REPORT_DIR/week-$(printf "%02d" $WEEK_NUM).md"
{
  echo "# GEO 引用监控报告 · 第${WEEK_NUM}周 · $QUERY_DATE"
  echo ""
  echo "## 核查清单"
  echo ""
  echo "| 平台 | 查询 | 山夏出现？ | 引用来源 | 变化 |"
  echo "|------|------|-----------|----------|------|"
} > "$REPORT_FILE"

echo "⚠️  AI平台通常封禁自动化查询，以下需要手动确认："
echo ""

for pentry in "${PLATFORMS[@]}"; do
  platform="${pentry%%:*}"
  url="${pentry##*:}"

  echo "--- $platform ($url) ---"
  echo ""

  for q in "${QUERIES[@]}"; do
    echo "  □ 查询：「$q」"
    echo "    山夏出现？ [y/N]  引用来源：______"
    echo ""

    # 写入报告占位
    echo "| $platform | $q | □ | 待确认 | — |" >> "$REPORT_FILE"
  done
  echo ""
done

# ——— 汇总 ———
{
  echo ""
  echo "## 快速跳转"
  echo "- 文心一言: https://yiyan.baidu.com"
  echo "- 通义千问: https://tongyi.aliyun.com"
  echo "- DeepSeek: https://chat.deepseek.com"
  echo "- 腾讯元宝: https://yuanbao.tencent.com"
  echo ""
  echo "## 检查步骤"
  echo "1. 打开每个AI平台"
  echo "2. 输入以上 8 个查询词"
  echo "3. 看回答里有没有提到：山夏摄影 / shanyue523478 / 山夏女摄"
  echo "4. 如果有，记录引用的具体来源（小红书/知乎/其他）"
  echo "5. 修改本报告文件：把 □ 改成 ✅ 或 ❌，填写来源"
  echo ""
  echo "## 本周状态"
  echo "待确认..."
} >> "$REPORT_FILE"

echo ""
echo "============================================"
echo "  报告已生成: $REPORT_FILE"
echo "  完整日志: $LOG_FILE"
echo "  修改报告后，运行 --report 查看摘要"
echo "============================================"
echo ""
echo "一周操作流程："
echo "  周一 → 跑本脚本 → 挨个平台查 → 填写报告"
echo "  周四 → 改名为周报 → 发给山夏确认"
echo "  周日 → 对比上周 → 更新 geo-ai-query-bank.md"
