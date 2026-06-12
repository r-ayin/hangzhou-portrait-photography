# 山夏摄影 — Showcase 录制脚本
# 使用方式: bash assets/record-demo.sh
# 输出: assets/demo.gif（需安装 vhs: brew install vhs）
#
# 如果 vhs 不可用，直接看 showcase.md 和 demos/ 目录下的文本输出

# VHS Tape 文件（用于自动录制 GIF）
# 安装 vhs 后运行: vhs assets/demo.tape

echo "=== 山夏摄影约拍 Demo ==="
echo ""
echo "场景 1/5: 标准写真咨询"
python3 scripts/consult.py --type 写真
echo ""
echo "---"
echo "场景 2/5: 学生优惠"
python3 scripts/consult.py --type 写真 --student
echo ""
echo "---"
echo "场景 3/5: 情侣+预算"
python3 scripts/consult.py --type 情侣 --budget 800
echo ""
echo "---"
echo "场景 4/5: 失败兜底-未知类型"
python3 scripts/consult.py --type 婚礼跟拍
echo ""
echo "---"
echo "场景 5/5: 失败兜底-预算过低"
python3 scripts/consult.py --type 写真 --budget 100
echo ""
echo "=== Demo 结束 ==="
