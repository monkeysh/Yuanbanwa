# PET Part 2 独白加长 · Claude 自审报告 · 2026-09-27

> 对象:`_content-drafts/pet-part2-extend.json`(12 组 / 28 句),已由 `scripts/splice_pet_part2_extend.mjs` 合入 `scenes.json`。
> 对照尺:`docs/PET-官方题型断言-2026-07-31.md` §四;上一轮体检 `_content-drafts/PET-Part2独白-体检报告-2026-08-01.md`。
> 外部终审 pack:`docs/PET-Part2加长-终审pack-2026-09-27.md`(交 Codex / GPT 三步法终审,结论回填后再修订)。

## 一、题型对照(逐条)

| 官方期待 | 本批做法 | 结果 |
|---|---|---|
| 描述所见:people / activities / place / other things(位置、物品、颜色、衣着、时间、天气) | 28 句全部是可见细节:衣着 7 句、背景与地点 11 句、物品 8 句、天气 2 句 | ✓ 无一句心理推测 |
| 简短、有画面依据的推断可以,但不能取代描述 | 新句不新增推断;每组原有的 1–2 句推断(I think / probably / maybe)保留在收尾位置 | ✓ |
| 不讲故事、不谈社会议题、不转到个人经历 | 新句无叙事、无议题、无第一人称经历 | ✓ |
| 约 1 分钟 long turn | 12 组补到 117–129 词(8-1 体检口径 100–120 词/分钟 → 约 60–75 秒纯口播;考场上带自然停顿正好约 1 分钟) | ✓ 均在 110–130 词目标区间 |
| 组织:overall scene → people/activities → place/background → other details → 收尾 | 新句一律插在"可见描述结束、推断/收尾开始"处(insertBefore),不打断原有路线 | ✓ |
| 连接方式不单一 | 新句用 Behind / Next to / In the background / In the distance / On the small table / There is/are / and,不叠加 and… and…;新句 0 次 maybe,各组 maybe ≤ 2 | ✓ |

## 二、逐组画面一致性(改一句必须重读整组)

| 组 | 新句要点 | 与原句的关系 | 判定 |
|---|---|---|---|
| pet-daily | 白色冰箱贴照片便条;灶台旁水壶与干净盘子 | 与"厨房干净整洁""做早餐"一致 | ✓ |
| pet-hobbies | 弹吉他男孩蓝帽白 T;背景高树与小池塘 | 两个男孩坐草地、身后有人走过,不冲突 | ✓ |
| pet-travel | 孩子旁红桶小铲;远处有人游泳;身后白色海滨小屋与棕榈树 | 8-1 已修"全家都站着"矛盾;新句不涉及人物姿势 | ✓ |
| pet-shopping | 灰毛衣牛仔裤挎包;车里已有牛奶与苹果 | 与"推车看货架""拿水果看标签"一致 | ✓ |
| pet-food | 白桌布、每人一杯水;窗帘拉上、墙上有画 | 与"晚上、灯开着"一致(窗帘拉上) | ✓ |
| pet-school | 前排女孩深色长发戴眼镜绿毛衣;一侧大窗户光线明亮 | "安静的图书馆"未说时间,白天光线不冲突 | ✓ |
| pet-health | 女孩黄上衣白运动鞋扎发;身后有滑梯秋千 | 男孩红 T 恤已有,女孩衣着补齐;公园游乐场合理 | ✓ |
| pet-weather | 一个孩子手里拿黄叶;路边高树多已落叶;远处有人遛狗 | 与"树叶飘落""地上黄棕落叶""在跑在笑"一致(拿着叶子跑不矛盾;避免了"举给对方看"与奔跑的张力) | ✓ |
| pet-entertainment | 小桌上两杯果汁与遥控器 | 8-1 指出该组重复"爆米花—好笑—大笑",只补 1 句不同物品细节 | ✓ |
| pet-technology | 浅蓝外套、长椅上书包;前方小路有人骑车;晴天有白云 | 原句未说天气;"树和花"与晴天一致 | ✓ |
| pet-work | 白蛋糕正放草莓;高白帽头发盘起;身后金属架托盘、左边大烤箱 | 与"厨师制服""装饰蛋糕""旁边有新鲜水果""整洁"一致 | ✓ |
| pet-family | 红白毯子上有盘子杯子;女孩粉裙、小狗棕色;身后大树、远处有湖 | 毯子上放盘杯而不放食物,保住收尾句"也许带了食物,因为旁边有篮子"的推断 | ✓ |

## 三、语言与格式自检(脚本)

- 字面重复(与全站 1986 句归一化比对 + 批内):0
- 中文混入英文(除 T恤):0
- 新句含 maybe:0;各组 maybe 总数 ≤ 2
- 句长 9–20 词:28/28;首字母大写、句末标点:28/28
- 英式偏向沿用现有:grey / jumper / trainers / cooker / trolley;无美式冲突
- 具体名词难度:spade、kettle、trolley、trainers、swings、oven、remote control 均在 B1 词表范围内,较具体但有教学价值

## 四、数据层校验

- `scripts/splice_pet_part2_extend.mjs`:往返零差异校验通过;二次运行全部"已合入,跳过"(幂等)
- 语义比对(vs HEAD):其余 51 个场景完全未动;12 个 PET 场景 Part 1 / Part 3 档不变,Part 2 原句原样、相对顺序不变;新句只在 insertBefore 之前的连续区间;句 id 与音频路径全站唯一;各档与顶层 sentenceCount 同步
- 顺手修正 24 个剑桥场景(PET 12 + FCE 12)的 examPart → `Part 1 + Part 2 + Part 3`,description 补 `+ Part 3 讨论`(只改元数据)
- `SPEAK_ALLOW_MISSING_AUDIO=1 npm run validate` / `node scripts/build.mjs`:75 场景 / 2014 句通过
- Web 与 iOS 两份 scenes.json md5 相同(214b068ced3106ab4e6e7e7d7560ff47)

## 五、待办

- 外部终审(Codex / GPT)回填后如有"必改",修订 `pet-part2-extend.json` 并重跑合入脚本(脚本按 en 文本判重,修订过的句子会被视为新句;届时改为直接改 scenes.json 里对应句 + 同步内容文件更稳妥)
- 音频:28 个 rosie 文件,清单 `_content-drafts/pet-part2-extend-burn.json`;烧录 `node scripts/burn_ket_audio.mjs pet-daily pet-hobbies pet-travel pet-shopping pet-food pet-school pet-health pet-weather pet-entertainment pet-technology pet-work pet-family`(已存在的文件跳过)——等用户点头,与日常 B1/B2 的 256 个一起烧
