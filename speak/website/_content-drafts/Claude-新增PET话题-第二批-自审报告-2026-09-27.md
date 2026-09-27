# 新增 PET 话题(第二批)· Claude 自审报告 · 2026-09-27

> 对象:`_content-drafts/pet-content-batch2.json`(6 话题 × 29 句 = 174 句 + 24 模板 + 6 条 examTip),已由 `scripts/splice_pet_batch2.mjs` 合入 `scenes.json`(插在 pet-family 之后)。
> 对照尺:`docs/PET-官方题型断言-2026-07-31.md`;方案:`docs/PLAN-2026-09-26-PET加强方案.md`。
> 外部终审 pack:`docs/新增PET话题-第二批-终审pack-2026-09-27.md`(交 Codex / GPT 三步法终审,结论回填后再修订)。

## 一、话题与分类

| id | category(examTopics) | kind | 标题 | Part 3 结尾 |
|---|---|---|---|---|
| pet-personal | personal | social | 聊聊我自己 · Talking about yourself | 一致(午饭 + 参观) |
| pet-home | home | life | 聊聊我住的地方 · Home and where I live | 分歧(游戏室 vs 书房,交父母决定) |
| pet-sports | sports | life | 聊聊运动 · Sports and exercise | 一致(午休开放体育馆 + 舞蹈/瑜伽课) |
| pet-transport | transport | travel | 聊聊交通出行 · Getting around town | 一致(火车) |
| pet-festivals | festivals | social | 聊聊节日庆祝 · Celebrations and special days | 分歧(野餐 vs 灯笼,两案一起提交) |
| pet-friends | family(家庭朋友,与 ket-friends 一致) | social | 聊聊朋友 · Friends and friendship | 一致(每周视频 + 假期互访) |

六个 category 键都已存在,未新增芯片。4 组自然一致、2 组保留分歧,符合官方「不强制一致、不过早决定」。

## 二、题型对照

| 官方期待 | 本批做法 | 结果 |
|---|---|---|
| Part 1 = 考官面试、考生答,不与搭档讨论;开场是固定的个人信息问题 | 每组 4 问 4 答交替;pet-personal 用真实 interlocutor 开场句(Where do you live? / Do you work or are you a student? / Do you enjoy studying English? / What did you do last weekend?);其余组用「Tell us about… / Do you prefer… / Have you ever…」式提问 | ✓ |
| 考生答 1–2 句完整、给理由或例子,B1 语法(现在 / 过去 / 完成时、比较级、would prefer、because / so / but) | 24 个答句均 1–2 句,17–26 词,每句带 because / so / but / which 之一;覆盖 present perfect(we've been friends for…、has opened)、past simple(went cycling、visited、took a high-speed train)、would prefer / I'd rather、比较级 | ✓ |
| Part 2 = 描述所见,路线 overall → people/activities → place → other details;简短有据推断可以;约 1 分钟 | 6 组各 9 句 / 126–132 词;前 6–7 句纯可见描述,推断句每组 1–2 句(It looks like… / I think…)且都有画面依据;无叙事、无议题、无个人经历 | ✓ |
| Part 3 = 任务卡情境 + 若干图示选项;提议 / 回应 / 比较 / 给理由;向结论推进但不过早决定 | 每组情境 + 4–5 个选项,12 句里逐个提出并回应(每个选项至少一提一驳或一提一赞);结论出现在第 11–12 句;两组以「两案并提 / 交他人决定」收尾 | ✓ |
| 两名考生按个人表现评分,互动要真实 | A/B 交替,回应语多样(Fair enough / Good point / That's true, but / Ha! / Definitely) | ✓ |

## 三、与 KET 同名话题的区分(避免撞车、保证高一级)

| PET | KET 对应 | 区分点 |
|---|---|---|
| pet-personal | ket-personal(生活对话「认识新朋友」) | PET 用真实考官固定问题,答句含理由与现在完成时;KET 是 A2 自我介绍对话 |
| pet-home | ket-home(几个房间、最喜欢哪间) | PET 加入「不喜欢的地方」「以后住房子还是公寓」(would prefer + because) |
| pet-sports | ket-sports(喜欢什么运动、多久一次) | PET 问「参与 vs 观看」「想尝试的运动」「年轻人运动量够不够」(观点题) |
| pet-transport | ket-transport(怎么上学、多久) | PET 加「火车 vs 汽车偏好」「城市出行方不方便」「有没有长途旅行经历」(present perfect) |
| pet-festivals | ket-festivals(最喜欢的节日、做什么) | PET 加「怎么过生日」「去年春节做了什么」(过去时)「节日对家庭重不重要」(观点) |
| pet-friends | ket-friends(介绍好朋友、一起做什么) | PET 加「交新朋友容不容易」「朋友多重不重要」(观点 + once / but 转折) |

字面重复自检(与全站 2014 句归一化比对 + 批内):0。考官提问刻意避开 KET 原句(如 KET「How do you get to school, Lily?」→ PET「How do you usually travel to school?」)。

## 四、生成后修订(自审抓出的 3 处)

1. pet-personal Part 3 的新同学原名 Anna,与既有 pet-shopping Part 3(Anna 的生日)重名 → 改为 Mia。
2. pet-festivals Part 1「my grandparents' house」的复数属格会让 `words` 里出现尾撇号 token(影响跟读比对)→ 改为「my grandma's house」。
3. pet-festivals Part 3 原为「给同学 Ben 过生日」,但既有 Part 3 已有 3 组生日题材(pet-shopping / pet-technology / pet-family)→ 改为「为交换生办中秋节晚会」(做月饼 / 灯笼工坊 / 传统音乐 / 讲节日故事 / 户外赏月野餐),保留分歧结尾;examTip 同步。

## 五、语言与格式自检(脚本)

- 句长:Part 1 ≤ 26 词、Part 2 ≤ 20 词、Part 3 ≤ 22 词,全部达标;首字母大写、句末标点:174/174
- 中文混入英文(人名与 T恤 除外):0;英文含引号:0(横幅文字改为 a banner that says Happy Birthday,避免引号 token)
- Part 2 推断句每组 1–2 句;maybe / probably 不堆叠
- Part 3 开场句 6 组各不相同,且不同于既有 24 组(新同学 / 空房间 / 学校运动 / 周六去苏州 / 中秋晚会 / Lucy 搬家)
- 英式偏向沿用现有(flat / lift / jumper / trainers / coach / underground / colourful);地名用杭州 / 苏州 / 上海 / 北京,贴合学员
- 模板 4 条均带 ___ 空位;examTip 260–321 字,覆盖 Part 1 / 2 / 3,措辞用「通常会自然用到」

## 六、数据层校验

- `scripts/splice_pet_batch2.mjs`:往返零差异校验;结构校验(templates 4 / part1 8 且考官考生交替 / part2 8–10 句且 110–135 词 / part3 12 且 A/B 交替 / examTip ≥ 80 字 / category 键已存在);二次运行「已存在,跳过」(幂等)
- 语义比对:既有 75 个场景原样、顺序不变;6 个新场景按顺序插在 pet-family 之后;场景字段顺序与既有 PET 场景一致;句 id `{sid}-{part}-{n}`、legacyIds、音频路径(Part 1 双声、Part 2 rosie、Part 3 A 轮 rosie / B 轮双声)全部按约定;句 id 与音频路径全站唯一;各档与顶层 sentenceCount 同步
- `SPEAK_ALLOW_MISSING_AUDIO=1 npm run validate` / `node scripts/build.mjs`:81 场景 / 2188 句通过
- Web 与 iOS 两份 scenes.json md5 相同(13113d949631363079c7bd042137b9f7)

## 七、待办

- 外部终审回填后修订:直接改 `scenes.json` 对应句并同步 `pet-content-batch2.json`(句 id 不变)
- 音频:174 句 / 258 个文件,清单 `_content-drafts/pet-topics-batch2-burn.json`;烧录 `node scripts/burn_ket_audio.mjs pet-personal pet-home pet-sports pet-transport pet-festivals pet-friends` —— 等用户点头
