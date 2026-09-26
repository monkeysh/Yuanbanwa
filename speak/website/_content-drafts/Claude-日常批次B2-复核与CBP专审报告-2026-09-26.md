# 日常批次 B2 · 复核 + 过海关 CBP 合规专审报告（2026-09-26，Claude）

> 对应审核包：`GPT-过海关CBP合规-专审包-2026-08-16.md`（customs 三档）以及批次 B2 其余 6 个场景的常规复核。审的是 `daily-batchB2.json` v2，修订已直接写入 v3（见文件 `_note`）。

## 一、机械自检：5 处与现有初级档字面完全重复（必改）

你们的上线前自检脚本对 entry / intermediate / advanced 逐句比对现有初级档，以下 5 句会直接 `assert` 失败：

| 场景 / 档 | 重复句 | 处理 |
|---|---|---|
| baggage · entry #4 | `Thank you.`（= beginner-7；也违反本批次 ⑨"入门第 4 句不浪费在 Thank you"） | → `All the way to Shanghai?`（转机旅客最需要的一句，且与中级 #7 不同） |
| customs · entry #1 | `Here's my passport.`（= beginner-1） | 删除；入门档顺延，末句补 `Could I have a Mandarin interpreter?` |
| customs · intermediate #8 | `Here's my return ticket.`（= beginner-7） | → `No meat or fruit — just the tea and mushrooms.`（见二 ③） |
| sick-leave · intermediate #5 | `Could you let her teacher know?`（= beginner-5） | → `Do I need to send an email too, or is this call enough?` |
| sick-leave · intermediate #9 | `Thanks very much.`（= beginner-6） | → `Thanks — I'll call again if anything changes.` |

修订后自检通过（含批次内跨档重复）。

## 二、customs · CBP 合规专审

审查标准：如实、简短、只答所问；申报义务；二次问话语气；中文不误导。

| # | 档 / 句 | 判定 | 说明与处理 |
|---|---|---|---|
| ① | advanced #9 现金合计 | 建议 → 已改 | 一万美元门槛按**同机同行的家庭/团体合并计算**，两人合计 1.2 万必须申报并填 FinCEN 105，原句方向正确；但"carrying about twelve thousand dollars"未说明是现金（现金 + 旅行支票等货币工具都算），补 `in cash`，并与 #10 "I'll fill out the form" 的表格指向一致 |
| ② | advanced #5 | 必改 → 已改 | `I'm retired, so I won't be working while I'm here.` 是典型的**主动澄清**：官员问的是职业，学员多说"我不会工作"反而引导对话走向工作意图。改为只答所问 `I'm retired.` |
| ③ | intermediate 缺漏 | 必改 → 已补 | 中国家长最常被追问的是**肉制品、水果、种子**（真空包装肉、含肉月饼、腊肠都是违禁品）。原三档只申报茶叶和干香菇，没有一句回答"有没有肉/水果"。补 `No meat or fruit — just the tea and mushrooms.`（顺接中级 #7 的申报）。注意：这句是**模板**，学员要按实情替换；真带了肉制品必须如实申报并主动放弃 |
| ④ | entry | 建议 → 已改 | 入门档改为 `I'm visiting family. / Three weeks. / I have some food in my bag. / Could I have a Mandarin interpreter?` 顺序即行为顺序：先答三个基本问题，答不上来再请翻译。CBP 有中文官员和电话翻译，入境口岸请翻译不会加重怀疑 |
| ⑤ | 处方药 advanced #8 | 通过 | 原包装 + 医生证明 + 合理用量，说法正确 |
| ⑥ | 二次问话语气 | 通过 | `Of course, officer.` / `I understand — I'll fill out the form.` / `Thank you for explaining that.` 平静配合，没有认错或服软式表述；`I'd rather declare it just to be safe.` 体现善意申报，二次检查中说这句是加分 |
| ⑦ | 中文 | 建议 → 已改 | `officer` 译"长官"带军衔/官阶色彩，改"警官"（两处）。`declare` 译"申报"、`form` 译"表"准确 |
| ⑧ | 现有初级档 `I have nothing to declare.` | 保留 | 按规矩初级档一字不动；但它与入门档"我包里有食品"并存，学员要理解"没有就说没有，有就必须说有"。建议后续场景说明里点一句 |

## 三、其余 6 个场景常规复核

| 场景 | 判定 | 说明 |
|---|---|---|
| starbucks | 通过 | 杯型口径 Grande 统一、热饮线要 mug、Wei 拼读、移动订单补做，全部自洽 |
| hotel-checkout | 建议 → 已改 | 高级 #6 原句 "I understand it's standard here…" 是让步；加州 2024-07-01 起生效的 SB 478（Honest Pricing Law）要求酒店把强制杂费计入标价，原句反而放弃了最有力的依据。改为 `In California, that fee is supposed to be included in the price up front.` 后接 #7 找经理，交涉链完整 |
| baggage | 见一 | 出发柜台不问到达转盘、超重转随身、托运前该取出什么（充电宝）、东京转机是否直挂、丢件 PIR 流程，事实正确 |
| gate | 通过 | 航司原因误机走 confirm 不走 standby，行李去向、住宿、餐券、新确认号，顺序合理 |
| parent-meeting | 建议 → 已改 | 入门第 4 句 `Thank you for your help.` 违反本批次 ⑨，改为 `Is there a Mandarin interpreter available?`（学区对家长有语言服务义务，中国家长刚需）。ELL / reclassification 术语准确 |
| sick-leave | 见一 | 独立学习协议（short-term independent study）、缺勤自动信、五天以上的变化，均是加州学区真实流程 |

## 附：审核 JSON（customs）

```json
{"reviews":[
 {"tier":"entry","idx":1,"severity":"必改","issue":"与初级档字面重复","suggest":"（删除）"},
 {"tier":"entry","idx":4,"severity":"建议","issue":"入门档缺中文翻译请求","suggest":"Could I have a Mandarin interpreter?"},
 {"tier":"intermediate","idx":8,"severity":"必改","issue":"与初级档字面重复；且三档无一句回答肉/水果","suggest":"No meat or fruit — just the tea and mushrooms."},
 {"tier":"advanced","idx":5,"severity":"必改","issue":"主动澄清'不会工作'，画蛇添足","suggest":"I'm retired."},
 {"tier":"advanced","idx":9,"severity":"建议","issue":"未说明是现金","suggest":"…between us we're carrying about twelve thousand dollars in cash."}
],"gaps":[{"missing":"肉制品/水果的否定申报模板","suggest":"No meat or fruit — just the tea and mushrooms."}],"overall":"申报义务与二次问话语气整体正确；改掉主动澄清与两处字面重复，补肉/水果申报句和翻译请求后可合入。"}
```
