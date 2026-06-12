#!/usr/bin/env python3
"""山夏摄影 — 问卷 JSON → Discord Embed 格式化器
被 submit-questionnaire.sh 复用，避免 inline Python 代码在 Shell 里重复两份。
也可被 submit-questionnaire.py 引用。
"""
import json
import sys


def format_embed(data: dict) -> dict:
    c = data.get("customer", {})
    p = data.get("practical", {})
    a = data.get("aesthetic_level", {})
    pers = data.get("personality", {})
    s = data.get("style_profile", {})
    notes = data.get("notes_for_shanxia", [])

    fields = []

    # 实用信息
    practical_lines = []
    for k, v, emoji in [
        ("photography_experience", "经验", "📷"),
        ("target_time", "目标", "📅"),
        ("photo_usage", "用途", "🎯"),
        ("budget", "预算", "💰"),
        ("mbti", "MBTI", "🧠"),
        ("confidence_outfit", "自信穿搭", "👗"),
        ("raw_photo_preference", "后期偏好", "🎨"),
        ("location_preference", "场地", "📍"),
    ]:
        val = p.get(k, "")
        if val and val not in ("未提供", "未讨论"):
            practical_lines.append(f"{emoji} {v}: {val}")
    if practical_lines:
        fields.append({"name": "📋 实用信息", "value": "\n".join(practical_lines), "inline": False})

    # 联系方式
    contact_lines = []
    cn = c.get("wechat_name", "") or c.get("name", "")
    if cn:
        contact_lines.append(f"💬 {cn}")
    if c.get("nickname") and c.get("nickname") != c.get("name", ""):
        contact_lines.append(f'✨ {c["nickname"]}')
    if c.get("wechat"):
        contact_lines.append(f'📱 微信: {c["wechat"]}')
    if c.get("phone"):
        contact_lines.append(f'📞 {c["phone"]}')
    if c.get("email"):
        contact_lines.append(f'📧 {c["email"]}')
    fields.append({
        "name": "📞 联系方式",
        "value": "\n".join(contact_lines) if contact_lines else "（未提供）",
        "inline": False,
    })

    # 审美等级
    aesthetic_text = (
        f'**L{a.get("level", "?")} · {a.get("level_name", "未知")}** '
        f'({a.get("score", "?")}/10)'
    )
    if a.get("key_signals"):
        aesthetic_text += f'\n信号: {a["key_signals"][:80]}'
    fields.append({
        "name": "🎨 审美等级",
        "value": aesthetic_text,
        "inline": True,
    })

    # 人物素养
    fields.append({
        "name": "🌱 人物素养",
        "value": f'**{pers.get("level", "未知")}**',
        "inline": True,
    })

    # 性格特征 — 解析轴值，输出可读方向标签
    axis_specs = [
        ("社交", pers.get("social_energy", ""), "内向", "外向"),
        ("沟通", pers.get("communication_style", ""), "感性", "理性"),
        ("冒险", pers.get("risk_tendency", ""), "谨慎", "冒险"),
        ("秩序", pers.get("order_preference", ""), "随性", "有序"),
        ("开放", pers.get("openness", ""), "传统", "探索"),
    ]
    axis_labels = []
    for label, raw, left_tag, right_tag in axis_specs:
        if not raw:
            continue
        dot_pos = max(raw.find("●"), raw.find("○"))
        if dot_pos < 0:
            axis_labels.append(f"{label}: {raw}")
            continue
        stripped = raw.strip()
        if len(stripped) < 3:
            axis_labels.append(f"{label}: {raw}")
            continue
        ratio = dot_pos / len(stripped)
        # 跳过 ←●→ 箭头格式（●永远在中间，无信息量）
        if "←" in stripped and "→" in stripped:
            continue
        if ratio < 0.30:
            direction = f"偏{left_tag}"
        elif ratio > 0.60:
            direction = f"偏{right_tag}"
        else:
            direction = "均衡"
        axis_labels.append(f"{label}: {direction}")
    
    if axis_labels:
        if len(axis_labels) <= 5:
            personality_text = " · ".join(axis_labels)
        else:
            personality_text = "\n".join(axis_labels)
    else:
        personality_text = "（未评估）"

    keywords = pers.get("keywords", [])
    if keywords:
        personality_text += f"\n\n🏷️ `{'` `'.join(keywords)}`"
    fields.append({"name": "🔥 性格特征", "value": personality_text, "inline": False})

    # 风格偏好
    style_lines = [
        f'方向: **{s.get("preferred_direction", "待定")}**',
        f'色调: {s.get("tone", "待定")}',
    ]
    excludes = s.get("excludes", [])
    if excludes:
        style_lines.append(f'❌ 排除: {" / ".join(excludes)}')
    if s.get("reference_consistency"):
        style_lines.append(f'参考图: 一致性 {s["reference_consistency"]}')
    fields.append({"name": "🎯 风格偏好", "value": "\n".join(style_lines), "inline": False})

    # 山夏备注
    if notes:
        fields.append({
            "name": "📝 山夏备注",
            "value": "\n".join(f"・{n}" for n in notes[:5]),
            "inline": False,
        })

    # AI 解读
    interpretation = data.get("interpretation", "")
    if interpretation:
        fields.append({
            "name": "🔍 AI 解读",
            "value": interpretation[:300],
            "inline": False,
        })

    # 规划建议
    planning = data.get("planning_advice", {})
    if planning:
        plan_lines = []
        if planning.get("communication"):
            plan_lines.append(f"💬 沟通: {planning['communication']}")
        if planning.get("shooting"):
            plan_lines.append(f"📷 拍摄: {planning['shooting']}")
        if planning.get("package"):
            plan_lines.append(f"📦 套餐: {planning['package']}")
        if planning.get("pricing_note"):
            plan_lines.append(f"💰 定价: {planning['pricing_note']}")
        if plan_lines:
            fields.append({
                "name": "📌 规划建议",
                "value": "\n".join(plan_lines),
                "inline": False,
            })

    return {
        "embeds": [{
            "title": f'📸 新客户 · {c.get("name", "未命名")}',
            "color": 0xE8967A,
            "fields": fields,
            "footer": {"text": f'来源: {data.get("source_agent", "未知")}'},
        }],
    }


if __name__ == "__main__":
    data = json.load(sys.stdin)
    print(json.dumps(format_embed(data), ensure_ascii=False))
