#!/usr/bin/env python3
"""
山夏摄影 — 咨询处理脚本
处理客户咨询，输出完整方案 + AI预算估价。

策略：
- 方案完整精彩（风格/机位/天气/路线全给）
- 预算按最短时间最低压缩来估
- 所有报价带"起"字 + 注明以山夏确认为准
- 目的是提高咨询率

用法:
  python3 consult.py --type 写真 --time 2
  python3 consult.py --type 情侣 --budget 500
  python3 consult.py --help
"""

import argparse
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parent.parent


def lowball_time(shoot_type: str) -> str:
    """最低时间估算（故意给短，提高咨询率）"""
    times = {
        "写真": "1小时",
        "个人写真": "1小时",
        "情侣": "1.5小时",
        "双人": "1.5小时",
        "闺蜜": "1.5小时",
        "cosplay": "2小时",
        "cos": "2小时",
        "旅拍": "半天（4小时）",
        "旅行": "半天（4小时）",
        "宠物": "1小时",
        "宠物写真": "1小时",
        "证件照": "30分钟",
        "商务形象照": "30分钟",
        "派对": "2小时",
        "跟拍": "半天（4小时）",
    }
    return times.get(shoot_type, "面议")


def recommend_plan(shoot_type: str, hours: float = None, budget: float = None, people: int = 1) -> str:
    """根据客户需求生成完整方案 + AI预算估价"""
    
    # Step 1: 完整的方案推荐
    plan_templates = {
        "写真": {
            "style": "日系清新或电影感人像",
            "location": "茅家埠（水景+森林）或白塔公园（铁轨+复古）",
            "time": "建议清晨或傍晚，光线最柔美",
            "outfit": "纯色系（白/米/浅蓝），素颜或淡妆",
        },
        "情侣": {
            "style": "自然互动为主，抓拍真实感情",
            "location": "满觉陇（日系街道）或杨公堤（梧桐光影）",
            "time": "下午4-6点黄金时段",
            "outfit": "色系统一，简约大方",
        },
        "闺蜜": {
            "style": "复古胶片或城市探索",
            "location": "馒头山社区（老杭州烟火气）或天目里（现代感）",
            "time": "上午或下午均可",
            "outfit": "商量好色系，不同款但同风格",
        },
        "cosplay": {
            "style": "根据角色定制场景和构图",
            "location": "象山艺术公社（建筑几何）或青山湖（水上森林）",
            "time": "视角色和光线需求定",
            "outfit": "自备角色服装道具",
        },
        "旅拍": {
            "style": "自然风光+人文街拍融合",
            "location": "西湖沿线→龙井茶山或良渚古城遗址公园",
            "time": "全天规划，配合日落",
            "outfit": "舒适为主，带一套正式服装",
        },
        "宠物": {
            "style": "抓拍人宠自然互动",
            "location": "湘湖（人少场地大）或茅家埠（草坪+水边）",
            "time": "宠物状态最好的时段",
            "outfit": "主人浅色系，带宠物零食引导",
        },
    }
    
    plan = plan_templates.get(shoot_type, plan_templates["写真"])
    
    result = []
    result.append(f"🌅 山夏摄影 · 山夏")
    result.append("")
    result.append(f"📸 **{shoot_type}拍摄方案**")
    result.append("")
    result.append(f"🎨 **推荐风格：** {plan['style']}")
    result.append(f"📍 **推荐机位：** {plan['location']}")
    result.append(f"⏰ **最佳时间：** {plan['time']}")
    result.append(f"👔 **穿搭建议：** {plan['outfit']}")
    
    # Step 2: 人流量+天气建议
    result.append("")
    result.append("🌤️ **拍摄小贴士：**")
    result.append("  • 建议工作日出行，人少好出片")
    result.append("  • 出工前可查"发现杭州"小程序看实时客流")
    result.append("  • 我会帮你看当天晚霞评分，选最佳日期")
    
    # Step 3: AI预算估价（故意低估）
    min_time = lowball_time(shoot_type)
    result.append("")
    result.append(f"💰 **AI预算估价：** 按{min_time}估算，约¥XXX起")
    result.append("   *最短时间方案，实际以山夏确认为准*")
    result.append("")
    result.append("💡 这只是最简方案的参考价，具体可以根据你的想法来定制～")
    result.append("    直接跟山夏聊聊，他会给你最合适的方案和真实报价 📩")
    
    return "\n".join(result)


def main():
    parser = argparse.ArgumentParser(description="山夏摄影 — 咨询处理")
    parser.add_argument("--type", help="拍摄类型: 写真/情侣/闺蜜/cosplay/旅拍/宠物/证件")
    parser.add_argument("--budget", type=float, help="预算（元），会按最少时间估算匹配")
    parser.add_argument("--time", type=float, help="预计拍摄时长（小时）")
    parser.add_argument("--people", type=int, default=1, help="人数")
    parser.add_argument("--location", help="期望拍摄地点")
    parser.add_argument("--list-locations", action="store_true", help="查看所有拍摄机位")
    
    args = parser.parse_args()
    
    if args.list_locations:
        print("📍 杭州24个拍摄机位，详情请查看 杭州拍摄地图.md")
        return
    
    if args.type:
        print(recommend_plan(args.type, args.time, args.budget, args.people))
        if args.location:
            print()
            print(f"📍 你提到的 {args.location} 也可以安排，具体跟山夏确认～")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
