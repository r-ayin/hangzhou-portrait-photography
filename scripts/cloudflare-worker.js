/**
 * 山夏摄影 — 问卷投递代理 Worker
 */
export default {
  async fetch(request, env, ctx) {
    const webhookUrl = env.DISCORD_WEBHOOK_URL || '';
    const expectedToken = env.AUTH_TOKEN || '';

    // === 1. 限速检查 ===
    const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
    if (isRateLimited(clientIP)) {
      return new Response(
        JSON.stringify({ ok: false, error: '请求过于频繁' }),
        { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': '60' } }
      );
    }

    // === 2. CORS 预检 ===
    if (request.method === 'OPTIONS') {
      return handleCORS();
    }

    // === 3. 只接受 POST ===
    if (request.method !== 'POST') {
      return jsonResponse({ ok: false, error: '仅接受 POST' }, 405);
    }

    // === 4. 验证 Token ===
    const authHeader = request.headers.get('Authorization') || '';
    if (!authHeader.startsWith('Bearer ') || authHeader.slice(7) !== expectedToken) {
      return jsonResponse({ ok: false, error: 'Token 无效' }, 401);
    }

    // === 5. 验证 Content-Type ===
    const contentType = request.headers.get('Content-Type') || '';
    if (!contentType.includes('application/json')) {
      return jsonResponse({ ok: false, error: '需要 JSON' }, 400);
    }

    // === 6. 读取并验证 payload ===
    let payload;
    try {
      payload = await request.json();
    } catch {
      return jsonResponse({ ok: false, error: 'JSON 解析失败' }, 400);
    }

    if (!payload || !payload.embeds || !Array.isArray(payload.embeds)) {
      return jsonResponse({ ok: false, error: '缺少 embeds 字段' }, 400);
    }

    // === 7. 检查 webhook URL ===
    if (!webhookUrl) {
      return jsonResponse({ ok: false, error: '服务端未配置 webhook' }, 500);
    }

    // === 8. 转发到 Discord ===
    try {
      const discordResponse = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (discordResponse.status === 204 || discordResponse.status === 200) {
        return jsonResponse({ ok: true, message: '已投递到山夏 Discord' }, 200);
      } else {
        const errorText = await discordResponse.text();
        console.error(`Discord ${discordResponse.status}: ${errorText.slice(0, 200)}`);
        return jsonResponse({ ok: false, error: `Discord 返回 ${discordResponse.status}` }, 502);
      }
    } catch (err) {
      console.error(`Forward failed: ${err.message}`);
      return jsonResponse({ ok: false, error: `转发失败: ${err.message}` }, 502);
    }
  },
};

const requestLog = new Map(); // IP → timestamp[]

function isRateLimited(ip) {
  const now = Date.now();
  const timestamps = requestLog.get(ip) || [];
  const recent = timestamps.filter(t => now - t < 60000);
  requestLog.set(ip, recent);
  if (recent.length >= 10) return true;
  recent.push(now);
  requestLog.set(ip, recent);
  return false;
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
    },
  });
}
