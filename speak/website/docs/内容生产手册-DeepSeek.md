# 剑桥内容自助生产手册(DeepSeek v4pro · 不吃 Claude 额度)

> 生成跑 **DeepSeek API**,审稿你**手动贴 ChatGPT**,中间拼接/烧音频是**纯脚本**。Claude 全程可不参与。
> 脚本在 `scripts/`,中间产物在 `_content-drafts/`(都已加进 deploy excludes,不会上公网)。

## 一次扩充话题的完整流程

```bash
cd Speak-website

# 1) 改话题:编辑 scripts/gen_pet_deepseek.mjs 顶部的 TOPICS 列表
#    每条 = { id:'pet-<key>', topicKey:'<key>', theme:'中文主题说明' }

# 2) 生成(DeepSeek v4pro,每话题约 30-50s)→ _content-drafts/pet-content-new.json
node scripts/gen_pet_deepseek.mjs
#    只生成某几条: node scripts/gen_pet_deepseek.mjs pet-health pet-weather

# 3) 自检:脚本自带结构校验(8 句Part1 / 6 句Part2 / 4 模板 / examTip≥60字)
#    再自己读几条英文,确认 B1 级、地道、翻译准

# 4) ★ GPT 终审(别省!):把 _content-drafts/pet-content-new.json 整篇贴给 ChatGPT,
#    让它挑 CEFR 级别/考法编号/地道度/翻译问题,按它的修正改回该文件

# 5) 拼接进 scenes.json(自动查重、补 examTopics 话题键)
node scripts/splice_cambridge_new.mjs _content-drafts/pet-content-new.json PET

# 6) 烧 Rosie 音频 + 补全 rosie 键
node scripts/gen_rosie.mjs pet-health pet-weather pet-entertainment pet-technology pet-work pet-family
node scripts/ensure_rosie_keys.mjs

# 7) 部署
bash deploy-speak.sh --dry-run    # 先看变更(只应新增音频+改 scenes/index)
bash deploy-speak.sh              # 真推;自动备份+修权限
```

## 关键配置(脚本运行时自动读)
- **DeepSeek**:`Lexile/.env` 的 `DEEPSEEK_GEN_API_KEY` + 模型 `deepseek-v4-pro`。推理模型,`max_tokens` 已设 32000(否则 JSON 截断)。
- **Rosie 音频**:`yuanbanwa-vocab/.env` 的 `ELEVENLABS_API_KEY` + `ELEVENLABS_VOICE_ID`(=`V1sMnmZsNBJuEOA7aVqB`)。

## 扩 FCE / 新考试(CAE/IELTS)
复制 `scripts/gen_pet_deepseek.mjs` 改:
- `SYS`(系统提示)改成对应级别考官(FCE=B2 / CAE=C1)。
- `schema` 里的 part2 结构(**FCE=对比两图 7 句**;PET=单图 6 句)。
- `TOPICS` 列表。
- 拼接时 `splice_cambridge_new.mjs <文件> FCE`(第二参数传考试名)。

## 脚本清单
| 脚本 | 作用 |
|---|---|
| `gen_pet_deepseek.mjs` | DeepSeek v4pro 生成 PET 话题(可改成别的考试) |
| `splice_cambridge_new.mjs` | 把生成的话题展开进 scenes.json,查重+补话题键 |
| `gen_rosie.mjs` | 给指定场景烧 Rosie 音频 + 注入 rosie 键(`--all-cambridge`/`--all-daily` 批量) |
| `ensure_rosie_keys.mjs` | parse 遍历补全所有句子的 rosie 键(修 gen_rosie 在"顶层 sentences + tiers"重复时的首匹配漏注入) |
| `review_deepseek.mjs` | (可选)DeepSeek v4pro 二审已有内容 |
| `build_gpt_pack.mjs` | (可选)把内容+审稿打包成 GPT 终审 pack |

## 铁律
1. **文本定稿才烧 TTS** —— 改了某句 EN,要 `gen_rosie.mjs <那个场景id>` 重烧(脚本幂等,已存在的跳过;改了的需先删旧 mp3 再烧)。
2. **GPT 终审别省** —— 它替代了 Opus 交叉验证。实测它抓出过:KET 把生活对话误标「口语 Part 1」、Opus 把 PET 单图描述误判成 Part 3(实为 Part 2)。DeepSeek 自己生成自己审容易自说自话。
3. **剑桥考试编号别搞错**:KET=Part1 面试/Part2 讨论;**PET=Part1 面试 / Part2 单图长说 / Part3 协商 / Part4 讨论**;FCE=Part1 面试/Part2 对比两图/Part3 协作/Part4 讨论。
4. **部署前** `_preview.html` / `scripts/` / `_content-drafts/` / `docs/` 已在 deploy excludes,不上公网。
