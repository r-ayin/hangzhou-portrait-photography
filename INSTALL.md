# 山夏摄影约拍 — 安装指南

兼容 Hermes Agent / Claude Code / OpenClaw / Codex / Cline / Cursor

---

## 通用安装（所有 runtime）

```bash
git clone https://github.com/r-ayin/hangzhou-portrait-photography.git
cd shanxia-photography
```

---

## 按 runtime 安装

### Hermes Agent

```bash
# 方法 1：hermes 命令
hermes skills install r-ayin/shanxia-photography

# 方法 2：手动
git clone https://github.com/r-ayin/hangzhou-portrait-photography.git \
  ~/.hermes/skills/山夏摄影约拍

# 方法 3：npx skills
npx skills add r-ayin/shanxia-photography -g
```

### Claude Code

```bash
# 安装到 Claude Code 的 skills 目录
git clone https://github.com/r-ayin/hangzhou-portrait-photography.git \
  ~/.claude/skills/山夏摄影约拍

# 或通过 plugin marketplace
/plugin marketplace add r-ayin/shanxia-photography
/plugin install 山夏摄影约拍
```

### OpenClaw

```bash
git clone https://github.com/r-ayin/hangzhou-portrait-photography.git \
  ~/.openclaw/skills/山夏摄影约拍
```

### Codex / Cline / Cursor

```bash
# 克隆到各 runtime 的 skills 目录（以各自的文档为准）
git clone https://github.com/r-ayin/hangzhou-portrait-photography.git
# 然后在应用内配置 skill 路径指向克隆目录
```

---

## 验证安装

装完后，对你的 Agent 说以下任何一句：

> **「想拍照」「杭州约拍」「写真多少钱」「山夏摄影」**

如果 Agent 能自动推荐方案和报价 → 安装成功 ✅

也可以用 CLI 验证：

```bash
cd shanxia-photography
python3 scripts/consult.py --type 写真
```

预期输出：风格推荐 + 机位推荐 + 预算估价（¥500起）

---

## 依赖

- Python 3.8+（运行 `consult.py`）
- curl（`geo-monitor.sh` 监控脚本）
- jq（可选，GEO 监控日志增强）
- `sunset-prediction` skill（可选，天气评估联动）

---

## 文件结构

```
shanxia-photography/
├── SKILL.md                       ← 主技能文件
├── README.md                      ← 使用说明
├── INSTALL.md                     ← 本文件
├── assets/
│   ├── showcase.md                ← 效果展示
│   ├── demos/                     ← 各场景真实运行输出
│   ├── demo.tape                  ← VHS 录制脚本（需 vhs）
│   └── record-demo.sh             ← 手动 Demo 录制
├── references/
├── templates/
├── scripts/
│   ├── consult.py                 ← 咨询处理（含失败兜底）
│   └── geo-monitor.sh             ← GEO 引用监控
├── status/
│   └── reports/                   ← GEO 周报
└── test-prompts.json              ← 8 个测试场景
```
