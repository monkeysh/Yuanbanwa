#!/usr/bin/env python3
"""
Seed 22 new scenes into scenes.json (total becomes 30).

Adds the 学校 category if missing. Each scene below uses a compact
representation (title, level, sentences = list of (en, zh, weak_indexes)).
The script tokenizes each English sentence using the same rules as the
existing scenes so weak indexes line up with rendered words.

Idempotent: reruns skip scenes whose id is already in the catalog.

Run:
    python3 scripts/seed-new-scenes.py
"""

from __future__ import annotations
import json
import re
import sys
from pathlib import Path

SCENES_JSON = Path(__file__).resolve().parent.parent / "Speak" / "Resources" / "scenes.json"


# Tokenizer mirrors the one we used for the first 8 scenes:
# - split on whitespace
# - strip trailing punctuation `.?!,;:`
# - keep inner apostrophes + hyphens
def tokenize(sentence: str) -> list[str]:
    words = []
    for raw in sentence.split():
        # Strip trailing punctuation repeatedly (handles "…hot.").
        w = raw
        while w and w[-1] in ".?!,;:\"":
            w = w[:-1]
        # Strip leading quote if any.
        while w and w[0] in "\"":
            w = w[1:]
        if w:
            words.append(w)
    return words


SCENES_NEW = [
    # ─────────── 出行 (7 new) ───────────
    {
        "id": "hotel-checkout", "kind": "travel", "category": "travel",
        "title": "酒店退房", "subtitle": "Hotel check-out",
        "level": "初级", "minutes": 4,
        "description": "早上退房前台交钥匙、核对账单、寄存行李的 7 句常用表达。",
        "learn": ["要求退房 / 还卡", "核对账单、发现错误", "寄存行李到下午", "礼貌收尾"],
        "sentences": [
            ("Could I check out, please?", "可以办理退房吗？", [0]),
            ("Here's the key card.", "这是房卡", []),
            ("Here's my room number.", "这是我的房间号", []),
            ("Could you explain the bill?", "能帮我看一下账单吗？", [3]),
            ("There seems to be a mistake here.", "这里好像有个错误", [4]),
            ("Could I leave my luggage here until 5?", "能把行李寄存到 5 点吗？", [4]),
            ("Thanks for the stay.", "谢谢招待", []),
        ],
    },
    {
        "id": "airport-checkin", "kind": "travel", "category": "travel",
        "title": "机场值机", "subtitle": "Airport check-in",
        "level": "初级", "minutes": 4,
        "description": "到航空公司柜台办理登机牌、问座位、问登机信息。",
        "learn": ["说航班号值机", "要靠窗 / 靠过道座位", "问是否准点、登机口", "问登机时间"],
        "sentences": [
            ("Hi, I'm checking in for flight UA857.", "你好，我办理 UA857 航班的值机", [3]),
            ("Here's my passport.", "这是我的护照", [2]),
            ("I have one bag to check.", "我有一个行李要托运", [5]),
            ("Could I have a window seat?", "能安排靠窗的座位吗？", [4]),
            ("Is my flight on time?", "航班准点吗？", []),
            ("Which gate is it?", "在哪个登机口？", [1]),
            ("When does boarding start?", "什么时候开始登机？", [2]),
            ("Thanks so much.", "非常感谢", []),
        ],
    },
    {
        "id": "baggage", "kind": "travel", "category": "travel",
        "title": "托运行李", "subtitle": "Checking luggage",
        "level": "初级", "minutes": 4,
        "description": "柜台托运行李时，重量、超重费、易碎品、随身的 7 句话。",
        "learn": ["说明托运件数", "问重量限制 / 超重费", "标注易碎品", "问提取位置"],
        "sentences": [
            ("I have two bags to check.", "我有两件行李要托运", [4]),
            ("Is there a weight limit?", "有重量限制吗？", [3]),
            ("How much do I have to pay for extra weight?", "超重的话多少钱？", [8]),
            ("This one is fragile, please.", "这件易碎，谢谢", [3]),
            ("Could I take this as a carry-on?", "这件能当随身行李吗？", [6]),
            ("Where do I pick them up?", "去哪里取行李？", [3]),
            ("Thank you.", "谢谢", []),
        ],
    },
    {
        "id": "gate", "kind": "travel", "category": "travel",
        "title": "找登机口", "subtitle": "Finding the gate",
        "level": "初级", "minutes": 3,
        "description": "机场找登机口、问登机进度、确认位置。",
        "learn": ["问登机口位置", "问是否已开始登机", "确认到对", "问附近卫生间"],
        "sentences": [
            ("Excuse me, where is gate B12?", "打扰一下，B12 登机口在哪？", [3]),
            ("Has boarding started yet?", "开始登机了吗？", [1]),
            ("Am I at the right gate?", "我在正确的登机口吗？", [4]),
            ("How long until boarding?", "离登机还多久？", [3]),
            ("Is there a bathroom nearby?", "附近有卫生间吗？", [3]),
            ("Thanks for your help.", "谢谢你的帮助", []),
        ],
    },
    {
        "id": "customs", "kind": "travel", "category": "travel",
        "title": "过海关", "subtitle": "Immigration & customs",
        "level": "中级", "minutes": 4,
        "description": "海关官员问话，如实回答身份 / 停留时间 / 目的 / 住处。",
        "learn": ["回答入境目的", "说停留时长", "说明住宿地", "回报税申报"],
        "sentences": [
            ("Here's my passport.", "这是我的护照", [2]),
            ("I'm here for tourism.", "我是来旅游的", [3]),
            ("I'll stay for about one week.", "我大概待一周", [5]),
            ("I'm staying at a hotel.", "我住酒店", [4]),
            ("This is my first visit.", "这是我第一次来", [3]),
            ("I have nothing to declare.", "没有需要申报的", [4]),
            ("Here's my return ticket.", "这是回程机票", [2]),
            ("Thank you, have a good day.", "谢谢，祝您愉快", []),
        ],
    },
    {
        "id": "subway", "kind": "travel", "category": "travel",
        "title": "坐地铁", "subtitle": "Taking the subway",
        "level": "初级", "minutes": 4,
        "description": "陌生城市坐地铁，问线路、票价、站台、到站提醒。",
        "learn": ["问线路怎么走", "问单程票 / 日票价格", "确认站台", "问要坐几站"],
        "sentences": [
            ("Which line goes to Times Square?", "去时代广场坐哪条线？", [4]),
            ("How much is a single ticket?", "单程票多少钱？", [4]),
            ("Do you sell day passes?", "有日票吗？", [4]),
            ("Is this the right platform?", "我站对站台了吗？", [4]),
            ("Which stop should I get off?", "我该在哪站下？", [1]),
            ("How many stops is that?", "总共几站？", [2]),
            ("Thanks a lot.", "非常感谢", []),
        ],
    },
    {
        "id": "delivery", "kind": "travel", "category": "travel",
        "title": "点外卖", "subtitle": "Ordering delivery",
        "level": "初级", "minutes": 4,
        "description": "电话或 APP 点外卖，告诉地址、问素食选项、给小费。",
        "learn": ["开口下外卖订单", "问是否有素食选项", "说送达时间 / 地址", "交代放门口 + 小费"],
        "sentences": [
            ("I'd like to place a delivery order.", "我想点一个外卖", [5]),
            ("Could I get two pepperoni pizzas?", "来两份意式辣香肠披萨", [4]),
            ("Do you have any vegetarian options?", "有素食选项吗？", [5]),
            ("How long will the delivery take?", "大概多久送到？", [5]),
            ("What's the delivery fee?", "配送费多少？", [2]),
            ("My address is 123 Main Street.", "我的地址是 Main 街 123 号", [1]),
            ("Could you leave it at the door?", "能放在门口吗？", [3]),
            ("Thanks, I'll tip in the app.", "谢谢，我在 app 里给小费", [3]),
        ],
    },

    # ─────────── 生活 (4 new) ───────────
    {
        "id": "phone-call", "kind": "life", "category": "life",
        "title": "电话开场", "subtitle": "Answering a call",
        "level": "初级", "minutes": 3,
        "description": "接起商务电话的 7 句通用开场。",
        "learn": ["自报姓名接电话", "问对方身份 / 来意", "要求重复或说大声点", "收尾致谢"],
        "sentences": [
            ("Hi, this is Nova speaking.", "你好，我是 Nova", [3]),
            ("Who's calling, please?", "请问您是哪位？", [1]),
            ("Could I ask what this is about?", "可以问下是什么事吗？", [2]),
            ("Sorry, could you speak up a bit?", "抱歉，能说大声一点吗？", [3]),
            ("Let me write that down.", "我记一下", [2]),
            ("Could you repeat that?", "能再说一遍吗？", [2]),
            ("Thanks for calling.", "谢谢来电", []),
        ],
    },
    {
        "id": "appointment", "kind": "life", "category": "life",
        "title": "预约时间", "subtitle": "Booking an appointment",
        "level": "初级", "minutes": 3,
        "description": "预约牙医 / 理发 / 美甲等服务，定时间、改时间。",
        "learn": ["开口预约", "说可选时间", "改期 / 问取消费", "礼貌收尾"],
        "sentences": [
            ("I'd like to book an appointment.", "我想预约一个时间", [3]),
            ("Do you have anything next week?", "下周有空档吗？", [3]),
            ("Monday afternoon works for me.", "周一下午可以", [0]),
            ("Around 3 PM if possible.", "下午 3 点左右", [4]),
            ("Could I reschedule that to Friday?", "能改到周五吗？", [2]),
            ("Is there a cancellation fee?", "取消有费用吗？", [3]),
            ("Thank you, see you then.", "谢谢，到时见", []),
        ],
    },
    {
        "id": "price-check", "kind": "life", "category": "life",
        "title": "购物问价", "subtitle": "Asking about prices",
        "level": "初级", "minutes": 3,
        "description": "店里问价、问折扣、问尺码、试穿、刷卡。",
        "learn": ["开口问价", "问是否打折", "问有没有小 / 大尺码", "试穿 + 结账"],
        "sentences": [
            ("Excuse me, how much is this?", "打扰一下，这个多少钱？", [1]),
            ("Is it on sale?", "在打折吗？", [3]),
            ("Do you have a smaller size?", "有小一号的吗？", [4]),
            ("Do you accept international cards?", "可以刷国际卡吗？", [3]),
            ("Could I try this on?", "能试穿一下吗？", [2]),
            ("I'll take it, thank you.", "我要了，谢谢", []),
        ],
    },
    {
        "id": "pharmacy", "kind": "life", "category": "life",
        "title": "药店买药", "subtitle": "At the pharmacy",
        "level": "中级", "minutes": 4,
        "description": "描述症状买 OTC 药，问服用方法、副作用。",
        "learn": ["说感冒 / 咳嗽症状", "问有没有相应药", "问服用频率 / 是否随餐", "问是否含嗜睡成分"],
        "sentences": [
            ("Excuse me, I have a bad cough.", "打扰一下，我咳嗽很严重", [4]),
            ("Do you have anything for it?", "有对症的药吗？", [3]),
            ("I also have a sore throat.", "我嗓子也疼", [5]),
            ("Is this safe to take with food?", "这个随餐吃安全吗？", [2]),
            ("How often should I take it?", "多久吃一次？", [1]),
            ("Is there anything non-drowsy?", "有不含嗜睡成分的吗？", [3]),
            ("Thanks, how much is it?", "谢谢，多少钱？", []),
        ],
    },

    # ─────────── 学校 (3 new) ───────────
    {
        "id": "parent-meeting", "kind": "school", "category": "school",
        "title": "家长会开场", "subtitle": "Meeting the teacher",
        "level": "中级", "minutes": 4,
        "description": "家长会上和老师的自我介绍 + 感谢 + 询问开场。",
        "learn": ["自我介绍作为某某的家长", "感谢老师抽时间", "表达期待", "礼貌开启对话"],
        "sentences": [
            ("Hi, I'm Nova's parent.", "你好，我是 Nova 的家长", [2]),
            ("Nice to finally meet you.", "终于见到您了", [2]),
            ("Thanks for making time for us.", "谢谢您抽时间", [2]),
            ("We've been looking forward to this.", "我们一直期待这次见面", [3]),
            ("How has Nova been doing?", "Nova 表现怎么样？", [3]),
            ("Is there anything we should know?", "有什么我们需要了解的吗？", [2]),
            ("We appreciate your patience.", "感谢您的耐心", [1]),
        ],
    },
    {
        "id": "teacher-conference", "kind": "school", "category": "school",
        "title": "问老师孩子情况", "subtitle": "Asking about your child",
        "level": "中级", "minutes": 5,
        "description": "和班主任深聊孩子的学习、社交、阅读进度、建议。",
        "learn": ["问课堂表现和参与度", "问薄弱学科", "问社交与同学关系", "问家里怎么配合"],
        "sentences": [
            ("How is Nova doing in class?", "Nova 在课堂上怎么样？", [2]),
            ("Does she participate enough?", "她参与度够吗？", [2]),
            ("Are there subjects she's struggling with?", "有哪些科目她比较吃力？", [5]),
            ("What should we work on at home?", "在家应该练什么？", [2]),
            ("How does she get along with classmates?", "她和同学处得怎么样？", [6]),
            ("Is her reading on track?", "她的阅读进度跟得上吗？", [2]),
            ("How can we support her at home?", "在家我们怎么支持她？", [3]),
            ("Thank you so much.", "非常感谢", []),
        ],
    },
    {
        "id": "sick-leave", "kind": "school", "category": "school",
        "title": "请假说明", "subtitle": "Calling in sick",
        "level": "初级", "minutes": 3,
        "description": "打电话 / 消息告诉学校孩子今天不能去。",
        "learn": ["自报孩子姓名 + 年级", "说明不来 + 症状", "预计返校时间", "请老师知晓"],
        "sentences": [
            ("Hi, I'm calling about Nova in grade 3.", "你好，我想说下三年级 Nova 的事", [3]),
            ("She won't be coming in today.", "她今天不能到校", [4]),
            ("She has a fever and a sore throat.", "她发烧，嗓子疼", [3]),
            ("She should be back on Monday.", "她周一应该就能回来", [2]),
            ("Could you let her teacher know?", "麻烦告诉她老师一下", [4]),
            ("Thanks very much.", "非常感谢", []),
        ],
    },

    # ─────────── 社交 (5 new) ───────────
    {
        "id": "first-meeting", "kind": "social", "category": "social",
        "title": "初次见面寒暄", "subtitle": "First time meeting",
        "level": "初级", "minutes": 4,
        "description": "聚会 / 活动第一次跟陌生人聊起来的 8 句话。",
        "learn": ["自我介绍开场", "问对方和主人的关系 / 职业", "交换联系方式", "礼貌告别"],
        "sentences": [
            ("Hi, I don't think we've met.", "你好，我们应该没见过", [4]),
            ("I'm Nova, nice to meet you.", "我是 Nova，很高兴认识你", [1]),
            ("How do you know the host?", "你怎么认识主人的？", [5]),
            ("What do you do for a living?", "你做什么工作？", [6]),
            ("Where are you from originally?", "你老家是哪里的？", [4]),
            ("What brings you here today?", "你今天怎么过来的？", [1]),
            ("Let's exchange contacts.", "我们加个联系方式", [1]),
            ("Hope to see you again soon.", "希望很快再见", [0]),
        ],
    },
    {
        "id": "thanks", "kind": "social", "category": "social",
        "title": "表达感谢", "subtitle": "Expressing thanks",
        "level": "初级", "minutes": 3,
        "description": "各种场合表达感谢的 7 种说法 —— 从日常到深情。",
        "learn": ["普通感谢到由衷感谢的梯度", "加强感谢语气", "表达意义深远", "收尾加倍感谢"],
        "sentences": [
            ("Thank you so much.", "非常感谢", []),
            ("I really appreciate it.", "真的感谢你", [2]),
            ("You've been so kind.", "你太好了", [0]),
            ("This means a lot to me.", "这对我很重要", [1]),
            ("I don't know what to say.", "我都不知道说什么好", []),
            ("I owe you one.", "欠你一次人情", [1]),
            ("Thanks again, truly.", "再次感谢", [2]),
        ],
    },
    {
        "id": "apology", "kind": "social", "category": "social",
        "title": "礼貌道歉", "subtitle": "A sincere apology",
        "level": "初级", "minutes": 3,
        "description": "迟到、出错、打扰后的 7 种自然道歉表达。",
        "learn": ["直接表达歉意", "承认不是故意", "让对方等的道歉", "承诺不再发生"],
        "sentences": [
            ("I'm so sorry for the delay.", "非常抱歉我迟到了", [4]),
            ("My bad, I didn't mean to.", "是我不好，不是故意的", []),
            ("Could I apologize?", "我能向你道歉吗？", [2]),
            ("Sorry to keep you waiting.", "抱歉让你久等了", [4]),
            ("I hope I didn't offend you.", "希望我没冒犯到你", [4]),
            ("It won't happen again.", "不会再发生了", [2]),
            ("Thanks for understanding.", "谢谢理解", [2]),
        ],
    },
    {
        "id": "decline", "kind": "social", "category": "social",
        "title": "礼貌拒绝", "subtitle": "Politely declining",
        "level": "中级", "minutes": 4,
        "description": "婉拒邀请或请求的 7 种不尴尬说法。",
        "learn": ["柔和表达无法参与", "肯定对方 + 推理由", "留下次机会", "收尾表示感谢"],
        "sentences": [
            ("Thank you, but I can't make it.", "谢谢你，但我去不了", [5]),
            ("That's really kind of you.", "你真的很贴心", [1]),
            ("I'd love to, but I'm swamped this week.", "我想去，但这周太忙了", [5]),
            ("Maybe next time?", "下次吧？", [0]),
            ("I don't think it's a good fit for me.", "可能不太适合我", []),
            ("I appreciate you asking.", "谢谢你来问我", [1]),
            ("No worries, next time for sure.", "没事，下次一定", [1]),
        ],
    },
    {
        "id": "ask-help", "kind": "social", "category": "social",
        "title": "请求帮助", "subtitle": "Asking for help",
        "level": "初级", "minutes": 3,
        "description": "向陌生人 / 同事开口求助的 6 句常用话。",
        "learn": ["礼貌开场 Excuse me", "说明不太会", "请对方演示", "致谢"],
        "sentences": [
            ("Excuse me, could you help me?", "打扰一下，能帮我一下吗？", []),
            ("Could I bother you for a moment?", "能打扰你一下吗？", [2]),
            ("I'm not sure how this works.", "我不确定这个怎么用", [2]),
            ("Could you show me?", "能演示一下吗？", [2]),
            ("I really appreciate your time.", "非常感谢你的时间", [2]),
            ("Thanks so much.", "非常感谢", []),
        ],
    },

    # ─────────── 紧急 (3 new) ───────────
    {
        "id": "lost", "kind": "urgent", "category": "urgent",
        "title": "丢东西求助", "subtitle": "Lost something",
        "level": "中级", "minutes": 4,
        "description": "丢了护照 / 钱包 / 手机后向人求助的 8 句话。",
        "learn": ["说明丢失物品 + 最后出现的地方", "问失物招领", "借电话联系酒店", "问警察局位置"],
        "sentences": [
            ("Excuse me, I need some help.", "打扰一下，我需要帮助", [3]),
            ("I think I lost my passport.", "我好像把护照弄丢了", [5]),
            ("I last had it at the restaurant.", "最后是在餐厅用过", [6]),
            ("Could I look in the lost and found?", "我能看下失物招领吗？", [5]),
            ("Could I borrow your phone to call my hotel?", "能借手机打给酒店吗？", [8]),
            ("Is there a police station nearby?", "附近有警察局吗？", [3]),
            ("Who should I report this to?", "我该向谁报案？", [3]),
            ("Thank you for your help.", "谢谢你的帮助", []),
        ],
    },
    {
        "id": "police", "kind": "urgent", "category": "urgent",
        "title": "找警察帮忙", "subtitle": "Asking police for help",
        "level": "中级", "minutes": 4,
        "description": "走向警察，报告手机被偷、备案、问时长。",
        "learn": ["礼貌开场 officer", "说明事件 + 时间 + 地点", "申请报案", "问手续所需"],
        "sentences": [
            ("Excuse me, officer.", "打扰一下，警官", [2]),
            ("I'd like to report something.", "我想报告一件事", [3]),
            ("My phone was stolen on the bus.", "我的手机在公交上被偷了", [3]),
            ("It happened about 20 minutes ago.", "大约 20 分钟前发生的", [1]),
            ("Could I file a report?", "我能报案吗？", [4]),
            ("Do you need my passport?", "需要我的护照吗？", [4]),
            ("How long will this take?", "大概要多久？", [2]),
            ("Thanks for your help.", "谢谢您的帮助", []),
        ],
    },
    {
        "id": "emergency-call", "kind": "urgent", "category": "urgent",
        "title": "紧急电话", "subtitle": "Calling emergency services",
        "level": "中级", "minutes": 3,
        "description": "打 911 / 112 报事故，传达位置、伤情、跟线。",
        "emotion": "紧急但不慌乱 —— 把关键信息说清楚就够了。",
        "learn": ["开口说发生事故", "报坐标 / 地址", "说伤情状态", "请求保持通话"],
        "sentences": [
            ("There's been an accident.", "发生事故了", [3]),
            ("I need an ambulance.", "我需要救护车", [3]),
            ("I'm on 5th Avenue near 42nd Street.", "我在第五大道靠近 42 街", [3]),
            ("There's one person hurt.", "一个人受伤了", [3]),
            ("He's breathing but not moving.", "他还在呼吸但不动了", [1]),
            ("I'll stay on the line.", "我会保持通话", [3]),
            ("Please hurry.", "请快点", []),
        ],
    },
]


def build_sentence(en: str, zh: str, weak: list[int]) -> dict:
    words = tokenize(en)
    # Sanity: weak indexes should all be in range.
    for w in weak:
        if w < 0 or w >= len(words):
            raise SystemExit(f"Weak index {w} out of range for: {en!r} → {words}")
    return {"en": en, "zh": zh, "words": words, "weak": weak}


def build_scene(spec: dict) -> dict:
    sentences = [build_sentence(en, zh, weak) for en, zh, weak in spec["sentences"]]
    scene = {
        "id": spec["id"],
        "kind": spec["kind"],
        "category": spec["category"],
        "title": spec["title"],
        "subtitle": spec["subtitle"],
        "level": spec["level"],
        "minutes": spec["minutes"],
        "sentenceCount": len(sentences),
        "progress": 0,
        "isNew": True,
        "isFeatured": False,
        "description": spec["description"],
        "learn": spec["learn"],
        "sentences": sentences,
    }
    return scene


def ensure_school_category(catalog: dict) -> None:
    existing = {c["key"] for c in catalog["categories"]}
    if "school" in existing:
        return
    # Insert 学校 right after 社交 so the order reads: 全部 · 生活 · 出行 · 社交 · 学校 · 紧急
    new_cats = []
    inserted = False
    for c in catalog["categories"]:
        new_cats.append(c)
        if not inserted and c["key"] == "social":
            new_cats.append({"key": "school", "label": "学校"})
            inserted = True
    if not inserted:
        new_cats.append({"key": "school", "label": "学校"})
    catalog["categories"] = new_cats


def main():
    catalog = json.loads(SCENES_JSON.read_text(encoding="utf-8"))
    ensure_school_category(catalog)

    existing_ids = {s["id"] for s in catalog["scenes"]}
    added = 0
    skipped = 0
    for spec in SCENES_NEW:
        if spec["id"] in existing_ids:
            skipped += 1
            continue
        catalog["scenes"].append(build_scene(spec))
        added += 1

    SCENES_JSON.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    total = len(catalog["scenes"])
    total_sentences = sum(len(s["sentences"]) for s in catalog["scenes"])
    print(f"Added {added} scenes · skipped {skipped} (already present).")
    print(f"Catalog now: {total} scenes · {total_sentences} sentences.")


if __name__ == "__main__":
    main()
