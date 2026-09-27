# KET Part 2 · GPT 终审包

> 质检流程:Claude 生成 → DeepSeek v4pro 双卡(**已过,0 修订**) → **GPT 终审(难度 + 全真模拟,本步)**
> 用法:整段复制给 GPT(Codex/ChatGPT),结果贴回给 Claude 修订。

---

## 终审任务(Prompt)

你是资深剑桥 **KET (A2 Key)** 口语考官兼命题专家,熟悉 Cambridge English 官方口语题库与评分标准。

下面是为「KET 口语跟读备考 App」新编的 **6 个话题的 Part 2 内容**。背景:此前 KET 只有 Part 1(考官问 + 考生答),缺 Part 2;现补上。真实 KET Part 2 = **两名考生看提示卡互相讨论**(提建议 → 回应 → 表态 → 达成一致),不是独白。内容已过 DeepSeek 双卡(地道性 + A2难度)。请你做**最终把关**,只聚焦两点:

## 终审一 · 难度是否精准匹配 A2
- 每句是否精准落在 **A2**?有没有偏难(像 B1+)或偏易(像 A1)?
- 是否用了 KET 该有的功能句(Let's / How about / Shall we / Good idea / I like...)?
- 青少年考生能否**照着模仿说出来**?(这是跟读素材,不是炫技范文)

## 终审二 · 是否全真模拟 KET Part 2
- 是否像真实 KET Part2 的**双人讨论**:有来有回、互相回应、最后达成一致?
- 每个话题的讨论任务是否符合 Cambridge 常考的 Part2 任务类型?
- 考法提示(task)是否准确、实用?

## 请这样输出
逐话题:①难度评级(A1偏易/A2达标/B1偏难) ②需修改的句子(标 `[话题id#句号]` + 问题 + 建议) ③全真模拟度(像不像真 KET Part2)
最后一句总评:这 6 个 Part 2 作为 KET 备考跟读内容,难度与全真模拟度是否合格。

---

## 待终审内容(6 话题 · 42 句)

### 话题 1:周末做什么 — Free time and hobbies
`ket-hobbies`

**Part 2 讨论任务**:**Part 2** 你和另一位考生讨论周末一起做什么 —— 提建议、说喜好、定下计划。

**Part 1(已有,供参考语境)**

1. `[考生]` What do you usually do at the weekend?
2. `[考官]` I often play basketball with my friends.
3. `[考生]` That sounds fun. Do you like reading?
4. `[考官]` Yes, I read books in the evening.
5. `[考生]` What kind of music do you like?
6. `[考官]` I love pop music. How about you?
7. `[考生]` I like rock music a lot.
8. `[考官]` Maybe we can go to a concert together.

**Part 2 双人讨论(待终审)**

1. `[考生A]` Let's do something together this weekend.
   > 这周末我们一起做点什么吧。
2. `[考生B]` Good idea! How about going to the cinema?
   > 好主意！去看电影怎么样？
3. `[考生A]` I like films, but the weather is really nice.
   > 我喜欢电影，不过天气这么好。
4. `[考生B]` You're right. Shall we go to the park instead?
   > 你说得对。那我们改去公园好吗？
5. `[考生A]` Yes! We can play badminton there.
   > 好啊！我们可以在那儿打羽毛球。
6. `[考生B]` Great. Let's meet at two o'clock.
   > 太好了。我们两点见吧。
7. `[考生A]` Perfect. See you at the park gate!
   > 好的。公园门口见！

---

### 话题 2:在快餐店点餐 — Ordering at a café
`ket-food`

**Part 2 讨论任务**:**Part 2** 你和另一位考生一起决定点什么吃 —— 说喜好、提建议、达成一致。

**Part 1(已有,供参考语境)**

1. `[考生]` Are you ready to order?
2. `[考官]` Yes. I'd like a cheeseburger, please.
3. `[考生]` Would you like anything to drink?
4. `[考官]` Can I have an orange juice?
5. `[考生]` Sure. Anything else?
6. `[考官]` No, that's all, thank you.
7. `[考生]` Okay. Your food will come soon.
8. `[考官]` Thank you very much.

**Part 2 双人讨论(待终审)**

1. `[考生A]` I'm really hungry. What shall we order?
   > 我好饿。我们点什么？
2. `[考生B]` How about a pizza? We can share one.
   > 披萨怎么样？我们可以合吃一个。
3. `[考生A]` Good idea. I don't like mushrooms, though.
   > 好主意。不过我不喜欢蘑菇。
4. `[考生B]` No problem. Let's get a cheese one.
   > 没问题。我们点芝士的吧。
5. `[考生A]` And some juice, please. I don't drink cola.
   > 再来点果汁吧。我不喝可乐。
6. `[考生B]` OK. Two orange juices and one pizza.
   > 好。两杯橙汁，一个披萨。
7. `[考生A]` That sounds perfect. Let's order now.
   > 听起来很棒。我们现在点吧。

---

### 话题 3:假期去哪玩 — Holidays and travel
`ket-holidays`

**Part 2 讨论任务**:**Part 2** 你和另一位考生商量假期去哪玩 —— 提议、比较、说理由、定下来。

**Part 1(已有,供参考语境)**

1. `[考官]` Do you like going on holiday, Lily?
2. `[考生]` Yes, I love it! I went to the beach last summer.
3. `[考官]` That sounds fun. What did you do there?
4. `[考生]` I swam in the sea and built sandcastles with my sister.
5. `[考官]` Nice! Do you prefer the beach or the mountains?
6. `[考生]` The beach, definitely. What about you, Tom?
7. `[考官]` I like the mountains. I went skiing there last winter.
8. `[考生]` Wow, that sounds exciting! I'd love to try skiing.

**Part 2 双人讨论(待终审)**

1. `[考生A]` Where shall we go for the holiday?
   > 假期我们去哪儿呢？
2. `[考生B]` How about the beach? I love swimming.
   > 去海边怎么样？我喜欢游泳。
3. `[考生A]` The beach is fun, but it's very hot in summer.
   > 海边很好玩，但夏天很热。
4. `[考生B]` That's true. We could go to the mountains.
   > 确实。我们可以去山里。
5. `[考生A]` I like that. It's cooler and we can walk a lot.
   > 我喜欢这个。凉快，还能多走走。
6. `[考生B]` Let's go for three days in July.
   > 我们七月去三天吧。
7. `[考生A]` Great! I'll ask my parents tonight.
   > 太好了！我今晚问问爸妈。

---

### 话题 4:喜欢的运动 — Sports and games
`ket-sports`

**Part 2 讨论任务**:**Part 2** 你和另一位考生决定一起做什么运动 —— 说擅长什么、提建议、约时间。

**Part 1(已有,供参考语境)**

1. `[考官]` What sports do you like, Lily?
2. `[考生]` My favourite sport is swimming. I go to the pool every weekend.
3. `[考官]` That's great. Do you play any team sports?
4. `[考生]` Yes, I play basketball with my friends after school.
5. `[考官]` How often do you practise?
6. `[考生]` About twice a week. I'm not very good, but it's really fun.
7. `[考官]` Do you like watching sports on TV too?
8. `[考生]` Sometimes. I love watching football with my dad.

**Part 2 双人讨论(待终审)**

1. `[考生A]` Do you want to play a sport after school?
   > 放学后想一起运动吗？
2. `[考生B]` Sure! How about basketball?
   > 当然！打篮球怎么样？
3. `[考生A]` I'm not very good at basketball, sorry.
   > 抱歉，我篮球不太好。
4. `[考生B]` That's OK. What sports do you like?
   > 没关系。你喜欢什么运动？
5. `[考生A]` I'm better at swimming and running.
   > 我游泳和跑步更擅长。
6. `[考生B]` Then let's go running in the park. It's free!
   > 那我们去公园跑步吧。还免费！
7. `[考生A]` Good plan. Let's meet at four thirty.
   > 好计划。我们四点半见。

---

### 话题 5:过节啦 — Festivals and celebrations
`ket-festivals`

**Part 2 讨论任务**:**Part 2** 你和另一位考生商量怎么过节 —— 提建议、说传统、一起决定。

**Part 1(已有,供参考语境)**

1. `[考官]` What's your favourite festival, Lily?
2. `[考生]` I love Spring Festival. The whole family gets together.
3. `[考官]` That sounds lovely. What do you usually do?
4. `[考生]` We have a big dinner and my grandma gives us red packets.
5. `[考官]` Nice! Do you eat any special food?
6. `[考生]` Yes, we make dumplings together. They're my favourite.
7. `[考生]` Which festival do you like, Tom?
8. `[考官]` I like Mid-Autumn Festival. We eat mooncakes and watch the moon.

**Part 2 双人讨论(待终审)**

1. `[考生A]` Spring Festival is coming. What shall we do?
   > 春节快到了。我们做点什么？
2. `[考生B]` Let's make dumplings with our families.
   > 我们和家人一起包饺子吧。
3. `[考生A]` I love that! My grandma makes the best ones.
   > 我很喜欢！我奶奶包得最好。
4. `[考生B]` Can we watch the fireworks after dinner?
   > 晚饭后我们能去看烟花吗？
5. `[考生A]` Yes, but it gets very cold at night.
   > 可以，不过晚上很冷。
6. `[考生B]` We'll wear warm coats. It's only one night!
   > 我们穿厚外套。就一个晚上嘛！
7. `[考生A]` OK, let's do both. It'll be a great day.
   > 好，两个都做。会是很棒的一天。

---

### 话题 6:聊聊我的家人 — My family and friends
`ket-family`

**Part 2 讨论任务**:**Part 2** 你和另一位考生商量和家人一起做什么 —— 提建议、说家人喜好、定计划。

**Part 1(已有,供参考语境)**

1. `[考官]` How many people are there in your family, Lily?
2. `[考生]` There are four. I live with my parents and my little brother.
3. `[考官]` Who are you closest to in your family?
4. `[考生]` I'm closest to my mum because she always listens to me.
5. `[考官]` What's your best friend's name?
6. `[考生]` Her name's Amy. We like playing together.
7. `[考官]` What do you do with your family and friends at weekends?
8. `[考生]` We often go to the park or have a picnic.

**Part 2 双人讨论(待终审)**

1. `[考生A]` Let's plan something with our families.
   > 我们和家人一起安排点活动吧。
2. `[考生B]` How about a picnic in the park?
   > 去公园野餐怎么样？
3. `[考生A]` My little brother would love that.
   > 我弟弟一定很喜欢。
4. `[考生B]` Great. My mum can make sandwiches.
   > 太好了。我妈妈可以做三明治。
5. `[考生A]` And my dad can bring the football.
   > 我爸爸可以带足球来。
6. `[考生B]` Shall we go on Saturday morning?
   > 我们周六早上去好吗？
7. `[考生A]` Yes! I'll tell my family tonight.
   > 好！我今晚告诉家里人。

---

