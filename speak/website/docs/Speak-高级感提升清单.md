# Speak 高级感提升实施清单

> 目标：在已落地的品牌底座（暖米纸张 + 陶土橙 + Georgia 衬线 + `data-theme` 深浅模式 + `.serif`/`.eyebrow`/`.card`/`.btn-primary`/`.seg`/`.pill`/`.w` 原语，见 `index.html` line 41-104）之上，把视觉质感推到「每日外刊精读」（Lexile）水准。
>
> **诊断（一句话）**：Speak 已搬了外刊的全套 token，但**组件层几乎没用**——中文标题 0 处衬线、字重全挤在 600、eyebrow 散成手写小标签、橙色铺满 eyebrow/数字/光晕/渐变底/分类 chip、间距用 `6/8/14/16/18/24` 乱跳、圆角 `16/18/20/26` 混用、彩色重投影拉低档次。缺的不是 token，是「把 `.serif` 用到中文大标题 + 字重拉到 700 + eyebrow 成对 + 橙色回收到只剩 CTA/tab + 间距收敛成三档 + 圆角归三档」这几个动作。
>
> **唯一改动文件**：`/Users/gelili/Documents/Claude.English/Speak-website/index.html`（单文件、无构建，直接改 `<style>` 与 `text/babel` 内联）。改完 `python3 -m http.server 8000` 本地验，再 `bash deploy-speak.sh`（无需 bump sw，Speak 不用 service worker）。
>
> **四态走查**：每步改完都要在 浅色 / 深色 / 跟随系统 三态 + 桌面画框/窄屏全屏 下走一遍，重点看金底高亮深色态可读、深色去描边主卡不糊。

---

## 四条核心原则（贯穿全部步骤）

1. **衬线建层级**：所有「页面大标题 / Hero 卡标题 / 英文核心句 / 品牌大数字」一律 `className="serif"` + `fontWeight:700` + 去 `letterSpacing:-0.3` + 去 `fontStyle:'italic'`（外刊衬线正立）。中文正文/说明/按钮维持黑体。serif=主角，sans=配角，分工干净。
2. **用色克制**：橙（`--primary`）只用在「按下去会发生事情」的地方——主 CTA、录音按钮、tab/seg 选中、实时进行态。进度/成就/积累归金（`--gold`），其余全是纸（`--paper/--surface`）与墨（`--ink/--ink-soft/--muted`）。目标配额 ≈ 中性 90% / 金 6% / 橙 4%。
3. **留白节奏**：把散落的 `6/8/10/14/16/18/24` 收敛成三个值——**组间 20、组内 10、卡间 12**；顶部统一 `calc(env(safe-area-inset-top,0px) + 48~56px)`。
4. **精致细节**：圆角归三档（13/20/28，砍掉 16/22）；删彩色重投影；主卡只留 feature 阴影不描边、次卡纯 hairline 描边不阴影；图标统一「圆角方块徽标」`36×36 / radius 11 / --primary-soft 底 / --primary 字`；修 active 缩放冲突 + 加桌面 hover。

---

# 阶段 A — 全局基调（先做，影响全屏，性价比最高）

## A1. 补两个共享样式类（一次性，供全站复用）

在 `<style>` 的 `.eyebrow`（line 71）之后追加：

```css
/* 报刊金色眉标（区块栏目头专用，与灰色 .eyebrow 区分主次） */
.eyebrow-gold { font-size: 11px; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; color: var(--gold); }
/* serif 斜体导语（报刊副标题/导读专用，仅英文 subtitle 用） */
.lede { font-family: var(--serif); font-style: italic; color: var(--ink-soft); line-height: 1.45; }
/* 桌面 hover 浮起（不污染触屏） */
@media (hover:hover) {
  .dk-card { transition: transform .18s ease, box-shadow .18s ease; }
  .dk-card:hover { transform: translateY(-4px); box-shadow: 0 22px 44px -22px rgba(28,43,51,.35); }
}
```

**约定「区块栏目头」统一两行写法**（金色 eyebrow + 衬线中文标题成对，外刊每节都用）：
```jsx
<div className="eyebrow-gold">TODAY'S PRACTICE</div>
<div className="serif" style={{fontSize:18, fontWeight:700, color:t.ink, marginTop:6}}>今日练习</div>
```
**原则**：一屏只让 1~2 个金色 eyebrow（区块头）；次级标签用灰色 `.eyebrow`，避免金色泛滥廉价。

## A2. 修两处全局冲突 / 名实不符

- **active 缩放打架**（line 119-121 全局 `button:active{scale(.975)}` 与 line 75 `.tap:active{scale(.985)}` 叠加）：删掉 line 118-121 的 `@media` 整段，让所有可点元素只走 `.tap`（.985）一条路。
- **`Tokens.shadow.md` 名实不符**（line 169 区，`md` 被映射成 `--shadow-card`，与 `sm` 同档）：把 `md` 改为 `'var(--shadow-feature)'`，让 Hero/今日卡真正比普通卡浮起，恢复主次。

## A3. 圆角归三档（机械替换，立刻显得「设计过」）

- 把 `Tokens.radius`（line 167）**砍掉 16 与 22 档**，只留 `{ sm:13, md:20, lg:28, pill:9999 }`。
- 全站裸数字圆角统一映射（小元素 13 / 卡片 20 / 大卡·弹层 28）：
  - SceneGlyph 容器 `borderRadius:16` → `var(--radius-sm)`（13）
  - 搜索框 `16` → `var(--radius-sm)`
  - 各场景/列表卡 `18` → `var(--radius)`（20）
  - 今日大卡 `26` → `var(--radius-lg)`（28）
  - 弹层 `48`(设备框除外) → `var(--radius-lg)`

## A4. 删全部彩色重投影（最显著去廉价感的单点）

全文搜 `0 12px 32px` / `0 12px 34px` 这类带 `hexA(t.accent,...)` / `hexA(t.sage,...)` 的彩色大扩散阴影：
- 录音按钮（约 line 888）、完成态（约 line 1138）：改中性暖墨 `0 10px 28px -14px rgba(28,43,51,.35)`，主色只留在填充/渐变里，不进阴影。
- 各处内联 `hexA(t.accentDeep,0.5)` 按钮投影：删掉内联，统一改挂 `className="tap btn-primary"`（line 78 已有 `0 8px 20px -12px`）。
- 弹层投影对齐外刊负扩散写法：`0 30px 90px -45px rgba(28,43,51,.45)`。

---

# 阶段 B — 字体层级（全屏标题/数字升级）

> 写法：删 `fontFamily: Tokens.font.zh`，给该元素加 `className="serif"`，`fontWeight` 改 `700`，去 `letterSpacing:-0.3`。

## B1. 页面级大标题 → serif + 700（立竿见影）

| 行号 | 元素 | 现值 | 改为 |
|---|---|---|---|
| ~428 | 问候「早上好，Nova」 | `font.zh, 26, w600, ls:-0.3` | `className="serif" 28, w700` |
| ~627 | 「场景馆」 | `font.zh, 28, w600, ls:-0.3` | `className="serif" 30, w700` |
| ~1409 | 「复练」 | `font.zh, 28, w600, ls:-0.3` | `className="serif" 30, w700` |
| ~716 | 详情标题 `s.title` | `font.zh, 24, w600, ls:-0.3` | `className="serif" 26, w700` |
| ~1144 | 结果标题 | `font.zh, 24, w600, ls:-0.3` | `className="serif" 25, w700` |
| ~460 | 今日卡标题 `today.title` | `font.zh, 22, w600, ls:-0.3` | `className="serif" 23, w700` |
| ~1263 | 我的页「Nova」 | `font.zh, 20, w600` | `className="serif" 21, w700` |

## B2. 小区块标题 → eyebrow 成对（栏目化）

| 行号 | 现状 | 改为 |
|---|---|---|
| ~492 | 「常练场景」`font.zh,17,w600` | `className="serif" 18,w700`（区块标题档） |
| ~458 | 「今日练习」`font.zh,12,w600,ls:1,橙` | `className="eyebrow-gold"`（去手写值） |
| ~801 | 「核心句子·预览」`13,w600,ls:1` | `className="eyebrow-gold"` + 右侧「共 N 句」用 `--muted` |
| ~771/782 | 「使用场景」/「本课将学会」 | `className="eyebrow-gold"` |
| ~1186 | 结果页「最佳句」标签 | `className="eyebrow-gold"` |
| ~1419 | 「待复练」`12,w600,ls:1` | `className="eyebrow-gold"` |
| ~1348 | 「常练场景」(我的页) | `className="eyebrow"`（灰，避免金泛滥） |
| ~724 | tier「难度」标签 `11,w600,ls:1` | `className="eyebrow"`（灰档） |

## B3. subtitle → serif 斜体导语

| 行号 | 现值 | 改为 |
|---|---|---|
| ~461 | 今日卡英文 subtitle `font.en,17,normal` | `className="lede" fontSize:16` |
| ~596 | 场景卡 `s.sub` `font.en,12,normal` | `className="lede" fontSize:13` |
| ~719 | 详情 `s.sub` `font.en,17,normal` | `className="lede" fontSize:16` |
| ~503 | 常练场景小卡 `s.sub,11` | 小卡可保 `font.en normal`，避免过碎 |

> 跟读核心英文大句（~line 1012，34px serif/400）已是「文章大标题」等价物，**保持不动**，但去 `fontStyle:'italic'` 改正立。

## B4. 品牌数字 → serif 700 + tabular-nums

| 行号 | 现值 | 改为 |
|---|---|---|
| ~1286 | 打卡「13」天 `font.en,44,w500` | `className="serif" 44,w700, fontVariantNumeric:'tabular-nums'` |
| ~1420 | 复练「N」句 `font.en,36,w500` | `className="serif" 36,w700, tabular-nums` |
| ~1165 | 结果三指标 `font.en,30,w500` | `className="serif" 30,w700, tabular-nums` |
| ~1300 | 我的页统计 `font.en,22,w500` | `className="serif" 22,w700` |

## B5. 正文/说明拉到 400，强化对比

纯说明性灰文案（问候副行 ~431、复练副标 ~1410、「还剩 3 句」~486）weight 不超过 **400**；只有「需强调的实体名/数值」才 600。让 700 标题 vs 400 正文形成清晰两极。

---

# 阶段 C — 用色回收（橙→中性/金/墨）

> 原则：橙只留 §保留处；其余按下表回收。token 本身（`--primary` 橙值）不动，改的是「橙被挂在哪些 className/inline style 上」。

## C1. **保留橙**（识别色，点到为止）

主 CTA `.btn-primary`（line 78/~1871/~293）、录音核心按钮 + 录音环（~886-888）、tab 选中 `.tabbar button.on`（line 95）、seg 选中字 `.seg button.on`（line 83）、「正在录音」实时状态字（~1073）。**判断标准**：当前唯一动作 / 当前导航位置 / 实时进行态。

## C2. eyebrow / 小标签 → `--muted`（中性）或金图标

| 行号 | 当前 | 改为 |
|---|---|---|
| ~458 | 「今日练习」橙字 + 橙 Sparkle | 见 B2 改 `.eyebrow-gold`；Sparkle 图标 `var(--gold)` |
| ~453 | 今日卡橙 radial 光晕 | **直接删整段**（最该砍，给整卡蒙橙） |

## C3. chip / 分类色 → 中性优先

| 行号 | 当前 | 改为 |
|---|---|---|
| ~351 | Chip `accent` tone（橙底橙字） | 默认改 `neutral`（`surfaceAlt`底 + `inkSoft`字）；只「待复练/进行中」状态 chip 才 accent |
| ~370 | SceneGlyph travel = accentSoft 橙 | 改中性墨蓝系/`--ink-soft`，别把品牌橙塞进分类系统 |

## C4. 数字/数据 → 墨黑或金（数字用橙是「平」的重灾区）

| 行号 | 当前 | 改为 |
|---|---|---|
| ~1161 | 「平均相似度 92%」橙 | `var(--ink)`，三数字统一墨黑 |
| ~432 | 「今天也开口 5 分钟」橙 | `var(--ink)` 加粗 或 `var(--gold)` |
| ~1175-1180 | streak「连续 13 天」整块橙底 | 底 `var(--gold-soft)` / 数字 `var(--gold)`（成就=金语义） |
| ~616 | 环形进度旁百分比 `accentDeep` | `var(--ink)` |

## C5. 进度条 / 环 → 金（完成态保 sage）

| 行号 | 当前 | 改为 |
|---|---|---|
| ~506 | 场景卡进度条进行中橙 | `var(--gold)`；完成保 sage 绿 |
| ~610 | 环形 stroke 进行中橙 | 金 或 `--ink-soft` |
| ~998 | Practice 顶部进度条橙 | `var(--gold)`（或保留橙，实时态，优先级低） |

## C6. 光晕 / 渐变底 / 装饰 → 删或改中性（看不见的橙污染）

| 行号 | 当前 | 改为 |
|---|---|---|
| ~453 | 今日卡橙光晕 | 删（见 C2） |
| ~703 | ScenesScreen 顶部 `accentSoft→透明` | `linear(var(--surface-soft)→透明)` |
| ~1415 | 复练卡 `accentSoft→sageSoft`（橙+绿混） | `linear(var(--surface-soft)→var(--sage-soft))` |
| ~1258 | heatmap `linear(accent→sun)` | 单色金梯度 `gold-soft→gold` |
| ~1121-1123 | 结果页彩屑全橙 | 混入 `--gold`/`--sage`/`--muted` |

## C7. 波形 / 反馈 / 边框 / 登录 → 中性

| 行号 | 当前 | 改为 |
|---|---|---|
| ~952/910 | 「你的」波形橙 | 保留橙（=你的声音）；**「原声」波形改 `--muted`** 形成对比 |
| ~956-957 | 反馈框 accentSoft 底 + accentDeep 字 | `var(--surface-soft)`底 + `var(--ink-soft)`字 |
| ~1019-1021/1484 | 弱读词橙 underline wavy | 改金底 `.w.now`（与外刊核心词高亮统一，去波浪线） |
| ~1205/1888 | 邀请/复习 橙虚线 | `var(--hairline)` 虚线 |
| ~1210-1212/1492 | Refresh 圆底 accentSoft + 橙图标 | `--surface-soft`底 + `--muted`图标 |
| ~1822/1850-1851 | 登录「超管」橙字/验证码橙边 | `--ink-soft`/`--muted`（登录越中性越稳） |

---

# 阶段 D — 留白节奏

## D1. 四屏顶部统一安全区

| 行号 | 当前 | 改为 |
|---|---|---|
| Home | `padding:'70px 20px 120px'` | `'calc(env(safe-area-inset-top,0px)+56px) 20px 120px'`；问候组与 streak 条间留 16 |
| Scenes ~626 | 标题区 `'70px 20px 8px'` | `'calc(env(safe-area-inset-top,0px)+52px) 20px 14px'`（底 8→14） |
| Detail ~701 | hero `'62px 20px 28px'` | `'calc(env(safe-area-inset-top,0px)+48px) 20px 30px'`，glyph 行 `marginBottom:20` |
| Me | 头像区 `'62px 20px 20px'` | `'calc(env(safe-area-inset-top,0px)+48px) 20px 22px'` |

## D2. 分组间距收敛（最该改 — MeScreen 节奏最乱）

- **MeScreen**（line ~1306/1329/1347/1367）：5 个 section 全是 `'6px 20px 14px'`，相邻只隔 20 且无层级 → **全改 `'20px 20px 0'`**；头像区下 streak 卡 `'0 20px 14px'` → `'22px 20px 0'`。底部由外层 `120` 兜底。**收益最大。**
- **HomeScreen**：继续卡 `marginBottom:24`（~478）→ `20`（消突变）；卡片块之间统一 20；「常练场景」分组前留 24；标题→网格 10。
- **ScenesScreen**：工具区纵向 padding 收一个稳定步进——板块 `'10px 20px 6px'`、搜索 `'10px 20px 6px'`、级别 `'10px 20px 0'`、chips `'10px 20px 16px'`。

## D3. 卡间距与卡内 padding

- 所有列表/网格 `gap:10` → `gap:12`（Scenes ~667、Home ~495、Detail 三宫格 ~754）。外刊全站 11-12，更通透。
- Detail 核心句子每句 `'12px 16px'` → `'14px 16px'`（~806）；metric 卡 `'14px 12px'` → `'16px 12px'`（~761）。
- Scenes 列表卡 `padding:14` → `'15px 16px'`，内 `gap:14` 保留（glyph 52px 占满后文字区局促）。

## D4. 分组小标题降一档（呼吸）

SceneDetail 现「`fontSize:13, letterSpacing:1, color:inkSoft`」方向对但偏大偏深，降到 → `fontSize:12, fontWeight:600, letterSpacing:'.06em', color:t.inkMuted, marginBottom:10`（中文做不了大写，靠字距撑标签感）。

---

# 阶段 E — 精致细节

## E1. 主卡 / 次卡 分层纪律（外刊「描边 OR 阴影」二选一）

- **主卡**（今日卡 ~448、结果页大卡）：去 `border`，只留 `var(--shadow-feature)`。
- **次级网格卡**（常练 ~498、场景列表 ~585）：保 `1px solid t.line`、**不加阴影**，靠 `--surface` 比 `--paper` 亮一档分层。
- **深色补描边**：去了 border 的主卡，深色态投影不可见会糊 → `style={{ border: DARK() ? '1px solid var(--hairline)' : 'none' }}`。

## E2. 列表内分隔 + Sheet 抓手（外刊招牌细节）

- 「我的」设置列表、结果页明细：改用**行间 `borderBottom:1px solid var(--hairline)`（末行 none）的单卡内分隔**，而非每行一张独立描边卡。（Detail「本课将学会」~787 已做对，推广它。）
- 所有底部面板 grabber 统一 `width:38, height:5, background:'var(--hairline)', borderRadius:99, margin:'0 auto 14px'`。

## E3. 图标统一「圆角方块徽标」

功能图标底由 `borderRadius:9999` 纯圆橙底 → `36×36 / borderRadius:11 / background:'var(--primary-soft)' / color:'var(--primary)'`（完成态换 `--good`）。继续卡左侧图标（~475-489）、我的页设置行、stat 卡图标统一此规格。

## E4. SceneGlyph 线性化（与 Icon 体系统一）

`Icon`（line 222-237）已对齐外刊（1.8 描边/round/currentColor），保持。SceneGlyph（~368）是彩色填充几何块，与线性 Icon 两套语言 → 改成与 Icon 同款**线性单色描边几何**（`fill:none, stroke:c.fg, sw:1.8, round`），背景盒保留柔色 `c.bg`。`school/social/urgent` 硬编码十六进制（~370-374）抽成 token 或集中常量（现手写 DARK() 分支是隐患）。`Icon` 默认 `sw` 收敛 1.8（chevron/箭头需 2 的保留）。

## E5. 桌面 hover + tap 过渡

- 给场景卡/今日卡挂 `className="... dk-card"`（A1 已定义），桌面 `translateY(-4px)+加深阴影`。
- 主卡 `.tap` 过渡补 `box-shadow .18s`，避免按下时阴影骤变闪。

---

# 关键屏增量（在 A~E 全局改完后逐屏精修）

> 前置：A~E 的 token/原语/配色/间距/圆角全部落地后，本节才有类可用。

## 屏 1 — HomeScreen 今日大卡（首屏门面）
- 问候行：eyebrow 日期（A1）+ `.serif 28` 问候 + 右上 streak pill（streak 从整条胶囊带收成右上一颗）。
- 今日卡：**删橙光晕** → SceneGlyph + `.eyebrow-gold` 小标 + `.serif 23` 标题 + 英文引句 `.lede`/serif 正立 + meta 改「图标+文字」标签栏（不再三色 chip，难度用一颗 `--primary-soft` pill）+ CTA 换 `.btn-primary`（圆角 14，不再 9999）。

## 屏 2 — SceneDetailScreen
- header 去饱和橙底 → `linear(var(--primary-soft)→透明)` + 圆形 `--surface` 描边返回钮 + eyebrow 来源 + `.serif 25` 标题。
- 难度档位 → `.seg` 分段控件（每片两行：label + 「N 句」）。
- 三卡（时长/句子/难度）→ `.card` + `shadow-card`，**数字 `.serif`**，label `--muted`，图标 `--primary`。
- 三区块小标全 `.eyebrow-gold`；核心句预览英文 `.serif 17` 正立；勾选圆改 `--primary-soft`/`--good`。
- 底部 CTA 玻璃条按钮换 `.btn-primary`，分隔线 `--hairline`。

## 屏 3 — PracticeScreen（核心屏，增量最大）
- **核心英文大句 → `.serif` 正立 + 金底荧光笔**：复用 `.w` 4 态，weak 词从橙波浪线 → 金底 `.w.now`（深色自动切深字）。这是「一看就是外刊」最强单点。
- 中文提示小标 → `.eyebrow`；进度条 fill → `--gold` 或 `--primary`，计数 `tabular-nums`。
- 速度切换 → `.seg`；「听示范」→ `.card` 风圆角 14 + `--hairline` 描边 + `--primary` 图标。
- 录音球 radial 保橙（核心动作）；状态「正在录音」`--primary`、「很棒」`--good`；下一句钮 `.btn-primary`（未激活 `.is-off`）。
- FeedbackCard：`.card`+`shadow-card`，「92%」数字 `.serif`，「原声」波形 `--muted`/「你的」`--gold`，weak 提示底 `--gold-soft`。

## 屏 4 — MeScreen
- 头部：Rosie 圆角方块头像 + `.serif 22` 名 + `--muted` 副行 + 圆形描边设置钮。
- 连续打卡卡：**删 sage 光晕** → 金渐变卡 `linear(var(--gold-grad-from)→var(--gold-soft))` + `.serif 42` 数字 + PlantIcon。
- 三 stat 卡：`.card`+`shadow-card`，`.serif 23` 数字，图标三色（天数=金/已练句=墨蓝/完成=墨绿）。
- Heatmap：空格 `--paper-2`、深浅三级到 `--good`、**今日格 `--gold` 1.5px 框**（去橙框）。
- 外观行：emoji 🌗 → 圆角方块月亮徽标；设置/常练场景列表 → `.card` + `--hairline` 行内分隔（E2）。

---

# 实施顺序总览（共 5 阶段）

| 阶段 | 内容 | 性价比 |
|---|---|---|
| **A 全局基调** | 补 `.eyebrow-gold`/`.lede`/`.dk-card`；修 active 冲突 + shadow.md；圆角归三档；删彩色重投影 | 影响全屏，先做 |
| **B 字体层级** | 大标题/小标题/subtitle/数字/正文 五类升级 serif+700+eyebrow | 立竿见影 |
| **C 用色回收** | 橙→中性/金/墨（光晕/数字/streak/进度/边框/登录） | 去廉价感 |
| **D 留白节奏** | 顶部安全区 + 组间20/组内10/卡间12 + 小标降档 | 呼吸感 |
| **E 精致细节** | 主次卡分层 + 列表内分隔 + 圆角方块图标 + SceneGlyph线性化 + hover | 收尾打磨 |
| 关键屏增量 | Home/Detail/Practice/Me 逐屏套用上述类 | 全局完成后做 |

**最优先三步**：① 删全部橙光晕 + 彩色重投影（A4+C6）；② 中文大标题全改 `.serif`+700（B1）；③ 统计数字/streak 去橙 + eyebrow 成对（B2+B4+C4）。这三步改完，层级从「26→13 全黑体 600」拉开成「44→11 serif 700 ↔ sans 400」，橙面积从铺满收回到 CTA/tab，高级感即到位。

---

**参考源**（外刊精确写法）：`/Users/gelili/Documents/Claude.English/Lexile/src/index.css`（`.serif`/`.eyebrow`/`.card`/`.btn-primary`/`.seg`/`.dk-card` 定义）、`Lexile/src/screens/HomeScreen.tsx`（今日 hero + GreetRow）、`ProfileScreen.tsx`（stat 卡/Heatmap/ThemeRow 衬线数字）、`PlayerScreen.tsx`（`SentenceBlock` 荧光笔 `.w` 4 态）。
**待改目标**：`/Users/gelili/Documents/Claude.English/Speak-website/index.html`（token line 41-104；Tokens 对象 148-173；各屏行号见上表）。
