#!/usr/bin/env python3
"""
Add 4-tier content (入门/初级/中级/高级) to 6 pilot scenes.

For each pilot scene, the existing top-level `sentences` list is wrapped
as the 初级 tier; new sentences are written for 入门 / 中级 / 高级 here.

The JSON schema becomes (additive — non-pilot scenes are untouched):

    {
      "id": "self-intro",
      "tiers": [
        {"level": "entry",        "label": "入门", "sentences": [...]},
        {"level": "beginner",     "label": "初级", "sentences": [...]},  # was scene.sentences
        {"level": "intermediate", "label": "中级", "sentences": [...]},
        {"level": "advanced",     "label": "高级", "sentences": [...]},
      ],
      // top-level "sentences" + "sentenceCount" are kept for back-compat
      // with scenes that don't have tiers yet
    }

Run:
    python3 scripts/seed-tiers.py
"""

from __future__ import annotations
import json
import re
import sys
from pathlib import Path

SCENES_JSON = Path(__file__).resolve().parent.parent / "Speak" / "Resources" / "scenes.json"

PILOT_SCENE_IDS = [
    "self-intro",
    "restaurant",
    "hotel",
    "first-meeting",
    "decline",
    "teacher-conference",
]

# Tokenizer mirrors the rest of the seed scripts: split on whitespace,
# strip end punctuation, keep contractions.
def tokenize(sentence: str) -> list[str]:
    words = []
    for raw in sentence.split():
        w = raw
        while w and w[-1] in ".?!,;:\"":
            w = w[:-1]
        while w and w[0] in "\"":
            w = w[1:]
        if w:
            words.append(w)
    return words


def sent(en: str, zh: str, weak: list[int]) -> dict:
    words = tokenize(en)
    for w in weak:
        if w < 0 or w >= len(words):
            raise SystemExit(f"Weak index {w} out of range for: {en!r} → {words}")
    return {"en": en, "zh": zh, "words": words, "weak": weak}


# ─────────────────────────────────────────────────────────────────
# Pilot content
#
# Difficulty calibration we're using:
#   入门 (Entry / pre-A1)  : 4-6 句, 2-5 words each, ultra-basic
#   初级 (Beginner / A1-A2): 7-10 句 (existing content)
#   中级 (Intermediate /B1): 9-10 句, 7-12 words, modals + past + plans
#   高级 (Advanced / B2-C1): 11 句, 10-15 words, idiomatic + register
#
# 专家 (C2) intentionally omitted — user feedback was that it's overkill
# for this product's audience (parents / casual learners). Can layer in
# later if pro/business segment opens up.
# ─────────────────────────────────────────────────────────────────

ENTRY = "entry"
BEGINNER = "beginner"
INTERMEDIATE = "intermediate"
ADVANCED = "advanced"

LABEL_FOR = {
    ENTRY: "入门",
    BEGINNER: "初级",
    INTERMEDIATE: "中级",
    ADVANCED: "高级",
}

# Non-pilot scenes — for the scenes_json migration we wrap their existing
# `sentences` list as a single 初级 tier so the iOS code only ever has to
# deal with the tier structure. Pilot scenes get all four tiers below.

PILOT_TIERS: dict[str, dict[str, list[dict]]] = {
    # ─── Scene 1: 自我介绍 ───────────────────────────────────────
    "self-intro": {
        # 入门 = 走廊 / 楼道偶遇邻居或同事的过路寒暄。完全独立于派对介绍那套。
        ENTRY: [
            sent("Hi there!",                    "嗨，你好",              []),
            sent("How's it going?",              "最近怎么样？",          [2]),
            sent("Pretty good, you?",            "还不错，你呢？",        [0]),
            sent("Catch you later!",             "回头见",                [0]),
        ],
        INTERMEDIATE: [
            sent("Hi, I don't think we've met yet.",                  "我们应该还没见过",          [4]),
            sent("I'm Nova — visiting from Shanghai.",                "我是 Nova，从上海过来的",   [4]),
            sent("I lead design at a small product startup.",         "我在一家产品初创做设计",     [3]),
            sent("I've been doing this for about five years.",        "这行我做了五年左右",        [3]),
            sent("What's keeping you busy these days?",               "你最近在忙什么？",          [3]),
            sent("Are you based here, or just visiting?",             "你住这边还是来出差？",      [4]),
            sent("The food scene here is amazing.",                   "这边的吃的太棒了",          [4]),
            sent("We should grab coffee sometime.",                   "找时间一起喝咖啡",          [3]),
            sent("Here's my card if you'd like to follow up.",        "这是我的名片",             [4]),
        ],
        ADVANCED: [
            sent("Pleasure to finally put a face to the name.",                                     "终于见到本人了",                  [4]),
            sent("I run product at a Series-B fintech.",                                            "我在一家 B 轮金融科技公司管产品", [3]),
            sent("I made the jump from finance about three years ago.",                             "三年前我从金融转过来的",          [4]),
            sent("It's been a steep learning curve, but no regrets.",                               "学习曲线挺陡，但不后悔",          [5]),
            sent("I'm here for the summit, mostly to catch up with old colleagues.",                "我来开峰会，主要和老同事叙旧",    [4]),
            sent("Are you on the founder side, or more on investments?",                            "你是创始人还是投资圈？",          [4]),
            sent("We've been heads-down on a launch, so I haven't been to many of these.",          "我们最近忙发布，没怎么出席",      [3]),
            sent("I'd love to compare notes before the closing keynote.",                           "闭幕演讲前我们交流一下",          [4]),
            sent("Feel free to drop me a line — happy to chat shop anytime.",                       "随时联系我，乐意聊业务",          [4]),
            sent("Looks like the panel's about to start, but really nice meeting you.",             "好像快开场了，认识你很高兴",      [5]),
            sent("Let's stay in touch — LinkedIn works.",                                           "保持联系",                       [3]),
        ],
    },

    # ─── Scene 2: 餐厅点餐 ───────────────────────────────────────
    "restaurant": {
        # 入门 = 咖啡店 / 快餐柜台快速点单（不在桌上，没服务员转桌）
        ENTRY: [
            sent("A coffee, please.",     "一杯咖啡",        [1]),
            sent("Make it small.",        "小杯就行",        [2]),
            sent("For here, thanks.",     "在这儿喝",        [1]),
            sent("How much is it?",       "多少钱？",        [3]),
        ],
        INTERMEDIATE: [
            sent("Hi, do you have a table for two?",            "有两人桌吗？",                  [3]),
            sent("We don't have a reservation, unfortunately.", "不好意思我们没订位",            [4]),
            sent("What's good here that's not on the menu?",    "有什么菜单外的推荐吗？",        [4]),
            sent("I'll go with the chef's special tonight.",    "来份今晚的主厨特餐",           [3]),
            sent("Could you put the dressing on the side?",     "酱汁单独放可以吗？",           [4]),
            sent("Is the salmon wild-caught or farmed?",        "三文鱼是野生还是养殖的？",      [3]),
            sent("Could we split the dessert three ways?",      "甜点能切成三份吗？",           [5]),
            sent("Do you take Apple Pay?",                      "收 Apple Pay 吗？",          [3]),
            sent("The service was lovely, thank you.",          "服务真好，谢谢",               [3]),
        ],
        ADVANCED: [
            sent("Hi, we're a party of two — anywhere you can squeeze us in?",  "我们两个人，哪儿能塞下都行",    [9]),
            sent("Whatever the kitchen recommends, we're game for.",            "厨房推荐什么我们都吃",         [4]),
            sent("Is there a wine pairing for the tasting menu?",               "品鉴菜单有配酒吗？",           [5]),
            sent("I'll defer to my friend on the appetizer choice.",            "前菜让朋友点",                 [3]),
            sent("Could you ask the chef to go light on the salt?",             "请厨师少放点盐",              [9]),
            sent("Anything we should avoid on the menu?",                       "菜单上有什么避雷的吗？",       [4]),
            sent("We're not in a rush — happy to space the courses out.",       "不赶时间，菜上慢点没事",       [4]),
            sent("Compliments to the kitchen — that was outstanding.",          "厨师手艺真棒",                [3]),
            sent("Could you box up the rest for us?",                           "帮我们打包一下",              [3]),
            sent("We'll handle the gratuity in cash.",                          "小费付现金",                 [4]),
            sent("Have a great evening.",                                       "晚上愉快",                    [3]),
        ],
    },

    # ─── Scene 3: 酒店办理入住 ──────────────────────────────────
    "hotel": {
        # 入门 = 民宿 / 青旅极简入住，跟前台扫一眼就走
        ENTRY: [
            sent("Just checking in.",     "来办入住",        [2]),
            sent("Just one night.",       "就一晚",          [2]),
            sent("Cash or card?",         "现金还是刷卡？",  [0]),
            sent("Where's my room?",      "我的房间在哪？",  [2]),
        ],
        INTERMEDIATE: [
            sent("I'm checking in — booking should be under Lin.",      "办入住，订单是 Lin",        [3]),
            sent("Is the breakfast buffet included in the rate?",       "房费包早餐自助吗？",        [3]),
            sent("Could I extend check-out by a few hours?",            "退房时间能延后几小时吗？",   [3]),
            sent("Any chance of an upgrade tonight?",                   "今晚能升级吗？",            [4]),
            sent("I'd prefer a quiet room away from the elevator.",     "想要安静一点远离电梯的房间", [6]),
            sent("Is the spa open to walk-ins?",                        "水疗中心可以现场进吗？",     [4]),
            sent("Where's the closest pharmacy?",                       "最近的药店在哪？",          [3]),
            sent("Could I get a wake-up call at 7?",                    "7 点叫醒服务可以吗？",      [4]),
            sent("Could you have a luggage cart sent up?",              "能送个行李车上来吗？",      [5]),
            sent("Thanks, have a great evening.",                       "晚上愉快",                  []),
        ],
        ADVANCED: [
            sent("Good evening — checking in for two nights, name's Lin.",    "晚上好，住两晚，姓 Lin",       [4]),
            sent("Anything special I should flag with the front desk?",       "有什么需要特别说明的吗？",      [6]),
            sent("I'd rather forgo the morning paper, thanks.",               "不用早报，谢谢",              [3]),
            sent("Could you connect me with the concierge?",                  "帮我转礼宾部",                [4]),
            sent("I'm hoping to grab a table at Bar Mercer tonight.",         "今晚想订 Bar Mercer",        [4]),
            sent("Could housekeeping skip my room tomorrow morning?",         "明早不用打扫",               [3]),
            sent("If anyone calls for me, just take a message.",              "有人打电话留言就好",         [5]),
            sent("Bills can go on the room — I'll settle at checkout.",       "消费挂房账，退房一起结",      [3]),
            sent("Late checkout's not an issue, is it?",                      "延迟退房没问题吧？",          [3]),
            sent("Sorry to bother — could I get a few extra towels?",         "能多给几条毛巾吗？",         [9]),
            sent("Appreciate the warm welcome.",                              "感谢热情接待",               [2]),
        ],
    },

    # ─── Scene 4: 初次见面寒暄 ──────────────────────────────────
    "first-meeting": {
        # 入门 = 公司大堂 / 电梯偶遇新同事（短促、功能性）
        ENTRY: [
            sent("Hey, are you new here?", "你是新来的吗？",      [4]),
            sent("Same team!",             "我们一个组的",        [1]),
            sent("Lunch around noon?",     "中午一起吃饭？",      [2]),
            sent("Welcome aboard!",        "欢迎加入",            [1]),
        ],
        INTERMEDIATE: [
            sent("Hi — I don't think we've been introduced.",         "我们好像还没认识",          [4]),
            sent("I'm Nova, I came with the marketing team.",         "我是 Nova，跟市场团队一起来的", [5]),
            sent("How do you and the host know each other?",          "你和主人怎么认识的？",      [3]),
            sent("What kind of work are you in?",                     "你做什么工作？",           [3]),
            sent("Have you been to one of these before?",             "你以前来过这种聚会吗？",    [3]),
            sent("Are you here for the talk or just the networking?", "你来听演讲还是 networking？", [4]),
            sent("What's been the highlight of your week?",           "你这周最大的亮点是什么？",   [5]),
            sent("Mind if I steal you for a quick chat later?",       "待会儿能聊几句吗？",        [4]),
            sent("Let me grab your contact before I forget.",         "趁没忘记加个联系方式",      [3]),
            sent("Really enjoyed talking — let's stay in touch.",     "聊得很愉快，保持联系",      [3]),
        ],
        ADVANCED: [
            sent("Pardon the intrusion — I overheard your point about retention.",          "不好意思打扰，听到您讲留存的话题",  [4]),
            sent("I'm Nova — I run growth at a B2B SaaS startup.",                          "我是 Nova，在 B2B SaaS 公司做增长", [4]),
            sent("How did you find your way into this industry?",                           "你是怎么进入这个行业的？",          [4]),
            sent("Are you on the speaker roster, or just in the audience like me?",         "你是讲者还是听众？",                [5]),
            sent("Mind if I ask what you're working on these days?",                        "我能问下你最近在做什么吗？",         [5]),
            sent("I'd love to hear more, but I don't want to monopolize your time.",        "想多听听，但不能霸占你时间",        [9]),
            sent("Are you headed to the after-party at the rooftop?",                       "你去顶楼的 after-party 吗？",      [4]),
            sent("We should definitely follow this up over coffee.",                        "改天喝咖啡接着聊",                  [3]),
            sent("Let me grab your details before the room clears.",                        "趁人散之前加下你联系方式",          [3]),
            sent("Honestly, this has been one of the better conversations of the night.",   "说实话，这是今晚最棒的对话之一",     [9]),
            sent("Take care — talk soon.",                                                  "保重，回头聊",                      [0]),
        ],
    },

    # ─── Scene 5: 礼貌拒绝 ──────────────────────────────────────
    "decline" : {
        # 入门 = 微信 / 短信婉拒朋友邀请（口语化、轻松）
        ENTRY: [
            sent("Sounds fun!",               "听起来不错",            [1]),
            sent("Can't make it tonight.",    "今晚去不了",            [0]),
            sent("Have one for me!",          "替我喝一杯",            [3]),
            sent("Catch up soon!",            "回头约",                [1]),
        ],
        INTERMEDIATE: [
            sent("Thanks for thinking of me, but I'll have to pass.",       "谢谢你想到我，这次去不了",       [6]),
            sent("I'd be there if I could, but my schedule's packed.",      "能去我一定去，但日程满了",       [9]),
            sent("It's not really my scene, but I appreciate the invite.",  "这不太是我兴趣点，但谢谢邀请",   [5]),
            sent("I'm trying to keep my weekends quiet for a while.",       "最近想周末休息一下",            [6]),
            sent("Let me check with my partner and get back to you.",       "我和家人确认下再回你",          [6]),
            sent("I don't want to overcommit and flake on you later.",      "不想答应了又放鸽子",            [4]),
            sent("Could we do a rain check?",                                "能改天吗？",                  [4]),
            sent("Honestly, dinner sounds great but the location is far.",  "吃饭挺好就是地方太远",          [4]),
            sent("Thanks for understanding — it really means a lot.",       "谢谢理解，真的很感激",          [2]),
        ],
        ADVANCED: [
            sent("I really appreciate the invite, but it's not going to work this time.",   "谢谢邀请，这次不太合适",       [9]),
            sent("I've been trying to be more intentional about my evenings.",              "最近想多留点晚上的时间给自己",  [6]),
            sent("Sounds like a great event — please count me out for this round.",         "活动听上去不错，这次先不参加",  [9]),
            sent("Honestly, I've been spread thin and I want to do less, not more.",        "最近事情太多，想做减法",       [4]),
            sent("Could I take a rain check and pencil in something soon?",                 "这次先错过，下次约一个",       [4]),
            sent("I'd hate to RSVP yes and then cancel last minute.",                       "不想答应了又临时取消",         [9]),
            sent("Thanks for understanding — this isn't the right week for me.",            "谢谢理解，这周不合适",         [3]),
            sent("Send me details, but no promises.",                                       "发我详情，但不保证去",         [3]),
            sent("Let's connect once things calm down on my end.",                          "等我这边忙完再说",             [3]),
            sent("Really thoughtful of you to ask — let's circle back next month.",         "谢谢想到我，下个月再聊",       [4]),
            sent("Would love to, but I'll have to take a hard pass this time.",             "想去但这次必须放弃",          [9]),
        ],
    },

    # ─── Scene 6: 问老师孩子情况 ──────────────────────────────────
    "teacher-conference": {
        # 入门 = 校门口接孩子 30 秒和老师对话（不像家长会那么深入）
        ENTRY: [
            sent("Hi, Ms. Lee.",                    "李老师好",              [1]),
            sent("Was Nova OK today?",              "Nova 今天还好吗？",     [3]),
            sent("Anything I should know?",          "有什么我该知道的吗？",  [3]),
            sent("See you Friday!",                  "周五见",                [2]),
        ],
        INTERMEDIATE: [
            sent("How has Nova been doing this semester?",                  "Nova 这学期表现怎么样？",      [4]),
            sent("Is she keeping up with her classmates?",                  "她跟得上同学吗？",            [3]),
            sent("Are there any subjects we should give extra attention?",  "有哪些科目要额外关注？",       [5]),
            sent("Has she been making friends OK?",                         "她交朋友顺利吗？",            [4]),
            sent("How's her reading level for her grade?",                  "她阅读水平在年级里怎么样？",   [3]),
            sent("What's the best way for us to support her at home?",     "在家怎么配合您最好？",         [3]),
            sent("Are there resources you'd recommend?",                    "您推荐什么学习资源？",        [3]),
            sent("Should we be worried about her math performance?",        "数学方面要担心吗？",          [4]),
            sent("Is there a parent-teacher app we should be using?",       "有家校 app 我们要用吗？",     [4]),
            sent("Thanks for taking the time today.",                       "谢谢您今天抽时间",            [4]),
        ],
        ADVANCED: [
            sent("Thanks for making the time — I know parent-teacher week is hectic.",          "谢谢您抽时间，知道家长会周很忙",  [10]),
            sent("How's Nova's engagement been compared to last semester?",                     "和上学期比，Nova 的参与度怎么样？", [3]),
            sent("We've noticed she's been quieter at home — is that consistent at school?",    "她在家变得安静，学校也这样吗？",  [4]),
            sent("Are there particular concepts she's struggling to grasp?",                    "有哪些具体的概念她还没掌握？",    [5]),
            sent("How does she handle group work versus working independently?",                "小组合作和独立学习哪个更适应？",  [4]),
            sent("Any social dynamics in the class we should be aware of?",                     "班级里有什么社交动态我们该了解？",  [4]),
            sent("Would you suggest a tutor at this stage, or is it too early?",                "现在要请家教吗，还是太早？",     [4]),
            sent("What does success in this grade typically look like?",                        "这个年级的优秀是什么样的？",     [3]),
            sent("Could we set up a follow-up in a month to check progress?",                   "一个月后再约一次看进展吗？",     [3]),
            sent("We really appreciate everything you do for her.",                             "真的感谢您为她做的一切",         [3]),
            sent("Looking forward to staying in close communication.",                          "期待保持密切沟通",              [3]),
        ],
    },
}


def build_tier(level: str, sentences: list[dict]) -> dict:
    return {
        "level": level,
        "label": LABEL_FOR[level],
        "sentenceCount": len(sentences),
        "sentences": sentences,
    }


def main():
    catalog = json.loads(SCENES_JSON.read_text(encoding="utf-8"))

    pilot_set = set(PILOT_SCENE_IDS)
    pilot_added = 0
    wrapped_existing = 0

    for scene in catalog["scenes"]:
        sid = scene["id"]
        existing = scene.get("sentences", [])

        if sid in pilot_set:
            extras = PILOT_TIERS.get(sid)
            if not extras:
                raise SystemExit(f"Pilot scene {sid!r} listed but not in PILOT_TIERS")
            tiers = [
                build_tier(ENTRY,        extras[ENTRY]),
                build_tier(BEGINNER,     existing),       # current content = 初级
                build_tier(INTERMEDIATE, extras[INTERMEDIATE]),
                build_tier(ADVANCED,     extras[ADVANCED]),
            ]
            scene["tiers"] = tiers
            pilot_added += 1
        else:
            # Non-pilot: wrap existing as a single 初级 tier so the iOS
            # code only ever has to deal with one shape.
            scene["tiers"] = [build_tier(BEGINNER, existing)]
            wrapped_existing += 1

    SCENES_JSON.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Pilot scenes given 4 tiers: {pilot_added}")
    print(f"Other scenes wrapped as single 初级 tier: {wrapped_existing}")
    total_tiers = sum(len(s["tiers"]) for s in catalog["scenes"])
    total_sents = sum(len(t["sentences"]) for s in catalog["scenes"] for t in s["tiers"])
    print(f"Total tiers: {total_tiers} · sentences: {total_sents}")


if __name__ == "__main__":
    main()
