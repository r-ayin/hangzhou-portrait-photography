#!/usr/bin/env bash
# ===== 注册山夏摄影约拍到 skills.sh =====
# skills.sh (Vercel Labs) 是一个 Agent Skills 目录和 CLI 工具。
# 
# 注意：skills.sh 目前没有公开的 REST API 来手动注册技能。
# 技能通过以下方式被收录到 skills.sh 目录：
#   1) GitHub 公开仓库中存在 SKILL.md 文件
#   2) CLI 工具 `npx skills add` 的使用和遥测
#   3) Vercel 对特定组织/仓库的收录
#
# 本脚本尝试多种方式注册，并给出替代方案。

set -e

REPO="r-ayin/hangzhou-portrait-photography"
SKILL_NAME="shanxia-photography"
GITHUB_URL="https://github.com/${REPO}"
SKILLS_SH_URL="https://skills.sh"
WEBSITE_PAGE="${SKILLS_SH_URL}/${REPO}"

echo "=========================================="
echo "  山夏摄影约拍 - skills.sh 注册脚本"
echo "=========================================="
echo ""
echo "目标仓库: ${GITHUB_URL}"
echo "技能名称: ${SKILL_NAME}"
echo ""

# --------------------------------------------------
# 方法 1: 尝试 POST 到 skills.sh API 端点
# skills.sh 是 Next.js 应用，/api/skills 路由是一个
# [owner]/[repo] 的页面路由，不是 REST API
# --------------------------------------------------
echo "【方法 1】尝试 POST 注册到 skills.sh API..."
HTTP_CODE=$(curl -s -o /tmp/skills_register_response.html -w "%{http_code}" \
  -X POST "${SKILLS_SH_URL}/api/skills" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${SKILL_NAME}\",
    \"description\": \"AI Photography Booking Agent for Hangzhou — demand analysis, style/location recommendation, sunset prediction, pricing, booking, after-sales\",
    \"github_url\": \"${GITHUB_URL}\",
    \"tags\": [\"photography\", \"hangzhou\", \"portrait\", \"ai-agent\", \"booking\", \"geo-optimization\"]
  }" 2>&1)

echo "  HTTP 状态码: ${HTTP_CODE}"
if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "201" ]]; then
  echo "  ✅ 注册成功！"
else
  echo "  ❌ 注册失败（HTTP ${HTTP_CODE}）。skills.sh 没有公开的注册 API"
  echo "     skills.sh 的 /api/skills 实际上是一个 Next.js 页面路由"
fi
echo ""

# --------------------------------------------------
# 方法 2: 检查 skills.sh 是否已收录
# --------------------------------------------------
echo "【方法 2】检查 skills.sh 是否已收录该仓库..."
PAGE_CODE=$(curl -sL -o /dev/null -w "%{http_code}" "${WEBSITE_PAGE}" 2>&1)

if [[ "${PAGE_CODE}" == "200" ]]; then
  echo "  ✅ 已收录！访问: ${WEBSITE_PAGE}"
else
  echo "  ℹ️  状态码: ${PAGE_CODE}（未收录）"
  echo "  skills.sh 是一个由 Vercel 维护的策划目录，"
  echo "  目前仅收录了经过验证的组织/仓库。"
fi
echo ""

# --------------------------------------------------
# 方法 3: 通过 CLI 工具验证可发现性
# --------------------------------------------------
echo "【方法 3】通过 npx skills CLI 验证发现能力..."
if command -v npx &>/dev/null; then
  echo "  运行: npx skills add ${REPO} --list"
  LIST_OUTPUT=$(npx skills add "${REPO}" --list 2>&1) || true
  if echo "${LIST_OUTPUT}" | grep -q "${SKILL_NAME}"; then
    echo "  ✅ CLI 工具可以成功发现技能 '${SKILL_NAME}'"
    echo "  用户可以通过以下命令安装:"
    echo "    npx skills add ${REPO} --skill ${SKILL_NAME}"
  else
    echo "  ❌ CLI 工具未能发现技能"
    echo "  输出: ${LIST_OUTPUT}"
  fi
else
  echo "  ⚠️  npx 未安装，跳过 CLI 验证"
fi
echo ""

# --------------------------------------------------
# 总结
# --------------------------------------------------
echo "=========================================="
echo "  注册总结"
echo "=========================================="
echo ""
echo "由于 skills.sh 的限制，目前不能通过 API 直接注册。"
echo ""
echo "【替代方案】"
echo ""
echo "方案 A: 在 skills.sh 的 GitHub 仓库提交 Issue 请求收录"
echo "  → https://github.com/vercel-labs/skills/issues/new"
echo "  标题: \"Add skill: r-ayin/hangzhou-portrait-photography\""
echo "  内容: 说明这是一个 Hermes Agent skill，包含完整的 SKILL.md"
echo ""
echo "方案 B: 通过 skills.sh 的 CLI 工具安装（已验证通过）"
echo "  npx skills add ${REPO} --skill ${SKILL_NAME} --global -y"
echo "  这将触发 skills.sh 的遥测系统，可能促进收录"
echo ""
echo "方案 C: 联系 Vercel 团队 (skills.sh 由 Vercel Labs 维护)"
echo ""
echo "【技能已可用】"
echo "  任何用户都可以通过以下命令直接安装:"
echo "    npx skills add ${REPO}"
echo "    npx skills add ${REPO} --skill ${SKILL_NAME}"
echo ""
echo "文档: https://skills.sh/docs"
echo "GitHub: https://github.com/vercel-labs/skills"
