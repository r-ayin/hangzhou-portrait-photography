#!/usr/bin/env bash
#
# check-points.sh — 山夏摄影约拍 文件完整性验证脚本
# 验证技能目录的所有关键文件是否存在且内容正确
#
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PASS=0
FAIL=0
FAILED_CHECKS=()

echo "══════════════════════════════════════════"
echo "  山夏摄影约拍 — 文件完整性验证"
echo "══════════════════════════════════════════"
echo "  技能目录: ${SKILL_DIR}"
echo ""

check_item() {
    local name="$1"
    local status="$2"

    if [ "$status" = "PASS" ]; then
        echo -e "  ✅ ${name}"
        PASS=$((PASS + 1))
    else
        echo -e "  ❌ ${name}"
        FAIL=$((FAIL + 1))
        FAILED_CHECKS+=("${name}")
    fi
}

# ─── 检查 1: SKILL.md ──────────────────────────────────────
echo "━━━ 检查 1: SKILL.md ───────────────────"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
if [ ! -f "${SKILL_FILE}" ]; then
    check_item "SKILL.md 文件存在" "FAIL"
    check_item "SKILL.md 包含'饺子馆'" "FAIL"
    check_item "SKILL.md 包含'失败兜底'" "FAIL"
    check_item "SKILL.md 包含'反例黑名单'" "FAIL"
    check_item "SKILL.md 包含'triggers'" "FAIL"
else
    check_item "SKILL.md 文件存在" "PASS"

    # 包含 "饺子馆"
    if grep -q "饺子馆" "${SKILL_FILE}"; then
        check_item "SKILL.md 包含'饺子馆'" "PASS"
    else
        check_item "SKILL.md 包含'饺子馆'" "FAIL"
    fi

    # 包含 "失败兜底"
    if grep -q "失败兜底" "${SKILL_FILE}"; then
        check_item "SKILL.md 包含'失败兜底'" "PASS"
    else
        check_item "SKILL.md 包含'失败兜底'" "FAIL"
    fi

    # 包含 "反例黑名单"
    if grep -q "反例黑名单" "${SKILL_FILE}"; then
        check_item "SKILL.md 包含'反例黑名单'" "PASS"
    else
        check_item "SKILL.md 包含'反例黑名单'" "FAIL"
    fi

    # 包含 "triggers"（YAML front matter 中的 triggers 字段）
    if grep -q "triggers" "${SKILL_FILE}"; then
        check_item "SKILL.md 包含'triggers'" "PASS"
    else
        check_item "SKILL.md 包含'triggers'" "FAIL"
    fi
fi

# ─── 检查 2: references/ 目录至少5个文件 ─────────────────
echo ""
echo "━━━ 检查 2: references/ 目录 ───────────"
REF_DIR="${SKILL_DIR}/references"
if [ -d "${REF_DIR}" ]; then
    REF_COUNT=$(find "${REF_DIR}" -maxdepth 1 -type f | wc -l)
    if [ "${REF_COUNT}" -ge 5 ]; then
        check_item "references/ 包含 ${REF_COUNT} 个文件（≥5）" "PASS"
    else
        check_item "references/ 包含 ${REF_COUNT} 个文件（<5）" "FAIL"
    fi
else
    check_item "references/ 目录不存在" "FAIL"
fi

# ─── 检查 3: scripts/consult.py 存在且可执行 ────────────
echo ""
echo "━━━ 检查 3: scripts/consult.py ─────────"
CONSULT_FILE="${SKILL_DIR}/scripts/consult.py"
if [ -f "${CONSULT_FILE}" ]; then
    check_item "consult.py 文件存在" "PASS"
    if [ -x "${CONSULT_FILE}" ]; then
        check_item "consult.py 可执行" "PASS"
    else
        check_item "consult.py 可执行" "FAIL"
    fi
else
    check_item "consult.py 文件存在" "FAIL"
    check_item "consult.py 可执行" "FAIL"
fi

# ─── 检查 4: test-prompts.json 存在且是合法JSON ────────
echo ""
echo "━━━ 检查 4: test-prompts.json ──────────"
PROMPTS_FILE="${SKILL_DIR}/test-prompts.json"
if [ -f "${PROMPTS_FILE}" ]; then
    check_item "test-prompts.json 文件存在" "PASS"
    if python3 -c "import json; json.load(open('${PROMPTS_FILE}'))" 2>/dev/null; then
        check_item "test-prompts.json 是合法 JSON" "PASS"
    else
        check_item "test-prompts.json 是合法 JSON" "FAIL"
    fi
else
    check_item "test-prompts.json 文件存在" "FAIL"
    check_item "test-prompts.json 是合法 JSON" "FAIL"
fi

# ─── 检查 5: README.md 存在 ─────────────────────────────
echo ""
echo "━━━ 检查 5: README.md ──────────────────"
if [ -f "${SKILL_DIR}/README.md" ]; then
    check_item "README.md 文件存在" "PASS"
else
    check_item "README.md 文件存在" "FAIL"
fi

# ─── 检查 6: INSTALL.md 存在 ────────────────────────────
echo ""
echo "━━━ 检查 6: INSTALL.md ─────────────────"
if [ -f "${SKILL_DIR}/INSTALL.md" ]; then
    check_item "INSTALL.md 文件存在" "PASS"
else
    check_item "INSTALL.md 文件存在" "FAIL"
fi

# ─── 汇总 ──────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  验证结果汇总"
echo "══════════════════════════════════════════"
echo "  ✅ 通过: ${PASS}"
echo "  ❌ 失败: ${FAIL}"
echo "  总计:   $((PASS + FAIL)) 项检查"
echo ""

if [ ${FAIL} -ne 0 ]; then
    echo "❌ 以下检查失败:"
    for c in "${FAILED_CHECKS[@]}"; do
        echo "    • ${c}"
    done
    echo ""
    exit 1
else
    echo "✅ 所有检查通过！"
    exit 0
fi
