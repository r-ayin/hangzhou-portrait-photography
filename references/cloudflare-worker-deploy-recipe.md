# Cloudflare Worker 部署记录

> 用于山夏摄影问卷投递的 Worker 部署过程与教训。
> 部署时间：2026-06-13

## Worker 信息

- **名称**: `shanxia-questionnaire`
- **URL**: `https://shanxia-questionnaire.womenhaiyouxiwang.workers.dev`
- **环境变量** (配置在 wrangler.toml `[vars]` 中):
  - `DISCORD_WEBHOOK_URL` — Discord webhook
  - `AUTH_TOKEN` — Bearer token 鉴权

## 部署教训

### 1. REST API 部署不激活路由

直接调用 Cloudflare API PUT 上传 Worker 成功，但 workers.dev 路由**不会自动激活**，访问返回 404 + 报错 1042。

**解决**: 用 `npx wrangler deploy` — wrangler 会自动创建并激活路由和 triggers。

### 2. ES modules 的 env 参数

ES modules 中 bindings 通过 `env` 参数传入：

```javascript
// ✅ 正确
export default {
  async fetch(request, env, ctx) {
    const token = env.AUTH_TOKEN;
  }
};
```

```javascript
// ❌ 错误（这是 Service Worker 格式的写法）
const token = AUTH_TOKEN;  // ReferenceError
```

### 3. wrangler.toml 绑定格式

```toml
[vars]
VAR_NAME = "value"
```

`[vars]` 中的变量自动作为 `plain_text` 绑定。
敏感值用 `npx wrangler secret put <NAME>` 设置。

### 4. 测试顺序

1. 先部署最小 Worker（只返回 `{"ok":true}`）确认环境
2. 再部署完整 Worker + 业务逻辑
3. 最后配环境变量

### 5. API multipart 注意事项

```json
{"main_module": "worker.js", "workers_dev": true, "bindings": [
  {"name": "VAR", "type": "plain_text", "text": "value"}
]}
```

> 字段名是 `"text"` 非 `"value"`。即使 API 返回 200，仍需额外配置路由。

### 6. Python urllib → Cloudflare 1010 错误

**现象**: 用 Python `urllib.request` POST 到 Worker 返回 `HTTP 403` 或 `HTTP Error 403: Forbidden`，`error code: 1010`

**根因**: Cloudflare 检测到 Python `urllib` 默认的 User-Agent 并拦了它。`curl` 正常因为它的默认 UA 不被拦。

**解决**: 在 `urllib.request.Request` 的 headers 中加上自定义 `User-Agent`:

```python
req = urllib.request.Request(url, data=data, headers={
    "Content-Type": "application/json",
    "Authorization": f"Bearer {token}",
    "User-Agent": "ShanxiaBot/2.0",    # ← 必须加
}, method="POST")
```

**记入**: `submit-questionnaire.py` 和 `submit-questionnaire.sh`（Shell 内的 Python inline 代码）的两处 Worker 请求 + 一处 webhook 直连请求均已添加。不限于 Worker——任何走 Cloudflare 的端点都可能触发此问题。
