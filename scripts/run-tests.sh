#!/usr/bin/env bash
#
# run-tests.sh — 山夏摄影约拍 自动化测试脚本
# 运行所有 consult.py 参数组合 + 验证输出包含关键预期字符串
#
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONSULT="python3 ${SKILL_DIR}/scripts/consult.py"
PASS=0
FAIL=0
FAILED_TESTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_result() {
    local test_name="$1"
    local status="$2"
    if [ "$status" = "PASS" ]; then
        echo -e "  [${GREEN}PASS${NC}] ${test_name}"
        PASS=$((PASS + 1))
    else
        echo -e "  [${RED}FAIL${NC}] ${test_name}"
        FAIL=$((FAIL + 1))
        FAILED_TESTS+=("${test_name}")
    fi
}

run_test() {
    local test_name="$1"
    local args="$2"
    local expected="$3"
    local description="$4"

    echo ""
    echo "━━━ 测试: ${description} ━━━"
    echo "  命令: cd ${SKILL_DIR} && ${CONSULT} ${args}"

    local output
    output=$(cd "${SKILL_DIR}" && ${CONSULT} ${args} 2>&1) || true

    # 检查所有预期字符串是否都出现在输出中
    local all_found=true
    while IFS= read -r keyword; do
        if ! echo "${output}" | grep -qFi "${keyword}"; then
            all_found=false
            echo "  ✗ 未找到预期文本: \"${keyword}\""
        fi
    done <<< "$(echo -e "${expected}")"

    if [ "$all_found" = true ]; then
        print_result "${test_name}" "PASS"
    else
        print_result "${test_name}" "FAIL"
        echo "  ── 实际输出 ──"
        echo "${output}" | head -20
    fi
}

# ─── 测试用例 ──────────────────────────────────────────────

# Test 1: --help
run_test "help-01" "--help" \
    "山夏摄影" \
    "帮助信息显示"

# Test 2: --type 写真
run_test "type-portrait-01" "--type 写真" \
    "写真
¥500" \
    "标准写真咨询"

# Test 3: --type 写真 --student
run_test "type-student-01" "--type 写真 --student" \
    "$(printf "学生\n¥250")" \
    "学生优惠咨询"

# Test 4: --type 情侣 --budget 800
run_test "type-couple-budget-01" "--type 情侣 --budget 800" \
    "$(printf "情侣\n800")" \
    "情侣指定预算800"

# Test 5: --type 婚礼 （未知类型，兜底转人工）
run_test "type-wedding-01" "--type 婚礼" \
    "$(printf "转给山夏本人\n微信")" \
    "未知类型兜底转人工"

# Test 6: --list-locations
run_test "list-locations-01" "--list-locations" \
    "机位" \
    "列出拍摄机位"

# ─── 汇总 ──────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  测试结果汇总"
echo "══════════════════════════════════════════"
echo -e "  ${GREEN}PASS${NC}: ${PASS}"
echo -e "  ${RED}FAIL${NC}: ${FAIL}"
echo ""

if [ ${FAIL} -ne 0 ]; then
    echo -e "${RED}以下测试失败:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo "  • ${t}"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}所有测试通过！${NC}"
    exit 0
fi
