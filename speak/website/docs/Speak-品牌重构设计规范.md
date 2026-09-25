# Speak 品牌重构设计规范

> 目标:把 Speak·原版娃口语的视觉全面对齐「每日外刊精读」品牌——**暖米纸张 + 墨蓝 primary + 金 gold + 衬线标题 + 纸面报刊质感 + data-theme 暖墨夜读 + 金色荧光笔逐词高亮**,做到「一看就是同一家公司」。
> 约束:Speak 是**单文件 `index.html`**(React 18 UMD + Babel standalone 浏览器编译,无构建)。本规范按「保持单文件、只重写视觉层」设计——重构集中在三处:`<head>` 内的 `<style>` 全局 CSS、`Tokens` JS 对象、各组件的内联样式。**逻辑层(状态机、scenes.json 加载、跟读 setTimeout 流程、双板块 KET/PET/FCE)一律不动。**
>
> 核心原则(抄自外刊):**单一 CSS 源**。所有颜色走 CSS 变量,`:root`(浅)+ `:root[data-theme="dark"]`(深)两套覆盖;`<html data-theme>` 由 JS 落属性。组件不再靠 `t === Tokens.palettes.dusk` 判断暗色分支,改为「全部颜色引用 CSS 变量,主题切换只换 `data-theme`」。这把当前 prop-drilling 的 `t` 体系彻底简化掉。

> ⚠️ **用户决策校准(2026-06-28,本规范生成后追加)**:产品定位「与外刊统一品牌、但保留一个口语专属强调色」。**`--primary` 用温暖橙(不用本规范正文写的墨蓝 `#0f3a52`)**,作为 Speak 的口语识别色;其余 token(纸张暖米 / 金 gold / 衬线 / 纸面质感 / `data-theme` 深浅 / 荧光笔)全部照本规范统一外刊。墨蓝气质由 `--ink #1c2b33`(墨蓝黑文字)承载,够"同一家公司"。橙取值见实施:浅色 `--primary:#c0531c`(深赤陶橙,配白字大文本可读)/`--primary-2:#9b3f12`(渐变深端)/`--primary-soft:#f8e4d6`;深色 `--primary:#e8945c`/`--primary-soft:#3a2417`。正文凡 `#0f3a52→#1b5570` 的墨蓝渐变,一律替换为橙渐变 `var(--primary)→var(--primary-2)`。落地后截图校准饱和度与对比度。
>
> **单文件迁移技巧(降低改动量)**:不逐处把 `t.accent` 改成字符串,而是把 `Tokens.palettes` 收敛成**单一 `t` 对象、每个颜色键的值改为 `'var(--xxx)'` 字符串**(如 `accent:'var(--primary)'`)。组件里 `style={{color:t.ink}}` 等**保持不动**,深浅由 `data-theme` 在 CSS 层自动切换。只需额外清掉 `t === Tokens.palettes.dusk ? A : B` 这类判断分支(改单值)。`t.font`/`t.radius` 与主题无关,原样保留。

---

## 0. 重构的根本架构决策(先读这条)

当前 Speak 用 `palette` state + prop-drilled `t` 对象,组件里到处 `t.accent`、`t === Tokens.palettes.dusk ? ... : ...`。外刊不是这么做的——**外刊把所有颜色固化为 CSS 变量,深浅只是 `<html>` 上的一个属性**,JSX 里写 `var(--primary)` 即可,不需要知道当前是深是浅。

**本次重构同时做这件事**:把 Speak 从「JS 调色板对象」迁移到「CSS 变量 + data-theme」。落地方式:

1. `<style>` 里新增 `:root { ... }` 与 `:root[data-theme="dark"] { ... }` 两套变量(见 §1)。
2. `Tokens` 对象**保留但瘦身**:`Tokens.font` / `Tokens.radius` 保留(它们与主题无关);`Tokens.palettes` **删除**,改为不再传 `t` 颜色,组件内联样式把 `t.accent` 全替换成 `'var(--primary)'` 这类字符串。
3. 过渡期可保留 `t` 形参签名不删(减少 diff),但 `t` 仅承载 font/radius;所有 `t.accent`/`t.surface` 等颜色访问改成 CSS 变量字符串。

> 若想最小改动:也可保留 `t` 对象,把 `Tokens.palettes.cream/dusk` 的值原地替换成外刊色值(见 §1 末「最小改动备选」)。但**推荐走 CSS 变量路线**,因为它才能正确支持「跟随系统」三态(纯 JS 调色板做不到首帧防闪 + 系统跟随)。

---

## 1. 品牌 Token 表

### 1.1 落到单文件的 CSS 变量(放进 `<head>` 的 `<style>`)

```css
:root {
  color-scheme: light;
  /* —— 纸张 / 表面 —— */
  --paper:        #ece6d9;   /* 页面纸张底（替换旧 cream.bg #F7F2EA） */
  --paper-2:      #dad2c2;   /* 次底 / 轨道 / 禁用底（替换旧 surfaceAlt #F1EADD） */
  --surface:      #fcfaf4;   /* 卡片表面（替换旧 surface #FFFBF5） */
  --surface-soft: #f2ede2;   /* 柔表面 / 分段槽底 */
  /* —— 主色 墨蓝（替换旧橙 accent #E8794B） —— */
  --primary:      #0f3a52;
  --primary-2:    #1b5570;   /* 渐变深端（按钮硬编码端点） */
  --primary-soft: #e4ecef;   /* 主色浅底（替换旧 accentSoft #FBE5D6） */
  /* —— 金 强调 —— */
  --gold:         #c8a24a;
  --gold-soft:    #f1e7c9;   /* 金浅底（可承接旧 sun/sunSoft 用途） */
  --gold-grad-from:#fdf8ec;  /* 金高级卡渐变浅端 */
  /* —— 文字 —— */
  --ink:          #1c2b33;   /* 主文字（替换旧 ink #2B2722） */
  --ink-soft:     #45555e;   /* 次级（替换旧 inkSoft #6E665A） */
  --muted:        #8a8273;   /* 弱化 / 占位（替换旧 inkMuted #A59C8E） */
  --hairline:     #e5ddce;   /* 分隔线 / 描边（替换旧 line rgba(43,39,34,.08)） */
  /* —— 语义 —— */
  --good:         #2e7d5b;   /* 正确 / 完成（替换旧 sage #7A9A7E，但更墨绿学术） */
  --good-soft:    #dfe9e1;   /* 完成浅底（替换旧 sageSoft） */
  --bad:          #b5562f;   /* 错误（替换旧 danger #C96553） */
  /* —— tabbar 玻璃底 —— */
  --tabbar-bg:    rgba(252,250,244,.92);
  /* —— 荧光笔高亮上的文字（金高亮恒浅，故文字恒深） —— */
  --hl-ink:       #1c2b33;
  /* —— 圆角 —— */
  --radius:       20px;
  --radius-sm:    13px;
  --radius-lg:    28px;
  /* —— 阴影（暖墨调，非中性灰） —— */
  --shadow-card:    0 2px 12px -8px rgba(28,43,51,.2);
  --shadow-feature: 0 12px 34px -18px rgba(28,43,51,.4);
  /* —— 字体 —— */
  --serif: Georgia, "Times New Roman", "Songti SC", serif;
  --fs: 16px;
  --lh: 1.7;
}

:root[data-theme="dark"] {
  color-scheme: dark;
  --paper:        #15120c;
  --paper-2:      #221d15;
  --surface:      #211c14;
  --surface-soft: #2a2418;
  --primary:      #4ca0c8;   /* 中调天青：既当卡片底配白字，又当深底强调文字 */
  --primary-2:    #1b5570;   /* 渐变深端不随主题变 */
  --primary-soft: #173742;
  --gold:         #d4b264;
  --gold-soft:    #38301c;
  --gold-grad-from:#2c2517;
  --ink:          #ece5d6;
  --ink-soft:     #b4ac9c;
  --muted:        #8f8674;
  --hairline:     #332c20;
  --good:         #57b389;
  --good-soft:    #1f3329;
  --bad:          #df8059;
  --tabbar-bg:    rgba(28,24,16,.92);
  /* --hl-ink 不覆盖（金高亮恒浅，深字仍可读） */
  --shadow-card:    0 2px 12px -8px rgba(0,0,0,.6);
  --shadow-feature: 0 14px 36px -18px rgba(0,0,0,.7);
}
```

### 1.2 逐项对照表(Speak 旧值 → 外刊新值)

| 角色 | Speak 旧(cream) | 外刊浅色 | 外刊深色 |
|---|---|---|---|
| 页面底 | `#F7F2EA` | `--paper #ece6d9` | `#15120c` |
| 次底/轨道 | `#F1EADD` | `--paper-2 #dad2c2` | `#221d15` |
| 卡片表面 | `#FFFBF5` | `--surface #fcfaf4` | `#211c14` |
| 分段槽底 | (无,用 surfaceAlt) | `--surface-soft #f2ede2` | `#2a2418` |
| **主品牌色** | **橙 `#E8794B`** | **墨蓝 `--primary #0f3a52`** | `#4ca0c8` |
| 主色浅底 | `#FBE5D6` | `--primary-soft #e4ecef` | `#173742` |
| 强调金 | `#E8B84B`(sun) | `--gold #c8a24a` | `#d4b264` |
| 金浅底 | `#F7EBC7` | `--gold-soft #f1e7c9` | `#38301c` |
| 主文字 | `#2B2722` | `--ink #1c2b33` | `#ece5d6` |
| 次文字 | `#6E665A` | `--ink-soft #45555e` | `#b4ac9c` |
| 弱文字 | `#A59C8E` | `--muted #8a8273` | `#8f8674` |
| 描边 | `rgba(43,39,34,.08)` | `--hairline #e5ddce` | `#332c20` |
| 完成/成功 | `#7A9A7E`(sage) | `--good #2e7d5b` | `#57b389` |
| 错误 | `#C96553` | `--bad #b5562f` | `#df8059` |
| theme-color meta | `#F7F2EA` | `#ece6d9` | `#15120c` |

### 1.3 字体 Token(改 `Tokens.font` + `<head>` 字体引入)

| 用途 | 旧值 | 新值(对齐外刊) |
|---|---|---|
| 中文/正文 | `"PingFang SC"...` | `-apple-system, "PingFang SC", "SF Pro Text", system-ui, sans-serif` |
| **英文大标题/核心句** | **`"Instrument Serif", italic`** | **`Georgia, "Times New Roman", "Songti SC", serif`(`--serif`,不用斜体)** |
| 序号/字母 | `enSans` | 保留(系统无衬线) |

**关键改动**:
- `<head>` 删除 `Instrument Serif` 的 Google Fonts `<link>`(L15)——外刊用 Georgia 系统衬线,**零网络字体**,更快更稳。`JetBrains Mono` 也可删(几乎没用)。
- 全站把 `fontStyle:'italic'` 去掉。外刊衬线标题是**正立 Georgia**,不是斜体。斜体是旧 Speak 的强签名,必须清除以「一看就是外刊」。

### 1.4 最小改动备选(若暂不迁 CSS 变量)
保留 `t` 体系,把 `Tokens.palettes.cream` 各键替换为上表浅色值、`dusk` 替换为深色值,并把 `accent→primary 墨蓝`、`sage→good 墨绿`。**但此路无法做「跟随系统」三态与首帧防闪**,且 dusk 仍是按钮切换而非 data-theme。仅作为时间紧张时的临时方案,最终应迁到 §1.1 + §3。

---

## 2. 逐组件映射表

> 通则:卡片圆角 `--radius`(20),按钮圆角 14px,药丸 999px。所有颜色写 `var(--xxx)`。可点元素挂 `.tap`。

### 2.1 把这些外刊原语 CSS 整段搬进 `<style>`(新增,组件复用)

```css
.serif       { font-family: var(--serif); }
.card        { background: var(--surface); border-radius: var(--radius); }
.tap         { cursor:pointer; user-select:none; transition: transform .12s ease, opacity .12s ease; }
.tap:active  { transform: scale(.985); opacity:.85; }
.pill        { display:inline-flex; align-items:center; border-radius:999px; }
.eyebrow     { font-size:11px; font-weight:700; letter-spacing:.14em; text-transform:uppercase; color:var(--muted); }

.btn-primary, .btn-gold { border:none; border-radius:14px; font-weight:700; cursor:pointer; }
.btn-primary { background:linear-gradient(135deg, var(--primary), var(--primary-2)); color:#fff;
               box-shadow:0 10px 24px -10px rgba(15,58,82,.6); }
.btn-gold    { background:linear-gradient(135deg, #ecd9a3, var(--gold)); color:#5c4716; font-weight:800;
               box-shadow:0 10px 24px -10px rgba(200,162,74,.55); }
.btn-primary.is-off, .btn-gold.is-off { background:var(--paper-2); color:var(--muted); box-shadow:none; cursor:default; }

.seg        { display:flex; background:var(--surface-soft); border-radius:999px; padding:3px; gap:2px; }
.seg button { flex:1; border:none; background:none; padding:9px 14px; border-radius:999px;
              font-size:13px; font-weight:600; color:var(--muted); transition:all .2s; white-space:nowrap; }
.seg button.on { background:var(--surface); color:var(--primary); font-weight:700; box-shadow:0 1px 4px rgba(28,43,51,.12); }

.tabbar        { background:var(--tabbar-bg); backdrop-filter:saturate(180%) blur(14px);
                 -webkit-backdrop-filter:saturate(180%) blur(14px); border-top:1px solid var(--hairline); }
.tabbar button.on { color:var(--primary); }

/* —— 荧光笔逐词高亮（跟读核心，直接对齐外刊 .w） —— */
.w        { transition:background .25s ease, color .25s ease; border-radius:4px; padding:0 1px; }
.w.unread { color:var(--muted); opacity:.5; }
.w.read   { color:var(--ink); opacity:1; }
.w.trail  { color:var(--hl-ink); background:rgba(200,162,74,.22); }
.w.now    { color:var(--hl-ink); background:rgba(200,162,74,.5); }
:root[data-theme="dark"] .w.trail { background:rgba(212,178,100,.16); }
:root[data-theme="dark"] .w.now   { color:#1c2b33; background:rgba(216,182,105,.88); }
.plain-read .w.unread { color:var(--ink); opacity:1; }
```

### 2.2 组件逐一映射

| Speak 组件 | 现状(旧) | 改成(外刊语言) |
|---|---|---|
| **`PrimaryButton`** | 橙实底 + 全圆角 9999 + 橙光晕 | `.btn-primary`:墨蓝 135° 渐变 `#0f3a52→#1b5570`,白字 700,圆角 **14px**(不再 9999),投影 `0 10px 24px -10px rgba(15,58,82,.6)`。禁用挂 `.is-off`。 |
| **`GhostButton`** | 透明 + line 描边 + 9999 | 圆角 14px,`border:1px solid var(--hairline)`,字 `var(--ink-soft)`。次要场景也可用 `.btn-gold`(金渐变,深棕金字 `#5c4716`,800)做第二 CTA。 |
| **`TabBar`** | 浮起药丸条 + 橙选中底 | 改 `.tabbar` 玻璃态:`--tabbar-bg` + `blur(14px)` + 顶 hairline 1px,贴底全宽(不再悬浮药丸)。每项纵向(图标+10.5px 字),未选 `--muted`,选中 `.on`→`--primary` + 文字 700。底 padding 含 `env(safe-area-inset-bottom)`。 |
| **`Chip`** | 4 tone 橙/绿/黄药丸 | `.pill` + 内联皮肤。墨蓝款:`background:var(--primary-soft); color:var(--primary); padding:4px 10px; font-size:12px; font-weight:700`。金款:`background:var(--gold-soft); color:#5c4716`。考试标 `exam`/`新` 用墨蓝款。 |
| **`Seg`(双板块切换)** | 药丸 + accentSoft 选中 | `.seg`:槽 `--surface-soft`,选中片 `--surface` + `--primary` 字 + 浅投影。**「💬 日常对话 / 🎓 剑桥考试」用 `.seg`** 顶部主切换。 |
| **剑桥 KET/PET/FCE 级别选择** | 一排级别 Seg | 同样用 `.seg`(级别 3 项);话题用 `.pill` chips。 |
| **`SceneGlyph`** | 抽象几何 SVG 按 kind 配色 | **保留几何形态,只换配色到墨蓝/金/墨绿体系**:底框 `--surface-soft` 圆角 16,主形 `var(--primary)`,点缀 `var(--gold)`。去掉旧橙/旧 sage。(若有 Rosie 题图资源可换真封面,见 §6,但当前无单场景插画,保留几何即可。) |
| **`PlantIcon`(养成植物)** | 花盆+叶+花,橙/绿/黄 | **保留养成隐喻**(情感价值高),换色:盆 `--surface-soft`/`--hairline` 描边,叶 `var(--good)`,花 `var(--gold)`。不再用旧橙。 |
| **`WaveformMic`(录音按钮)** | 132px 橙 radial 球 + 放射波形 + ringpulse | 球体渐变改墨蓝:`radial-gradient(var(--primary), var(--primary-2))`,波形线 `var(--primary)`;录音中脉冲环 `rgba(15,58,82,.3)`。完成态可点金。 |
| **`AudioBars`/`WaveformRow`** | 跳动条 | 条色 `var(--primary)`;示范波形 `--primary`,「你的」波形 `--gold`。 |
| **`FeedbackCard`(模拟反馈)** | 双波形 + 相似度% + weak 重音 | `.card` + `--shadow-card`;相似度数字用 `.serif`;**weak 词高亮改用 `.w.now` 金底**(不再橙波浪线),或保留 `text-decoration` 但颜色改 `var(--gold)`。 |
| **核心英文大句(Practice)** | 34px Instrument Serif **斜体** | `.serif` **正立** 32–34px `var(--ink)`。逐词包 `<span class="w now/trail/read/unread">`,直接复用 §2.1 荧光笔 4 态。提供「跟读/阅读」双模式:阅读模式给容器加 `.plain-read`。 |
| **`HomeScreen` 今日大卡** | 橙光晕 + 斜体引句 + chip | `.card` + `--shadow-feature`;eyebrow(`今日跟读 · DAILY SHADOWING`)+ `.serif` 标题 + 元信息 `.pill` + `.btn-primary` CTA。右上橙光晕删除或改极淡金 radial。 |
| **`HomeScreen` 问候行** | "早上好,Nova" 斜体 | eyebrow 日期 + `.serif` 26px 正立问候;连读天数用 `.pill`(植物图标 + `var(--good)`)。 |
| **`SceneDetailScreen` header** | accentSoft→透明渐变 | 改 `linear-gradient(var(--primary-soft), transparent)` 或纯纸面 + eyebrow + `.serif` 标题;Tier 档位选择器用 `.seg`(入门/初级/中级/高级);底部 sticky 用 `.btn-primary`。 |
| **`ResultScreen`** | sageSoft 渐变 + 彩纸 + 绿 Check 章 | header 渐变改 `var(--good-soft)→transparent`;完成圆章用 `var(--good)`;统计大数字 `.serif`;「盖章」可引入外刊 `stampDown` 动画(旋转 -11° 落下,见 §3 动效)。streak 卡换墨蓝/金。 |
| **`MeScreen`** | 头像橙→黄渐变 + heatmap 绿深浅 | 头像渐变改 `var(--primary)→var(--gold)`(或直接用 Rosie 头像,见 §6);分段用 `.seg`;heatmap 格子用 `var(--good)` 深浅,今日格高亮 `var(--gold)` 框;统计数字 `.serif`。**新增「外观」行**(深色切换,见 §3)。 |
| **`ReviewScreen`(复练)** | accentSoft→sageSoft 渐变 + 斜体数字 | 大卡渐变改 `var(--primary-soft)→var(--gold-soft)`;数字 `.serif` 正立;错句卡 weak 词改 `var(--gold)` 加粗或 `.w.now` 金底;「一起练」按钮 `.btn-primary`。 |
| **`LoginCard`** | 见 §5 | 见 §5。 |
| **`DemoBanner`/`Toast`/`LoadingScreen`/`LoadErrorScreen`** | 硬编码旧橙/旧米 | **全部改 CSS 变量**:DemoBanner 边框 `var(--gold)`/字 `var(--ink-soft)`;Toast 底 `var(--ink)` `.92` 透明;Loading/Error 字 `var(--muted)`/强调 `var(--primary)`。这些是换肤最易残留旧色的点,逐处清。 |

---

## 3. 主题机制改造(cream/dusk 按钮 → data-theme 三态)

**目标**:从「`palette` state + ☀/☾ 浮动按钮」改成外刊的「`data-theme`(system/dark/light)+ `ra_theme` 风格 localStorage + 首帧防闪」。

### 3.1 localStorage 键
沿用 Speak 命名风格:`ybw.speak.theme`(与已有 `ybw.speak.auth.v1`、`ybw-auth-change` 事件一致),三态值 `'system' | 'dark' | 'light'`,默认 `system`,非法值回落 `system`。

### 3.2 首帧防闪内联脚本(放 `<head>`,在 React/Babel 加载之前同步执行)

```html
<script>
(function(){
  try {
    var pref = localStorage.getItem('ybw.speak.theme') || 'system';
    var dark = pref === 'dark' || (pref === 'system' &&
      window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
    var m = document.querySelector('meta[name="theme-color"]');
    if (m) m.setAttribute('content', dark ? '#15120c' : '#ece6d9');
  } catch(e){}
})();
</script>
```

> 注意:这段必须是**普通 `<script>`**(非 `text/babel`),否则 Babel 未加载时不执行,起不到防闪作用。放在 `<meta theme-color>` 之后、字体 link 附近即可。

### 3.3 React 层逻辑(内联进 `text/babel` 块,替换旧 `palette` 体系)

```jsx
// —— 主题工具（顶部，组件外） ——
const THEME_KEY = 'ybw.speak.theme';
const mql = () => { try { return window.matchMedia('(prefers-color-scheme: dark)'); } catch(e){ return null; } };
const getThemePref = () => {
  const v = localStorage.getItem(THEME_KEY);
  return (v === 'dark' || v === 'light' || v === 'system') ? v : 'system';
};
const resolveTheme = (pref) => pref === 'system' ? (mql()?.matches ? 'dark' : 'light') : pref;
const applyTheme = (pref) => {
  const dark = resolveTheme(pref) === 'dark';
  document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
  const m = document.querySelector('meta[name="theme-color"]');
  if (m) m.setAttribute('content', dark ? '#15120c' : '#ece6d9');
};
const setThemePref = (pref) => {
  localStorage.setItem(THEME_KEY, pref); applyTheme(pref);
  window.dispatchEvent(new CustomEvent('ybw-theme-change'));
};
const cycleThemePref = () => {
  const order = ['system','light','dark'];
  const next = order[(order.indexOf(getThemePref()) + 1) % order.length];
  setThemePref(next); return next;
};
// 启动：跟随系统（仅 pref==='system' 时响应）
(function initTheme(){
  applyTheme(getThemePref());
  const m = mql(); if (!m) return;
  const onChange = () => { if (getThemePref() === 'system') applyTheme('system'); };
  m.addEventListener ? m.addEventListener('change', onChange) : m.addListener(onChange);
})();
```

### 3.4 切换 UI 入口
**删除右上 `.theme-switch` 浮动「☀白天/☾夜晚」按钮**(`Tokens` 叙事 + CSS L64–99 + JSX 两处)。改为对齐外刊:在 **`MeScreen`(我的)** 底部加一行「外观」(`.tap` 整行),右侧显示当前态中文标签(`跟随系统 / 浅色 / 深色`),点击调 `cycleThemePref()`。游客也可用。用 `useEffect` 监听 `ybw-theme-change` 刷新 label。

### 3.5 清理
- 删 `App` 与 `AuthGate` 里的 `palette`/`loginPalette` state 与 `body.theme-dusk` class 切换 `useEffect`(改由 data-theme 驱动;body 背景改成 `body { background: var(--paper); }`、删 `body.theme-dusk` 规则)。
- 组件里所有 `t === Tokens.palettes.dusk ? A : B` 的分支删除——颜色已由 CSS 变量自动随主题切换,JSX 无需再判断深浅。

---

## 4. iPhone 画框去留

**建议:移动端去掉 iPhone 画框,改全屏纸面;桌面靠"限宽居中成纸面"营造质感。** 这与外刊一致(外刊 `IOSFrame.tsx` 仅是开发预览残留,线上未用)。

具体做法(改 `Phone`/`IOSDevice`/CSS):

- **移动端(`<768px`)**:不套 `IOSDevice` 画框、不渲染灵动岛 / home 横条 / 假状态栏 `9:41`。根容器 `.app { width:100%; min-height:100dvh; background:var(--paper); }`。顶部/底部用 `env(safe-area-inset-*)` 接管:页头 `padding-top: calc(env(safe-area-inset-top,0px) + 10px)`,tabbar 底 `padding-bottom: calc(8px + env(safe-area-inset-bottom,0px))`。`html,body,#root` 用 `height:100dvh`(iOS WebView 撑满到底,修底部空白)。
- **`≥768px`**:`.app` 限宽 820、居中,成「纸面」:`body{ background:var(--paper-2); }` 衬底加深,`.app{ background:var(--paper); box-shadow:0 0 0 1px var(--hairline), 0 30px 90px -45px rgba(28,43,51,.45); }`。
- **`≥1024px`(可选,二期)**:`.app` 放宽 1180,左侧可加常驻 sidebar(品牌头 + Rosie + 导航 4 项 + 连读天数)。**一期先不做 sidebar**,只做 820 纸面即可拿到「报刊感」,投入产出最高。

```css
.app { width:100%; min-height:100dvh; background:var(--paper); margin:0 auto; }
@media (min-width:768px){
  body { background:var(--paper-2); }
  .app { max-width:820px; box-shadow:0 0 0 1px var(--hairline), 0 30px 90px -45px rgba(28,43,51,.45); }
}
@media (min-width:1024px){ .app { max-width:1180px; } }
```

> 删除项:`IOSDevice`(L199–226)、`IOSStatusBar`(L181–196)、CSS `.ios-device`/灵动岛/home-indicator(L52–61)。`Phone` 简化为「内容 + TabBar」直接挂 `.app`。

---

## 5. 登录页与品牌头

**对齐外刊登录模板:Rosie 头像 + 衬线产品名 + 灰副标题(居中)+ 墨蓝渐变 CTA。** Speak 登录刚改过,这次再对齐到外刊精确规格。

### 5.1 形态
- **移动端**:底部上滑 sheet,或保留当前白卡(对齐外刊也可整页居中卡)。推荐对齐外刊:遮罩 `rgba(28,43,51,.42)`,面板圆角(sheet 用 `26px 26px 0 0`,居中卡用 22),`sheetUp .3s`(手机)/`popIn .35s`(大屏)。
- **大屏(`≥768`)**:居中对话框,`max-width:460`。

### 5.2 品牌头(登录卡顶部,逐值)
```jsx
<div style={{textAlign:'center', padding:'14px 0 18px'}}>
  <img src="./assets/rosie-icon.png"
       style={{width:54, height:54, borderRadius:15,
               boxShadow:'0 8px 20px -7px rgba(15,58,82,.5)'}}/>
  <div className="serif" style={{fontSize:21, fontWeight:700, color:'var(--ink)', marginTop:10}}>
    原版娃口语
  </div>
  <div style={{fontSize:12.5, color:'var(--muted)', marginTop:4}}>
    手机号验证码登录 · 新用户自动注册
  </div>
</div>
```
- **删除旧「橙 radial 渐变方 + Instrument Serif『原』字印章」**,换成 Rosie 头像(§6)。产品名用 `.serif` 正立。

### 5.3 字段
- 手机号输入:`background:var(--surface); border:1.5px solid var(--hairline); border-radius:13px; padding:11px 14px; font-size:16px; color:var(--ink)`;聚焦 `border-color:var(--primary)`;占位 `var(--muted)`;左侧可放图标。
- 验证码:同款输入 + 右侧内嵌「获取验证码 / 60s」小钮(`background:var(--primary-soft); color:var(--primary)`)。保留旧逻辑(点击自动填 1234、超管 001/218 免码、演示 5 分钟)。
- **主 CTA**:`.btn-primary`(墨蓝渐变,白字 16/700)。**删除旧「深色 ink 底登录按钮」**。
- 演示模式钮:虚线边 `1px dashed var(--gold)`,字 `var(--gold)`(替换旧橙虚线)。
- 底部协议文案 `var(--muted)`。

### 5.4 `<head>` 品牌元信息同步
- `<title>` 改 `原版娃口语`(替换「口语练习 · Shadow」)。
- og:title / og:description 同步换 Speak 品牌文案。
- favicon:删除旧橙 SVG inline icon(L12),换 Rosie:`<link rel="icon" href="./assets/rosie-icon.png">`(或导出小尺寸 png)。
- meta theme-color 由 §3 脚本动态管,初值 `#ece6d9`。

---

## 6. Rosie 形象融入

资产已就位:`/Users/gelili/Documents/Claude.English/Speak-website/assets/rosie-icon.png`(头像/logo,皮克斯风 3D 女性形象,对齐外刊 IP)、`rosie-real.png`(备用)。**与外刊「Rosie = App 图标 = 品牌头像 = AI 外教人设」三位一体的用法完全对齐。**

落地点:
1. **登录品牌头**:`rosie-icon.png` 54×54 圆角 15 + 墨蓝投影(§5.2)。这是 IP 统一的核心。
2. **favicon / apple-touch-icon / og:image**:全部指向 `rosie-icon.png`(§5.4)。
3. **`MeScreen` 头像**:用 `rosie-icon.png` 替代旧「accent→sun 渐变圆 + 字母 N」(或保留用户字母,但默认头像/品牌位用 Rosie)。
4. **AI 外教人设(产品文案)**:跟读反馈、鼓励语署名「Rosie 老师」,与外刊「外教 Rosie」「Rosie 讲解·纯英文」同一 IP。Speak 的鼓励式反馈正好可挂 Rosie 名义。语音若接 TTS 用 ElevenLabs Rosie 声线 `V1sMnmZsNBJuEOA7aVqB`(与外刊统一)。
5. **`≥1024` sidebar 品牌区**(二期):42×42 Rosie + `.serif`「原版娃口语」+ eyebrow 副标。
6. **部署注意**:`deploy-speak.sh` 默认 ship `index.html`/`scenes.json`/`audio/`——**需确认 `assets/` 也被上传**(检查 rsync include/exclude;若被排除需加 `assets/` 到 ship 列表),否则线上 Rosie 404。`Speak-ios/` 也应把同一张 Rosie 复制进各自 icon 体系保持 IP 一致。

---

## 7. 保留 vs 改动清单 + 分步实施顺序

### 7.1 保留(不动)
- 全部业务逻辑:`scenes.json` 加载、`transformScenesJSON`、`playSentenceAudio`/4 声线、跟读 `setTimeout` 模拟流程、`useAuth` mock 鉴权、demo 5 分钟。
- 双板块结构:`💬 日常对话 / 🎓 剑桥考试` + KET/PET/FCE 级别 + 话题筛选(只换视觉到 `.seg`/`.pill`)。
- 7 屏 + 复练 + 我的的页面结构与导航。
- 养成隐喻 `PlantIcon`、几何 `SceneGlyph`(只换配色)。
- 单文件 + UMD + Babel 架构(无构建)。

### 7.2 改动
- Token 体系:橙→墨蓝、奶油→纸张、sage→墨绿、阴影暖墨化(§1)。
- 字体:去 Instrument Serif + 去全站斜体,改 Georgia 衬线(§1.3)。
- 主题机制:cream/dusk 按钮 → data-theme 三态 + 首帧防闪 + 我的页「外观」入口(§3)。
- 去 iPhone 画框,改全屏纸面 + 768 限宽(§4)。
- 登录页对齐外刊 + Rosie 头像(§5、§6)。
- 荧光笔逐词高亮对齐外刊 `.w` 4 态金底(§2.1)。
- 清理全部硬编码旧橙/旧米(DemoBanner/Toast/Loading/Error/body/favicon/meta/og,§2.2 末行)。

### 7.3 分步实施顺序(每步可独立验证)
1. **Token 层**:`<head>` 加 `:root` + `:root[data-theme=dark]` 两套 CSS 变量;搬入 §2.1 原语 CSS;改字体引入(删 Instrument Serif)。此时页面应仍可跑(组件还在用 `t`)。
2. **主题机制**:加首帧防闪脚本 + React 主题工具 + 我的页「外观」入口;删 `.theme-switch` 浮钮与 `palette` state;body 背景改 `var(--paper)`。验证三态切换 + 系统跟随 + 刷新不闪。
3. **基础组件**:`PrimaryButton`/`GhostButton`/`TabBar`/`Chip`/`Seg`/输入框 改成外刊 className/CSS 变量;去 `t===dusk` 分支。
4. **各屏逐个迁**:Home → Scenes(双板块) → SceneDetail → **Practice(荧光笔 4 态 + 正立衬线大句,重点)** → Result(盖章动画) → Me(heatmap/外观) → Review → Login(Rosie 头像)。每屏把颜色换 CSS 变量、去斜体、换几何/植物配色。
5. **去画框 + 响应式**:删 `IOSDevice`/状态栏/灵动岛;`.app` 全屏 + 768 限宽纸面。
6. **清扫硬编码**:DemoBanner/Toast/Loading/Error/favicon/title/og/meta 全部清旧色换 Rosie/变量。
7. **验证**:浅色 + 深色 + 跟随系统 三态各屏走查;移动(全屏)/平板(820 纸面)两形态;跟读高亮金底逐词推进;Rosie 头像加载(确认 `assets/` 已部署);无残留橙色/斜体。`deploy-speak.sh --dry-run` 确认 `assets/` 在 ship 列表。Speak 无 sw.js,无需 bump 缓存版本。

---

### 附:外刊动效 keyframes(可整段搬进 `<style>`,无依赖)
`screenInFwd/Back`(屏间滑入,`.32s cubic-bezier(.22,.61,.36,1)`)、`sheetUp`(`translateY(100%)→0`)、`popIn`(`scale .92→1`+淡入)、`fadeIn`(遮罩)、`stampDown`(盖章 -11° 回弹 `cubic-bezier(.3,1.4,.5,1)`,用于 Result)、`pulse`(呼吸点)、`vw`(波形竖伸缩)。Practice 的 `.w` 过渡与 `.tap` 缩放对 Speak 价值最高。带 `@media (prefers-reduced-motion:reduce)` 兜底。
