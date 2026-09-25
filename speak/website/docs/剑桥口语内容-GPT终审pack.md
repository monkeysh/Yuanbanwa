# 剑桥口语跟读内容 · GPT 终审 pack

> 审稿链:**DeepSeek v4pro 二审 → Opus 4.8 对抗式复审(独立复审 + 逐条核验 DeepSeek)→ 你(GPT)终审**。
> 产品:Speak 跟读 App「剑桥考试对话」分区,KET(A2)/PET(B1)/FCE(B2)各 6 话题,每话题含 examPart 标注、examTip 考点说明、templates 答题模板、Part 1 对话、Part 2 长独白(PET 单图/FCE 双图)。

## 请 GPT 做的事
1. 对下方 **7 个开放问题**逐条给出明确裁决与理由(尤其问题 1 的统一定性)。
2. 复核 Opus 列出的 **4 条 high / 5 条 med** 修正是否准确、修正文案是否最优,若有更好改法请直接给出。
3. 指出 Opus + DeepSeek 都漏掉的任何**事实性/考法性错误**(剑桥官方 KET/PET/FCE 口语题型编号与流程)。

## 总体结论(Opus)
三级内容（KET/PET/FCE）语言质量整体过硬：英文地道、CEFR 级别名实相符、翻译准确、templates 可迁移，绝大多数话题可直接上线。真正阻断上线的是 KET 板块的系统性「考法定性错误」——ket-personal/shopping/food 三个话题把「考生互相问答」或「店员-顾客交易对话」标成了 KET Speaking Part 1，而真实 Part 1 是考官单向提问、考生作答，这对付费备考学生属高优先级误导，必须先修 examPart/examTip（part1 正文是否重写可酌情）；pet-school 还有一处考法错误（描述单图是 PET Part 3 而非 Part 2）同属 high。其余均为 low/med 级润色：examTip 措辞过强、templates 的 zh 用功能标签而非直译（多为有意设计，可选统一）、个别搭配/翻译不够地道。结论：PET、FCE 两级几乎即可上线（仅 pet-school 需修考法标签）；KET 级语言达标但考法标注需统一修正后方可作为「备考」内容上线。建议先批量处理 4 条 high，再按需采纳 low 级润色。

### 分级评估
- **KET**:A2 级别名实相符、英文地道无语病；但 personal/shopping/food 三话题把对话型/交易型内容误标为 Speaking Part 1（真实为考官单向问答），考法定性需统一修正后方可作备考用途。
- **PET**:B1 级别名实相符、内容地道、Part 1 个人问答与单图长描述真实考法基本到位；唯 pet-school 把单图描述误标为 Part 2（实为 Part 3），修正考法标签后整级达标。
- **FCE**:B2 级别名实相符、内容质量最稳，Part 1（经历/计划）与 Part 2（双图对比+推测）考法准确，搭配与高级连接词地道，仅余 examTip 措辞与 templates zh 风格等 low 级润色，可直接上线。

### 统计
问题总数 33(high 4 / med 5 / low 24)

## 开放问题(需 GPT 裁决)

**Q1.** KET 三个话题（personal/shopping/food）的 part1 正文是真实双角色/交易型对话，本品又是「跟读」产品。最终该把 examPart 重写为考官-考生单向问答（牺牲生活场景真实感），还是保留生活对话原貌、仅把标签从『Part 1』改为『生活场景口语』（牺牲与 KET 考试的直接挂钩）？请给出统一裁决，避免逐话题各行其是。

**Q2.** templates 字段的 zh 在全站多处是『功能标签』（如「说旅行的好处」）而非逐句直译，跟读时学生无法对照句意。这是产品有意设计还是疏漏？应统一改为带空格的直译，还是保留功能标签（甚至二者兼具）？此决定影响 pet-hobbies/fce-environment/fce-work/fce-travel 等多条 low issue 是否立案。

**Q3.** ket-school 的 part1 含考生互动语 'What about you?' 和 'Good luck with it!'——剑桥官方鼓励 Part 1 的互动衔接技能，但严格 Part 1 是考官单向提问。在『跟读同伴互练』定位下，是否应保留这类互动语并仅在 examTip 注明，还是为忠于考法而删除？

**Q4.** ket-personal 的 examTip 称「拼写名字是最常被追问项」。现行 A2 Key (2020 改版) Part 1 是否仍把『拼写姓名/字母』作为标准/高频环节？需第三方确认 2020 改版后的真实流程，以定夺该表述是夸大还是属实。

**Q5.** pet-school 把『描述单张照片』归为 Part 2 实属 Part 3 已确认为 high。请复核：现行 PET (B1) 口语四部分的官方编号是否确为 Part1 个人问答 / Part2 双人协商 / Part3 个人长说(单图) / Part4 双人讨论？以确保改成『Part 1 + Part 3』后整套编号与官方一致。

**Q6.** 多条 FCE/PET 的 examTip 用『要求用（某时态/某结构）』这类绝对措辞（fce-technology、fce-health 等）。是否应在全站统一为『通常会自然用到』式软性引导？请给出一个可复用的标准措辞模板，便于批量替换。

**Q7.** 对 'I prefer shopping online…'（pet-shopping templates[0]）与 'I'd like to learn'（pet-hobbies templates[2] 无宾语）这两处，DeepSeek 判为语法陷阱、Opus 驳回。请第三方裁决这两个无宾语/动名词结构作为 B1 跟读模板是否地道、是否需补宾语。

## HIGH(阻断上线) 修正项

### [ket-food] examPart  · source=both conf=0.95
- **问题**:标注为「口语 Part 1」，但内容是店员与顾客的点餐交易对话。真实 KET Speaking Part 1 是考官-考生一对一面试（个人信息问答 + 'tell me about…' 简短陈述），不含此类服务场景角色扮演。标签严重误导备考方向。
- **建议修正**:改标签为「生活场景口语」（不挂 KET Part）；若保留 KET 关联，examPart 写「生活口语（KET 话题拓展）」，并在 examTip 明确这是话题/场景拓展而非 Part 1 真实考法。

### [ket-shopping] examPart  · source=both conf=0.9
- **问题**:examPart 标为「口语 Part 1」，但 part1 内容是顾客与店员双角色成交式购物对话（8 句一问一答）。KET Speaking Part 1 实为考官向单个考生提个人问答（Do you like shopping? What did you buy?），无双角色交易对话。错误定性会误导考生对考试形式的认知。
- **建议修正**:examPart 改为「实用购物口语」（或「生活情景对话」）。如需保留考试关联，可在 examTip 注明这是真实交流表达、可为 Part 1 购物话题作答储备素材，但本身不是 Part 1 题型。

### [ket-personal] part1  · source=both conf=0.9
- **问题**:标注为「口语 Part 1」，但 part1 写成两名平辈考生（Tom 与 Lily）初次见面互相自我介绍并反问（I'm from China. And you? / How old are you?）。KET Part 1 真实考法是考官单向提问、考生作答；考生互问出现在 Part 2。该对话与本条目 examTip 自述的「考官先问你的名字、年龄、家乡和家庭」也自相矛盾。作为唯一 KET Part 1 范例会误导考生。
- **建议修正**:改为考官-考生单向问答（保留 Lily 为答题考生）：考官 Hello. What's your name? / 考生 My name is Lily.；考官 Where do you live, Lily? / 考生 I live in Beijing, in China.；考官 How old are you? / 考生 I'm fifteen years old.；考官 How many people are there in your family? / 考生 There are four people in my family — my mum, my dad, my younger brother and me.；考官 Do you have any brothers or sisters? / 考生 Yes, I have one younger brother.

### [pet-school] examPart / examTip  · source=opus conf=0.9
- **问题**:考试 Part 归属错误。PET (B1) 口语中 Part 2 是双人协商任务（两名考生看一组小图讨论做决定），描述单张彩色照片的「个人长说」是 Part 3。本内容 examPart 标为「Part 1 + Part 2」，examTip 写「Part 2 单图常是教室、图书馆…要用 There is/are 和现在进行时描述」——这描述的其实是 Part 3，会直接误导备考方向。
- **建议修正**:将 examPart 改为「Part 1 + Part 3」；examTip 中「Part 2 单图常是教室、图书馆或学生在学习的场景」改为「Part 3 个人长说会给你一张彩色照片，常是教室、图书馆或学生在学习的场景」，其余描述（There is/are、现在进行时、I think/probably 推测）保持不变。

## MED(建议修) 修正项

### [ket-food] examTip  · source=both conf=0.85
- **问题**:examTip 把「Part 1 考官常问 What's your favourite food?」与点餐对话并列陈述，暗示点餐句型属于 Part 1 考查内容，强化了 examPart 的误导。
- **建议修正**:拆分表述：「KET Part 1 饮食话题，考官常问 What's your favourite food? Do you often eat out? 答完整句加理由最稳。下面的点餐对话是生活场景拓展——考试不直接考，但学会 I'd like…、Can I have…、For here or to take away? 出国点餐很实用。」

### [ket-shopping] examTip  · source=both conf=0.78
- **问题**:examTip 自相矛盾：开头把内容框定为 Part 1 面试（Do you like shopping?…完整句加理由），随后又推销 How much is…/Do you have it in…/Can I try it on 这些成交短句——而这些短句不会出现在 Part 1 个人问答的答语里，二者是两种语境。
- **建议修正**:改为：「购物是 KET 常考生活话题。Part 1 考官可能问 Do you like shopping? What did you buy last week?，要用完整句回答并给理由。下面这段店里购物对话练的是另一类——真实买东西时的实用说法：问价 How much is…、要颜色 Do you have it in…、试穿 Can I try it on，逛店真用得上。」（点明这是真实场景表达，与 Part 1 答题区分开。）

### [ket-travel] examPart / examTip  · source=opus conf=0.7
- **问题**:examPart 标为「口语 Part 1」并称「与 KET 口语 Part 1 真实考法匹配」，但 KET Part 1 是考官对考生的个人信息访谈（姓名、居住地、学校、爱好），不含与陌生人的功能性问路交易对话（Excuse me, how do I get to…）。examTip 把功能对话与个人问句混为一谈，略有误导。
- **建议修正**:将 examTip 首句调整为不暗示这是 Part 1 真实题型，如：「问路是日常出行必备口语。注意：KET 口语 Part 1 实际是考官问你个人问题（如 How do you get to school?），而本段练的是真实街头问路对话——两者都用得上 go straight / turn left。」examPart 可保留作内容归类，但不应宣称「真实考法匹配」。

### [ket-school] part1  · source=both conf=0.6
- **问题**:对话被标为「口语 Part 1」且 examTip 以考官提问框架呈现，但句中混入考生对考官的反问 'I really like science. What about you?' 和结尾 'Good luck with it!'，使整段更像同伴聊天而非 KET Part 1 的考官-考生一问一答，与考试框架轻微不符。
- **建议修正**:若要忠于 Part 1 考法，把 'I really like science. What about you?' 改为 'I really like science. It's interesting.'；把结尾 'Good luck with it!' 改为考官式收束 'OK, thank you.'；或保留同伴语气但在 examTip 注明「这是同伴互练版，考试中考生只需回答考官」。

## 附录:受影响话题全文(供 GPT 判定)

### ket-personal（KET/A2）认识新朋友 — Meeting someone new
- examPart: `口语 Part 1`
- examTip: KET 口语 Part 1，考官先问你的名字、年龄、家乡和家庭。每题都要答完整一句话，别只蹦单词；最常被追问的是「拼写你的名字」和「家里有几口人」。一时没听清，就说 Sorry, can you repeat that?，比愣着强。
- templates: `My name is ___. / I'm ___.`(介绍名字) / `I'm ___ years old.`(说年龄) / `I'm from ___. / I live in ___.`(说来自哪里) / `There are ___ people in my family.`(说家里几口人)
- Part1:
  1. Hi! Nice to meet you. I'm Tom.  〔你好！很高兴认识你，我是汤姆。〕
  2. Nice to meet you too, Tom. My name is Lily.  〔我也很高兴认识你，汤姆。我叫莉莉。〕
  3. Where are you from, Lily?  〔你来自哪里，莉莉？〕
  4. I'm from China. And you?  〔我来自中国。你呢？〕
  5. I'm from Canada. How old are you?  〔我来自加拿大。你多大了？〕
  6. I'm fifteen years old.  〔我十五岁。〕
  7. Do you have any brothers or sisters?  〔你有兄弟姐妹吗？〕
  8. Yes, I have one younger brother.  〔有的，我有一个弟弟。〕

### ket-shopping（KET/A2）买一件 T 恤 — Buying a T-shirt
- examPart: `口语 Part 1`
- examTip: 购物是 KET 常考生活话题。Part 1 考官可能问 Do you like shopping? What did you buy last week?，要用完整句回答并给理由。对话里的实用说法——问价 How much is…、要颜色 Do you have it in…、试穿 Can I try it on——逛店真用得上，记熟能脱口而出。
- templates: `How much is this ___?`(问价格) / `Do you have it in ___?`(要颜色或款式) / `Can I try it on?`(试穿) / `I'll take it. Here you are.`(决定购买并付款)
- Part1:
  1. Excuse me, how much is this T-shirt?  〔打扰一下，这件 T 恤多少钱？〕
  2. It's twelve dollars.  〔十二美元。〕
  3. Do you have it in blue?  〔有蓝色的吗？〕
  4. Yes, here you are.  〔有的，给你。〕
  5. Can I try it on?  〔我可以试穿吗？〕
  6. Sure. The changing room is over there.  〔当然，试衣间在那边。〕
  7. It fits well. I'll take it.  〔很合身，我就要这件。〕
  8. Great. That's twelve dollars, please.  〔好的，一共十二美元，谢谢。〕

### ket-food（KET/A2）在快餐店点餐 — Ordering at a café
- examPart: `口语 Part 1`
- examTip: 饮食是 KET 高频话题。Part 1 考官常问 What’s your favourite food? Do you often eat out?，答完整句加理由最稳。点餐对话里的 I’d like…、Can I have…、Anything else? 是餐厅、快餐店的必备说法，练熟了出国点餐不慌。
- templates: `I'd like a ___, please.`(点餐) / `Can I have a ___?`(点饮料或加点) / `For here or to take away?`(堂食还是外带) / `That's all, thank you.`(礼貌结束点单)
- Part1:
  1. Are you ready to order?  〔您可以点餐了吗？〕
  2. Yes. I'd like a cheeseburger, please.  〔好的，我要一个芝士汉堡，谢谢。〕
  3. Would you like anything to drink?  〔需要喝点什么吗？〕
  4. Can I have an orange juice?  〔可以来一杯橙汁吗？〕
  5. Sure. Anything else?  〔当然，还要别的吗？〕
  6. No, that's all, thank you.  〔不用了，就这些，谢谢。〕
  7. Okay. Your food will come soon.  〔好的，您的餐很快就好。〕
  8. Thank you very much.  〔非常感谢。〕

### ket-travel（KET/A2）问路去车站 — Asking the way
- examPart: `口语 Part 1`
- examTip: 出行问路是实用口语，KET Part 1 也可能问 How do you get to school?。这段教你开口问路 Excuse me, how do I get to…、听懂方向 go straight / turn left、判断远近 Is it far?。礼貌用 Excuse me 开头，听不懂就说 Sorry?，比硬猜强。
- templates: `Excuse me, how do I get to the ___?`(问路) / `Is it far from here?`(问远近) / `Which bus goes to the ___?`(问公交线路) / `Could you say that again, please?`(没听懂请重说)
- Part1:
  1. Excuse me, how do I get to the train station?  〔打扰一下，请问火车站怎么走？〕
  2. Go straight and turn left at the bank.  〔一直走，在银行那里左转。〕
  3. Is it far from here?  〔离这里远吗？〕
  4. No, it's about five minutes on foot.  〔不远，走路大约五分钟。〕
  5. Which bus goes there?  〔哪路公交车到那里？〕
  6. You can take the number ten bus.  〔你可以坐十路公交车。〕
  7. Thank you for your help.  〔谢谢你的帮助。〕
  8. You're welcome. Have a nice day!  〔不客气，祝你今天愉快！〕

### ket-school（KET/A2）聊聊学校 — Talking about school
- examPart: `口语 Part 1`
- examTip: 学校是 KET Part 1 最经典的话题之一。考官会问 What’s your favourite subject? How many lessons do you have today? Do you get a lot of homework?。答题要给科目 + 理由（I like science because it’s interesting），别只蹦一个词，多用 favourite、because。
- templates: `My favourite subject is ___.`(说最爱的科目) / `I like ___ because ___.`(给理由) / `We have ___ lessons today.`(说课程数量) / `I usually do my homework after ___.`(聊作业习惯)
- Part1:
  1. What's your favourite subject?  〔你最喜欢哪门课？〕
  2. I really like science. What about you?  〔我很喜欢科学。你呢？〕
  3. I like English best.  〔我最喜欢英语。〕
  4. How many lessons do you have today?  〔你今天有几节课？〕
  5. I have six lessons today.  〔我今天有六节课。〕
  6. Do you have any homework tonight?  〔你今晚有作业吗？〕
  7. Yes, I have some maths homework.  〔有，我有一些数学作业。〕
  8. Good luck with it!  〔祝你顺利！〕

### ket-hobbies（KET/A2）周末做什么 — Free time and hobbies
- examPart: `口语 Part 1`
- examTip: 兴趣爱好是 KET Part 1 和 Part 2 都爱考的话题。考官常问 What do you do at the weekend? Do you like sport or music?。用 usually/often 讲频率，用 because 给理由，聊到一起还能发出邀请 Do you want to…?。答完整句、有来有往是关键。
- templates: `At the weekend, I usually ___.`(讲周末常做的事) / `I often ___ with my friends.`(讲和谁一起) / `I really like ___ because ___.`(讲喜好加理由) / `Do you want to ___ together?`(发出邀请)
- Part1:
  1. What do you usually do at the weekend?  〔你周末通常做什么？〕
  2. I often play basketball with my friends.  〔我经常和朋友打篮球。〕
  3. That sounds fun. Do you like reading?  〔听起来很有趣。你喜欢阅读吗？〕
  4. Yes, I read books in the evening.  〔喜欢，我晚上看书。〕
  5. What kind of music do you like?  〔你喜欢什么类型的音乐？〕
  6. I love pop music. How about you?  〔我喜欢流行音乐。你呢？〕
  7. I like rock music a lot.  〔我很喜欢摇滚乐。〕
  8. Maybe we can go to a concert together.  〔也许我们可以一起去看场演唱会。〕

### pet-school（PET/B1）聊聊学习计划 — Talking about studies
- examPart: `Part 1 + Part 2`
- examTip: 学习与未来计划在 PET 口语里既出现在 Part 1，也常作为收尾的展望话题。考官会问你最喜欢哪门课、为什么、将来想做什么。这里非常考验将来表达：be going to / would like to / want to + 动词原形。B1 学生要给出理由和具体计划，避免只说「I like English.」，应说「I like English because I want to study abroad in the future.」。Part 2 单图常是教室、图书馆或学生在学习的场景，要用 There is/are 和现在进行时描述谁在做什么、用了什么工具，并用 I think / probably 推测他们在学什么、感觉如何。
- templates: `My favourite subject is ___ because ___.`(讲最喜欢的科目并给理由) / `In the future, I'd like to ___.`(讲未来的计划或愿望) / `I find ___ quite difficult, so I need to ___.`(讲学习中的困难和打算) / `After I finish school, I'm going to ___.`(讲毕业后的打算)
- Part1:
  1. What's your favourite subject at school?  〔你在学校最喜欢哪门课？〕
  2. My favourite subject is English, because I enjoy learning new words and watching films in English.  〔我最喜欢的科目是英语，因为我喜欢学新单词，也喜欢看英文电影。〕
  3. Is there a subject you find difficult?  〔有没有你觉得难的科目？〕
  4. Yes, I find maths quite difficult, so I usually ask my teacher for extra help.  〔有，我觉得数学挺难的，所以我经常向老师寻求额外的帮助。〕
  5. What do you want to do after you finish school?  〔你毕业后想做什么？〕
  6. After school, I'd like to go to university and study business, because I want to start my own company one day.  〔毕业后，我想上大学学商科，因为我希望有一天能开自己的公司。〕
  7. Do you prefer studying alone or with classmates?  〔你更喜欢自己学还是和同学一起学？〕
  8. I usually prefer studying with classmates, because we can help each other and it's less boring.  〔我通常更喜欢和同学一起学，因为我们可以互相帮助，而且没那么无聊。〕
- Part2:
  1. In this picture, there are some students studying in a quiet library.  〔这张照片里有一些学生在安静的图书馆里学习。〕
  2. A girl in the front is reading a thick book and taking notes.  〔前面有个女孩正在读一本厚书，做着笔记。〕
  3. There are a lot of bookshelves behind them, full of different books.  〔他们身后有很多书架，摆满了各种书。〕
  4. Some students are using laptops, so I think they are working on a project together.  〔有些学生在用笔记本电脑，所以我觉得他们在一起做一个项目。〕
  5. It looks like they are preparing for an important exam.  〔看起来他们在为一场重要的考试做准备。〕
  6. They all look very serious and focused, but maybe a little tired too.  〔他们看起来都很认真、很专注，不过也许还有点累。〕
