# Speak SOE 生产硬化包

这是 `speak.yuanbanwa.top/api/soe` 的可部署替换版本。它保留现有业务协议：接收
`POST { refText, voiceData }`，把 16 kHz 单声道 PCM16 音频送到腾讯云 SOE
WebSocket，再返回标准化的句子、流利度、完整度、单词和音素评分。

本目录不是已部署状态。2026-07-11 的线上核查全程只读，没有修改、重启或部署
任何线上文件或进程，也没有读取 `.env` 的内容或密钥值。

## 线上只读基线

核查到的现状如下：

- `/www/wwwroot/speak-soe/server.js`、`nginx.location.conf`、`package.json` 均为
  `root:root 0644`。
- `.env` 为 `root:root 0644`。
- PM2 中 `speak-soe` 由 root 运行，实际命令为
  `node /www/wwwroot/speak-soe/server.js`，仅监听 `127.0.0.1:4006`。
- 线上运行时为 Node `18.19.1`、nginx `1.28.1`、`ws 8.11.0`；项目没有
  `package-lock.json`，`package.json` 也没有声明 `ws` 依赖。
- nginx 当前允许 12 MB 请求体、30 秒上游等待，没有 `limit_req` 或
  `limit_conn`。
- 应用当前没有用户鉴权、用户/IP 配额或并发闸门，GET 还会公开密钥是否存在、
  引擎和评分系数等运行信息。

## 这版增加了什么

| 边界 | 实现 |
| --- | --- |
| 请求鉴权 | HMAC-SHA256 短时签名，绑定用户、时间戳、nonce、方法、路径和原始请求体；默认 60 秒有效并防重放 |
| IP + 用户限流 | nginx IP 令牌桶；应用层再按真实 IP 和已签名用户分别限流 |
| 并发控制 | 默认全局 4、单 IP 2、单用户 1；超限立即返回 429，不排无界队列 |
| 请求体 | nginx 约 1.4 MB，Node 精确 1,400,000 字节；慢上传 10 秒超时 |
| 输入校验 | 限制参考文本字符/字节数；严格校验 base64；PCM16 必须偶数字节且默认 0.1–30 秒 |
| CORS | 精确 origin 白名单，不反射任意 `Origin`，预检只开放必要方法和签名头 |
| 上游 | WebSocket 握手、总耗时、响应体积均有限制；签名 URL 默认只存活 60 秒 |
| 信息暴露 | 健康检查只返回服务名与版本；生产默认不回传腾讯原始结果；错误不回显内部异常 |
| 日志 | 不记录参考文本、音频、签名或原始用户/IP，只记录 HMAC 截断标识和请求 ID |
| 运行权限 | 部署流程使用独立 `speak-soe` 系统用户；`.env` 必须为 `0600` |

默认值都在 [`.env.example`](./.env.example) 中，可以按真实流量调整。nginx 和应用层
限制应保持相互匹配。

## 重要：静态网页不能持有签名密钥

不要把 `SOE_SIGNING_SECRET` 放进 `index.html`、任何前端 JavaScript、localStorage、
构建变量或 App 包。那会让“鉴权”退化为公开口令。

上线本硬化服务前，必须先具备可信身份来源。当前 Speak 页面使用的本地演示登录
不能提供这个边界。推荐两种接法：

1. 浏览器携带真实会话访问业务后端；后端从已验证会话派生稳定、匿名的 `userId`，
   使用本目录的 `signature.cjs` 签名后代转 SOE 请求。
2. 后端签发一次性请求头给浏览器。后端必须验证真实会话、从会话派生 `userId`，
   且签名必须绑定浏览器即将发送的**完全相同的请求体字节**。返回短时签名头是
   可以的，返回共享密钥不可以。

如果真实认证/签名网关尚未完成，**不要部署这一版到 4006**；否则当前未签名的
页面请求会正确地变成 401。

### 签名格式

规范串用换行连接：

```text
soe-v1
<unix timestamp seconds>
<16-64 char nonce>
<server-derived user id>
POST
/api/soe
<sha256 of exact HTTP body bytes in lowercase hex>
```

然后计算：

```text
X-SOE-Signature: v1=<HMAC-SHA256(signing secret, canonical string) in hex>
```

另需发送 `X-SOE-User`、`X-SOE-Timestamp`、`X-SOE-Nonce` 和
`Content-Type: application/json`。可直接在可信 Node 后端复用：

```js
const { createSignedHeaders } = require('./signature.cjs');

const body = JSON.stringify({ refText, voiceData });
const headers = createSignedHeaders({
  body,
  userId: authenticatedUser.soeOpaqueId,
  secret: process.env.SOE_SIGNING_SECRET,
});

const response = await fetch('https://speak.yuanbanwa.top/api/soe', {
  method: 'POST',
  headers,
  body, // 必须发送上面参与签名的同一个字符串，不能重新 JSON.stringify
});
```

`userId` 不应使用手机号、姓名等直接身份信息；建议由后端保存独立的稳定随机 ID。

## 文件说明

- `server.js`：完整硬化代理，保留原腾讯 SOE 业务链路。
- `signature.cjs`：服务端校验与可信后端签名共用实现。
- `nginx.http-limits.conf`：必须包含在 nginx 的 `http {}` 中，只定义 zone。
- `nginx.location.conf`：替换现有站点内的 SOE location。
- `ecosystem.config.cjs`：由独立系统用户启动的 PM2 配置。
- `.env.example`：无密钥的配置模板。
- `package.json` / `package-lock.json`：锁定 `ws 8.21.0`。
- `test/`：签名、篡改、过期、健康检查、CORS 和未签名拒绝测试。

## 本地验证

```bash
cd ops/speak-soe
npm ci --ignore-scripts
npm run check
npm test
```

测试不会连接腾讯云，也不会产生 SOE 费用。若要本地启动，复制 `.env.example` 为
`.env` 并填入测试环境凭据；不要把真实 `.env` 提交到仓库。

## 生产部署步骤

以下流程假设已完成真实认证/签名接入，并使用 ECS root shell 执行系统配置。
命令中的时间戳变量应在同一个 shell 会话中保留。先安排短维护窗口。

### 1. 打包和上传到暂存目录

在本地仓库执行：

```bash
tar --exclude='./node_modules' -C ops/speak-soe -czf /tmp/speak-soe-v3.tar.gz .
scp /tmp/speak-soe-v3.tar.gz yuanbanwa-server:/tmp/
```

在服务器执行：

```bash
set -eu
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE="/www/wwwroot/speak-soe.next.${STAMP}"
ROLLBACK="/www/wwwroot/speak-soe.rollback.${STAMP}"
VHOST="/www/server/panel/vhost/nginx/speak.yuanbanwa.top.conf"
LIMITS="/www/server/panel/vhost/nginx/speak-soe-limits.conf"

getent group speak-soe >/dev/null 2>&1 || groupadd --system speak-soe
id speak-soe >/dev/null 2>&1 || useradd --system --gid speak-soe --home-dir /var/lib/speak-soe --create-home --shell /usr/sbin/nologin speak-soe
install -d -o speak-soe -g speak-soe -m 0750 /var/lib/speak-soe
install -d -o root -g speak-soe -m 0750 "$STAGE"
tar -xzf /tmp/speak-soe-v3.tar.gz -C "$STAGE"

install -o speak-soe -g speak-soe -m 0600 /www/wwwroot/speak-soe/.env "$STAGE/.env"
cd "$STAGE"
npm ci --omit=dev --ignore-scripts
npm run check
npm test
```

在 `"$STAGE/.env"` 中新增独立的 `SOE_SIGNING_SECRET`，至少 32 字节；建议使用
`openssl rand -hex 32` 生成。确认 `ALLOW_ORIGINS=https://speak.yuanbanwa.top`。
不要复用腾讯的 SecretKey，也不要在终端日志或工单中粘贴任何密钥。
配置完成后执行只输出成功/失败、不输出配置值的检查：

```bash
cd "$STAGE"
npm run config-check
```

设置最终权限：

```bash
chown -R root:speak-soe "$STAGE"
find "$STAGE" -type d -exec chmod 0750 {} +
find "$STAGE" -type f -exec chmod 0640 {} +
chown speak-soe:speak-soe "$STAGE/.env"
chmod 0600 "$STAGE/.env"
```

### 2. 安装 nginx 全局限流 zone

线上 `nginx.conf` 已在 `http {}` 中包含
`/www/server/panel/vhost/nginx/*.conf`。因此把 zone 文件安装到该目录即可，**不要**
再向 `nginx.conf` 添加第二条显式 include。先备份站点配置并安装 zone：

```bash
cp -a "$VHOST" "${VHOST}.soe.${STAMP}"
if [ -e "$LIMITS" ]; then cp -a "$LIMITS" "${LIMITS}.soe.${STAMP}"; fi
install -o root -g root -m 0644 "$STAGE/nginx.http-limits.conf" "$LIMITS"
```

该 wildcard 位于 `http {}`，而 `speak-soe-limits.conf` 的文件名排序在
`speak.yuanbanwa.top.conf` 前面。不要把 `limit_req_zone` 放入站点的
`server {}`。完成后先检查当前配置：

```bash
/www/server/nginx/sbin/nginx -t
```

### 3. 切换服务并迁移到非 root PM2

只有这一步开始会产生几秒钟中断。删除 root PM2 中的单个 `speak-soe` 进程不会
影响同一 PM2 下的其他产品：

```bash
/usr/local/bin/pm2 delete speak-soe
/usr/local/bin/pm2 save --force
mv /www/wwwroot/speak-soe "$ROLLBACK"
mv "$STAGE" /www/wwwroot/speak-soe

/www/server/nginx/sbin/nginx -t

runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 start /www/wwwroot/speak-soe/ecosystem.config.cjs --update-env
runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 save

curl --fail --silent --show-error http://127.0.0.1:4006/api/soe/healthz
/www/server/nginx/sbin/nginx -s reload
```

为独立 PM2 用户安装开机启动；执行命令后检查它生成的 systemd unit，再保存一次：

```bash
/usr/local/bin/pm2 startup systemd -u speak-soe --hp /var/lib/speak-soe
runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 save
```

不要删除或停用 root 的 PM2 systemd 服务；其他产品仍由它管理。
上面的 root `pm2 save --force` 必须紧跟在删除后执行，确保 root 的 dump 不会在重启时
复活旧 `speak-soe`；新服务则只写入 `speak-soe` 用户自己的 PM2 dump。

### 4. 上线验收

```bash
curl --fail --silent --show-error https://speak.yuanbanwa.top/api/soe/healthz

curl -i -X OPTIONS https://speak.yuanbanwa.top/api/soe \
  -H 'Origin: https://speak.yuanbanwa.top' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,x-soe-user,x-soe-timestamp,x-soe-nonce,x-soe-signature'

curl -i -X POST https://speak.yuanbanwa.top/api/soe \
  -H 'Content-Type: application/json' \
  --data '{"refText":"Hello","voiceData":"AAAA"}'

stat -c '%a %U:%G %n' /www/wwwroot/speak-soe/.env
SOE_PID="$(runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 /usr/local/bin/pm2 pid speak-soe)"
ps -o pid=,user=,group=,args= -p "$SOE_PID"
```

预期结果：健康检查 200；预检 204 且只回显生产 origin；未签名 POST 401；
`.env` 为 `600 speak-soe:speak-soe`；Node 进程用户和组均为 `speak-soe`。
最后用已接入的真实签名链路做一次短录音评测，确认评分字段兼容前端。

部署后重点观察结构化日志中的 `invalid_signature`、`ip_rate_limited`、
`user_rate_limited`、`concurrency_limited`、`upstream_timeout` 和 502 比例。不要为
消除 429 而直接取消限制，应先依据真实峰值逐步调参。

## 回滚步骤

若健康检查、签名链路或真实评测失败，立即回滚。下例继续使用部署时的 `STAMP`；
不要删除失败版本，保留用于离线诊断。

```bash
set -eu
: "${STAMP:?请设置为部署时的时间戳}"
ROLLBACK="/www/wwwroot/speak-soe.rollback.${STAMP}"
VHOST="/www/server/panel/vhost/nginx/speak.yuanbanwa.top.conf"
LIMITS="/www/server/panel/vhost/nginx/speak-soe-limits.conf"
FAILED="/www/wwwroot/speak-soe.failed.${STAMP}"

runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 delete speak-soe || true
runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 save --force

# root 与 speak-soe 用户各有独立 dump；继续确保 root dump 中没有旧进程。
/usr/local/bin/pm2 delete speak-soe || true
/usr/local/bin/pm2 save --force

mv /www/wwwroot/speak-soe "$FAILED"
mv "$ROLLBACK" /www/wwwroot/speak-soe
cp -a "${VHOST}.soe.${STAMP}" "$VHOST"
if [ -e "${LIMITS}.soe.${STAMP}" ]; then
  cp -a "${LIMITS}.soe.${STAMP}" "$LIMITS"
else
  rm -f "$LIMITS"
fi

chown -R root:speak-soe /www/wwwroot/speak-soe
find /www/wwwroot/speak-soe -type d -exec chmod 0750 {} +
find /www/wwwroot/speak-soe -type f -exec chmod 0640 {} +
chown speak-soe:speak-soe /www/wwwroot/speak-soe/.env
chmod 0600 /www/wwwroot/speak-soe/.env

/www/server/nginx/sbin/nginx -t
runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 start /www/wwwroot/speak-soe/server.js --name speak-soe --cwd /www/wwwroot/speak-soe
runuser -u speak-soe -- env HOME=/var/lib/speak-soe PM2_HOME=/var/lib/speak-soe/.pm2 \
  /usr/local/bin/pm2 save
/www/server/nginx/sbin/nginx -s reload

curl --fail --silent --show-error http://127.0.0.1:4006/
```

回滚会先分别持久化“不含 `speak-soe`”的用户与 root dump，再只把旧版本写回
`speak-soe` 用户的 dump；root dump 始终保留其他产品，但不再包含该进程。

这会恢复旧业务行为，但也会恢复“公开未鉴权 SOE”风险；它只适合作为短时应急回退。
服务仍保持非 root 与 `.env 0600`，随后应离线修好新签名链路并重新上线。

## 后续交接清单

交给下一位 Coding Agent 时，请按此顺序继续：

1. 先检查真实认证后端，决定“后端代转”还是“一次性签名头”方案。
2. 从已验证会话派生匿名稳定 `userId`，并对签名签发本身做用户配额。
3. 确保参与签名和实际发送的是同一个 body 字符串；不要二次序列化。
4. 补一条端到端测试：未登录 401、篡改 body 401、重放 401、超限 429、真实短音频 200。
5. 先上线签名调用方，再按本 README 切 SOE 服务；不要反过来。
6. 上线后验证 PM2 用户、`.env` 权限、nginx zone、CORS、请求体上限和日志告警。
