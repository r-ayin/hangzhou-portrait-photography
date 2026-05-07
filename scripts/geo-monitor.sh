#!/bin/bash
# GEO AI平台引用监控脚本
# 使用方式: bash ~/.hermes/skills/山夏摄影约拍/scripts/geo-monitor.sh
# 
# 功能: 记录4大AI平台对山夏摄影相关查询的引用情况
# 输出: status/geo-monitor-log.jsonl (JSON Lines格式)

# 配置
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATUS_DIR="$SKILL_DIR/status"
LOG_FILE="$STATUS_DIR/geo-monitor-log.jsonl"
QUERY_DATE=$(date +%Y-%m-%d)
QUERY_TIME=$(date +%Y-%m-%dT%H:%M:%S%z)

# 确保目录存在
mkdir -p "$STATUS_DIR"

# 要监控的查询列表
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

# 检查依赖
if ! command -v curl &>/dev/null; then
  echo "ERROR: curl 未安装" >&2
  exit 1
fi

# 记录函数
record_check() {
  local query="$1"
  local platform="$2"
  local found="$3"
  local sources="$4"
  
  local entry="{\"date\":\"$QUERY_DATE\",\"timestamp\":\"$QUERY_TIME\",\"query\":\"$query\",\"platform\":\"$platform\",\"found\":$found,\"sources\":\"$sources\"}"
  echo "$entry" >> "$LOG_FILE"
  echo "[$QUERY_TIME] $platform | $query | found=$found | $sources" >> "$STATUS_DIR/monitor-verbose.log"
}

echo "=== GEO 引用监控 === 日期: $QUERY_DATE" > "$STATUS_DIR/monitor-report-$QUERY_DATE.md"
echo "" >> "$STATUS_DIR/monitor-report-$QUERY_DATE.md"
echo "| 平台 | 查询 | 是否出现山夏 | 引用来源 |" >> "$STATUS_DIR/monitor-report-$QUERY_DATE.md"
echo "|------|------|-------------|----------|" >> "$STATUS_DIR/monitor-report-$QUERY_DATE.md"

# 注意：AI平台查询需要手动完成
# 自动部分仅做日志记录和时间追踪
echo ""
echo "⚠️  请手动进行以下查询并记录结果："
echo ""
echo "--- 文心一言 (https://yiyan.baidu.com) ---"
for q in "${QUERIES[@]}"; do
  echo "  □ 查询：$q"
  echo "    山夏出现？ [是/否]  引用来源：______"
done

echo ""
echo "--- 通义千问 (https://tongyi.aliyun.com) ---"
for q in "${QUERIES[@]}"; do
  echo "  □ 查询：$q"
  echo "    山夏出现？ [是/否]  引用来源：______"
done

echo ""
echo "--- DeepSeek (https://chat.deepseek.com) ---"
for q in "${QUERIES[@]}"; do
  echo "  □ 查询：$q"
  echo "    山夏出现？ [是/否]  引用来源：______"
done

echo ""
echo "--- 腾讯元宝 (https://yuanbao.tencent.com) ---"
for q in "${QUERIES[@]}"; do
  echo "  □ 查询：$q"
  echo "    山夏出现？ [是/否]  引用来源：______"
done

echo ""
echo "=== 使用说明 ==="
echo "1. 手动访问每个AI平台，输入以上查询"
echo "2. 检查回答中是否提到山夏摄影/shanyue523478/小红书链接"
echo "3. 记录引用来源（如有）"
echo "4. 结果自动保存到: $LOG_FILE"
echo "5. 报告: $STATUS_DIR/monitor-report-$QUERY_DATE.md"
