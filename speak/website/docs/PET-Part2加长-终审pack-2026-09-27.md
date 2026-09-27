# PET Part 2 独白加长 · 终审 pack · 2026-09-27(v2,已按第一轮独立终审修订)

> 背景:中国学生的英语跟读 App「原版娃口语」,剑桥 B1 Preliminary(PET)备考分区。下面是 12 个 PET 话题的 **Part 2 单人长说(照片描述)示范**,每组已由 Claude 补入 1–3 句可见细节(标 ★),目的是把示范从 6–7 句 / 80–108 词补到 8–10 句 / 117–129 词,接近官方约 1 分钟的口播量。现有句子一字未动。
> 对照尺:`docs/PET-官方题型断言-2026-07-31.md` §四(Part 2 = 描述所见:people/activities/place/other details;简短有画面依据的推断可以,但不能取代描述;不讲故事、不谈社会议题、不转到个人经历)。
> 上一轮体检:`_content-drafts/PET-Part2独白-体检报告-2026-08-01.md`(建议低于 80 词的组各补一条 10–15 词的可见背景细节,不补人物心理推测)。

## 请你(Codex / GPT)做的事

请严格分三步作答:

**第一步**:先凭你对 Cambridge 官方 handbook(2020 revision)的了解,交代 B1 Preliminary Speaking Part 2 的官方任务形态:考生要做什么、考官期待什么、约 1 分钟对应多少口播量、常见失分表现。此步不看下面内容。

**第二步**:对照第一步,逐组判定加长后的示范是否仍符合 Part 2 形态:新句(★)是否都是可见内容;有没有与同组已有句子在画面上矛盾(人物姿势、天气、时间、物品位置);新句插入位置是否破坏「描述 → 简短推断 → 收尾」的组织;整组长度是否合适(不要超过 1 分钟)。

**第三步**:逐句审新句(★)的语言:是否地道自然、B1 难度是否合适、连接方式是否单一(and… and…)、中文翻译是否准确自然。只标真有问题的。

回答最后附严格 JSON:
```json
{"reviews":[{"tid":"话题id","sid":"句id","severity":"必改|建议","issue":"问题(中文)","suggest":"改进英文"}],"groupIssues":[{"tid":"话题id","issue":"整组问题","fix":"处理建议"}],"typeVerdict":"题型判定(中文)","overall":"总评(中文)"}
```

## 12 组全文(★ = 本次新增;v2 文本)

### pet-daily(聊聊日常作息)— 9 句 / 128 词,新增 2 句

1. `part2-1` In the picture, I can see a young woman in her kitchen at home.  〔照片里我能看到一个年轻女人在家里的厨房。〕
2. `part2-2` It looks like it is early in the morning because sunlight is coming through the window.  〔看起来是清晨时分，因为阳光正从窗户照进来。〕
3. `part2-3` She is making breakfast and there is some bread and a cup of coffee on the table.  〔她正在做早餐，桌上有一些面包和一杯咖啡。〕
4. `part2-4` She is wearing comfortable clothes, so I think she has just woken up.  〔她穿着舒适的衣服，所以我觉得她刚起床。〕
5. `part2-5` She looks quite relaxed and maybe a little sleepy.  〔她看起来挺放松的，也许还有点困。〕
6. `part2-7` There is a small plant on the windowsill, and the kitchen looks clean and tidy.  〔窗台上有一盆小植物，厨房看起来干净整洁。〕
7. ★ `part2-8` Behind her, there is a white fridge with a few photos and notes stuck on the door.  〔她身后有一台白色冰箱，冰箱门上贴着几张照片和便条。〕
8. ★ `part2-9` Next to the cooker, there is a kettle and a few clean plates on the counter.  〔灶台旁边的台面上放着一个水壶和几个干净的盘子。〕
9. `part2-6` I think it's a calm and peaceful start to her day.  〔我觉得这是她一天平静而美好的开始。〕

### pet-hobbies(聊聊兴趣爱好)— 9 句 / 117 词,新增 2 句

1. `part2-1` In this picture, there are two boys sitting on the grass in a park.  〔这张照片里有两个男孩坐在公园的草地上。〕
2. `part2-2` One of them is playing the guitar and the other one is singing along.  〔其中一个在弹吉他，另一个在跟着唱。〕
3. `part2-3` It looks like a sunny day because the sky is clear and blue.  〔看起来是个晴天，因为天空湛蓝清澈。〕
4. `part2-4` There are some other people walking behind them, so the park seems quite busy.  〔他们身后还有一些人走过，所以公园看起来挺热闹。〕
5. `part2-7` There is a music book open on the grass in front of them.  〔他们面前的草地上摊开着一本乐谱。〕
6. ★ `part2-8` The boy with the guitar is wearing a blue cap and a white T-shirt.  〔弹吉他的男孩戴着一顶蓝色鸭舌帽，穿着白色T恤。〕
7. ★ `part2-9` In the background, I can see some tall trees and a small pond.  〔背景里我能看到几棵高大的树和一个小池塘。〕
8. `part2-5` I think they are probably good friends who love music.  〔我觉得他们可能是热爱音乐的好朋友。〕
9. `part2-6` They look really happy and they are enjoying their free time together.  〔他们看起来非常开心，正一起享受空闲时光。〕

### pet-travel(聊聊旅行计划)— 9 句 / 124 词,新增 3 句

1. `part2-1` In the picture, I can see a family spending time on a sandy beach.  〔照片里，我能看到一家人正在沙滩上度假。〕
2. `part2-2` There are two children building a sandcastle near the water.  〔有两个孩子在水边堆沙堡。〕
3. `part2-3` It looks like a hot summer day, because everyone is wearing shorts and sunglasses.  〔看起来像是炎热的夏日，因为大家都穿着短裤、戴着墨镜。〕
4. `part2-4` The parents are sitting under a big umbrella and probably watching their children.  〔父母坐在一把大伞下，可能在看着孩子。〕
5. `part2-5` The sea is blue and the sky is clear, so it's a perfect day for the beach.  〔大海是蓝色的，天空很晴朗，所以是去海滩的完美日子。〕
6. ★ `part2-7` The children have a red bucket and a small spade next to them.  〔孩子们旁边放着一个红色的小桶和一把小铲子。〕
7. ★ `part2-8` There are a few other people swimming in the sea a bit further out.  〔远一点的海里还有几个人在游泳。〕
8. ★ `part2-9` Behind the family, I can see some white beach houses and a few palm trees.  〔在这家人身后，我能看到几栋白色的海滨小屋和几棵棕榈树。〕
9. `part2-6` I think they are on holiday and they all look very relaxed and happy.  〔我觉得他们在度假，每个人看起来都很放松、很开心。〕

### pet-shopping(聊聊购物消费)— 8 句 / 120 词,新增 2 句

1. `part2-1` In this picture, there is a woman shopping in a big supermarket.  〔这张照片里有个女人在一家大超市购物。〕
2. `part2-2` She is pushing a shopping trolley and looking at the products on the shelf.  〔她正推着购物车，看着货架上的商品。〕
3. ★ `part2-7` She is wearing a grey jumper and jeans, and she has a handbag on her shoulder.  〔她穿着灰色毛衣和牛仔裤，肩上挎着一个包。〕
4. `part2-3` There are a lot of fruit and vegetables in front of her, so I think she is buying food for the week.  〔她面前有很多水果和蔬菜，所以我觉得她在买这一周的食物。〕
5. `part2-4` The supermarket looks clean and bright, and there are a few other customers behind her.  〔超市看起来干净又明亮，她身后还有几位顾客。〕
6. ★ `part2-8` In her trolley, there are already some bottles of milk and a bag of apples.  〔她的购物车里已经有几瓶牛奶和一袋苹果。〕
7. `part2-5` She is holding a piece of fruit and reading the label carefully.  〔她拿着一个水果，仔细地看着标签。〕
8. `part2-6` I think she wants to choose the freshest products, and she looks quite focused.  〔我觉得她想挑最新鲜的商品，看起来挺专注的。〕

### pet-food(聊聊饮食外食)— 9 句 / 119 词,新增 2 句

1. `part2-1` In the picture, I can see a family having dinner together at home.  〔照片里我能看到一家人在家里一起吃晚餐。〕
2. `part2-2` There are several dishes on the table, including rice, vegetables and some meat.  〔桌上有好几道菜，包括米饭、蔬菜和一些肉。〕
3. ★ `part2-8` There is a white tablecloth on the table, and everyone has a glass of water.  〔桌上铺着白色桌布，每个人面前都有一杯水。〕
4. `part2-3` Everyone is sitting around the table and talking while they eat.  〔大家围坐在桌边，一边吃一边聊天。〕
5. `part2-7` The father is passing a plate of vegetables to a little girl.  〔爸爸正把一盘蔬菜递给一个小女孩。〕
6. `part2-4` The little girl is laughing, so it looks like a happy family meal.  〔小女孩笑着，看起来是一顿开心的家庭晚餐。〕
7. `part2-5` It's probably the evening, because the lights in the room are on.  〔可能是晚上，因为房间里的灯都开着。〕
8. ★ `part2-9` Behind them, I can see a window with the curtains closed and a picture on the wall.  〔他们身后有一扇拉上窗帘的窗户，墙上还挂着一幅画。〕
9. `part2-6` I think they really enjoy spending time together and the food looks delicious.  〔我觉得他们很享受在一起的时光，而且食物看起来很好吃。〕

### pet-school(聊聊学习计划)— 9 句 / 121 词,新增 2 句

1. `part2-1` In this picture, there are some students studying in a quiet library.  〔这张照片里有一些学生在安静的图书馆里学习。〕
2. `part2-2` A girl at the front is reading a thick book and taking notes.  〔前面有个女孩正在读一本厚书并做笔记。〕
3. `part2-3` There are a lot of bookshelves behind them, full of different books.  〔他们身后有很多书架，摆满了各种书。〕
4. `part2-7` On the table, there are some notebooks, pens and a bottle of water.  〔桌上放着一些笔记本、几支笔和一瓶水。〕
5. `part2-4` Some students are using laptops, so I think they are working on a project together.  〔有些学生在用笔记本电脑，所以我觉得他们在一起做一个项目。〕
6. ★ `part2-8` The girl at the front has long dark hair and is wearing glasses and a green jumper.  〔前面那个女孩留着深色长发，戴着眼镜，穿着绿色毛衣。〕
7. ★ `part2-9` There are big windows on one side, and the light from outside makes the room bright.  〔一侧有几扇大窗户，外面的光线让房间很明亮。〕
8. `part2-5` It looks like they are preparing for an important exam.  〔看起来他们在为一场重要的考试做准备。〕
9. `part2-6` They all look very serious and focused, but maybe a little tired too.  〔他们看起来都很认真、很专注，不过也许还有点累。〕

### pet-health(聊聊健康习惯)— 8 句 / 124 词,新增 2 句

1. `part2-1` In the picture, I can see two children playing football in a park.  〔在照片里，我看到两个孩子在公园里踢足球。〕
2. `part2-2` There is also a woman, maybe their mother, sitting on a bench and watching them.  〔还有一个女人，可能是他们的妈妈，坐在长凳上看着他们。〕
3. `part2-3` The boy in a red T-shirt is kicking the ball, while the girl is trying to stop it.  〔穿红色T恤的男孩正在踢球，而女孩正试图拦住球。〕
4. `part2-4` It looks like a sunny day because the sky is clear and there are some trees with green leaves.  〔看起来是晴天，因为天空晴朗，还有一些长着绿叶的树木。〕
5. ★ `part2-7` The girl is wearing a yellow top and white trainers, and her hair is tied back.  〔女孩穿着黄色上衣和白色运动鞋，头发扎在脑后。〕
6. ★ `part2-8` Behind them, there is a playground with a slide and some swings.  〔他们身后有一个游乐场，有滑梯和几个秋千。〕
7. `part2-5` They probably enjoy the game very much, and the woman looks relaxed and happy.  〔他们很可能很享受这场比赛，而那位女士看起来轻松又开心。〕
8. `part2-6` I think spending time outdoors like this is a great way to stay active and have fun.  〔我认为像这样在户外活动是保持活力和享受乐趣的好方法。〕

### pet-weather(聊聊季节与天气)— 10 句 / 123 词,新增 3 句

1. `part2-1` In the picture, there are two children playing in a park.  〔照片里有两个孩子在公园玩耍。〕
2. `part2-2` They are wearing light jackets and scarves, so it looks like it's autumn.  〔他们穿着薄外套和围巾，所以看起来是秋天。〕
3. `part2-3` The sky is grey and there are some leaves falling.  〔天空灰蒙蒙的，有些树叶在飘落。〕
4. `part2-7` There is a wooden bench beside the path behind the children.  〔孩子们身后的小路边有一张木长椅。〕
5. `part2-4` The children are laughing and running, so they seem very happy.  〔孩子们在笑在跑，所以他们看起来很开心。〕
6. ★ `part2-8` One of the children is holding a big yellow leaf in one hand.  〔其中一个孩子一只手里拿着一片大大的黄叶。〕
7. ★ `part2-9` There are some tall trees along the path, and most of them have lost their leaves.  〔小路两旁有几棵高大的树，大多数已经掉光了叶子。〕
8. ★ `part2-10` In the distance, I can see a man walking a dog near the gate.  〔远处，我能看到一个男人在大门附近遛狗。〕
9. `part2-5` I think they are probably enjoying the cool weather.  〔我想他们很可能在享受凉爽的天气。〕
10. `part2-6` The ground is covered with yellow and brown leaves, which makes the park look colourful.  〔地上铺满了黄色和棕色的落叶，让公园看起来色彩斑斓。〕

### pet-entertainment(我的电影与音乐品味)— 7 句 / 124 词,新增 1 句

1. `part2-1` In the picture, there are two friends sitting on a sofa in a cosy living room.  〔在照片中，两个朋友坐在舒适客厅的沙发上。〕
2. `part2-2` They are watching a film on a large TV, and the room is quite dark, so it feels a bit like being at the cinema.  〔他们正在大电视上看电影，房间很暗，感觉有点像在电影院。〕
3. `part2-3` The girl on the left is holding a bowl of popcorn and the boy is pointing at the screen, probably because something funny is happening.  〔左边的女孩拿着一碗爆米花，男孩指着屏幕，可能是因为发生了有趣的事情。〕
4. ★ `part2-7` On the small table in front of them, there are two drinks and a remote control.  〔他们面前的小桌上放着两杯饮料和一个遥控器。〕
5. `part2-4` Both of them are laughing, so they seem to be enjoying the film very much.  〔他们两个都在笑，所以他们似乎非常享受这部电影。〕
6. `part2-5` I think they chose a comedy because they both look really happy.  〔我觉得他们选了一部喜剧，因为他们俩看起来都很开心。〕
7. `part2-6` There are some cushions on the sofa, which make the room look warm and comfortable.  〔沙发上放着几个抱枕，让房间显得温馨舒适。〕

### pet-technology(手机与生活)— 9 句 / 128 词,新增 3 句

1. `part2-1` In the picture, there is a teenage girl sitting on a bench in a park.  〔照片里，有一个十几岁的女孩坐在公园的长椅上。〕
2. `part2-2` She is holding her smartphone and smiling at the screen.  〔她正拿着智能手机，对着屏幕微笑。〕
3. `part2-3` There are some trees and flowers around her, so the place looks pleasant and relaxing.  〔她周围有一些树和花，所以这个地方看起来很舒适、很放松。〕
4. ★ `part2-7` She is wearing a light blue jacket and has a school bag next to her on the bench.  〔她穿着浅蓝色外套，身旁的长椅上放着一个书包。〕
5. ★ `part2-8` There is a path in front of her, and a few people are cycling past.  〔她前面有一条小路，有几个人正骑车经过。〕
6. ★ `part2-9` It looks like a sunny day with just a few white clouds in the sky.  〔看起来是个晴天，天上只飘着几朵白云。〕
7. `part2-4` She may be messaging a friend because she is typing on her phone.  〔她可能在给朋友发消息，因为她正在手机上打字。〕
8. `part2-5` She seems to be enjoying the conversation because she has a big smile on her face.  〔她似乎聊得很开心，因为她脸上挂着大大的笑容。〕
9. `part2-6` Overall, she looks relaxed as she sits outside using her phone.  〔总的来说，她坐在户外用手机的样子很放松。〕

### pet-work(未来工作畅想)— 9 句 / 122 词,新增 3 句

1. `part2-1` In the picture, I can see a young woman working in a bright modern kitchen.  〔在照片里，我可以看到一个年轻女子在一个明亮的现代厨房里工作。〕
2. `part2-2` She is wearing a chef’s uniform and she’s decorating a cake on a table.  〔她穿着厨师制服，正在桌上装饰一个蛋糕。〕
3. `part2-3` There are some bowls, fresh fruit and a rolling pin near her.  〔她旁边有一些碗、新鲜水果和一根擀面杖。〕
4. `part2-4` She seems calm and focused because she is looking carefully at the cake.  〔她看起来很平静、很专注，因为她正认真地看着蛋糕。〕
5. ★ `part2-7` She is putting some strawberries on top of the white cake.  〔她正往白色蛋糕的顶上放草莓。〕
6. ★ `part2-8` She also has a tall white hat on, and her hair is tied up under it.  〔她还戴着一顶高高的白帽子，头发盘在帽子里。〕
7. ★ `part2-9` Behind her, there are some metal shelves with trays, and a big oven on the left.  〔她身后有几个放着托盘的金属架子，左边还有一个大烤箱。〕
8. `part2-5` She may be a pastry chef, and she seems pleased with the cake she is making.  〔她可能是位烘焙师，看起来对自己正在做的蛋糕很满意。〕
9. `part2-6` The kitchen around her looks tidy and well organised.  〔她周围的厨房看起来整洁而井井有条。〕

### pet-family(温馨一家人)— 9 句 / 124 词,新增 3 句

1. `part2-1` In the picture, I can see a family having a picnic in a park.  〔在这张照片里，我看到一家人在公园里野餐。〕
2. `part2-2` A mother and a father are sitting on a blanket, and they are smiling.  〔一位妈妈和一位爸爸正坐在毯子上，他们在微笑。〕
3. `part2-3` A young girl is running after a small dog, and she looks very excited.  〔一个小女孩在追一只小狗，她看上去非常兴奋。〕
4. `part2-4` The sun is shining, so it's probably a warm summer day.  〔阳光明媚，所以这很可能是一个温暖的夏日。〕
5. ★ `part2-7` There are some plates and cups on the red and white blanket.  〔红白相间的毯子上放着一些盘子和杯子。〕
6. ★ `part2-8` The girl is wearing a pink dress, and the dog is brown.  〔小女孩穿着粉色连衣裙，那只狗是棕色的。〕
7. ★ `part2-9` There are some big trees behind them, and I can see a lake in the distance.  〔他们身后有几棵大树，远处我能看到一个湖。〕
8. `part2-5` I think they are all feeling happy and relaxed because they are spending time together.  〔我想他们都很开心、放松，因为他们在一起享受时光。〕
9. `part2-6` Maybe they have brought some food with them, because there is a basket next to them.  〔也许他们带了一些食物，因为旁边有一个篮子。〕
