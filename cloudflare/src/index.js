const API_PREFIX = "/api/nexo";

function json(data, status = 200, extra = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...securityHeaders(),
      ...extra,
    },
  });
}

function securityHeaders() {
  return {
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "referrer-policy": "strict-origin-when-cross-origin",
  };
}

function corsHeaders(request, env) {
  const configured = String(env.CORS_ORIGINS || "*");
  const origin = request.headers.get("Origin") || "";
  const allow = configured === "*" || configured.split(",").map(x => x.trim()).includes(origin)
    ? (configured === "*" ? "*" : origin)
    : "null";
  return {
    "access-control-allow-origin": allow,
    "access-control-allow-headers": "authorization,content-type",
    "access-control-allow-methods": "GET,HEAD,POST,PUT,PATCH,DELETE,OPTIONS",
    "access-control-max-age": "86400",
    "vary": "Origin",
  };
}

function withCors(response, request, env) {
  const h = new Headers(response.headers);
  for (const [k, v] of Object.entries(corsHeaders(request, env))) h.set(k, v);
  for (const [k, v] of Object.entries(securityHeaders())) h.set(k, v);
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers: h });
}

function apiPath(url) {
  if (url.pathname === API_PREFIX) return "/";
  if (url.pathname.startsWith(API_PREFIX + "/")) return url.pathname.slice(API_PREFIX.length);
  return url.pathname;
}

async function proxyLegacy(request, env, path) {
  const origin = String(env.LEGACY_API_ORIGIN || "").replace(/\/$/, "");
  if (!origin) return json({ error: "LEGACY_API_ORIGIN_NOT_CONFIGURED" }, 503);

  const incoming = new URL(request.url);
  const target = new URL(origin + path + incoming.search);
  const headers = new Headers(request.headers);
  headers.delete("host");
  headers.delete("content-length");

  const proxied = new Request(target.toString(), {
    method: request.method,
    headers,
    body: ["GET", "HEAD"].includes(request.method) ? undefined : request.body,
    redirect: "manual",
  });

  try {
    return await fetch(proxied);
  } catch (error) {
    return json({ error: "LEGACY_ORIGIN_UNREACHABLE", message: String(error) }, 502);
  }
}

async function authorize(request, env) {
  const auth = request.headers.get("Authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!token || !env.JWT_SECRET) return null;
  return verifyJwt(token, env.JWT_SECRET);
}

function base64urlBytes(input) {
  const s = input.replace(/-/g, "+").replace(/_/g, "/");
  const padded = s + "=".repeat((4 - s.length % 4) % 4);
  const raw = atob(padded);
  return Uint8Array.from(raw, c => c.charCodeAt(0));
}

function base64urlJson(input) {
  return JSON.parse(new TextDecoder().decode(base64urlBytes(input)));
}

async function verifyJwt(token, secret) {
  try {
    const [a, b, sig] = token.split(".");
    if (!a || !b || !sig) return null;

    const payload = base64urlJson(b);
    if (payload.exp && Number(payload.exp) < Math.floor(Date.now() / 1000)) return null;

    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"],
    );
    const ok = await crypto.subtle.verify(
      "HMAC",
      key,
      base64urlBytes(sig),
      new TextEncoder().encode(a + "." + b),
    );
    return ok ? payload : null;
  } catch (_) {
    return null;
  }
}

async function handleRealtime(request, env) {
  if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
    return json({ error: "WEBSOCKET_REQUIRED" }, 426);
  }

  const user = await authorize(request, env);
  if (!user?.sub) return json({ error: "UNAUTHORIZED" }, 401);

  const url = new URL(request.url);
  const roomId = url.searchParams.get("roomId") || "lobby";
  const id = env.GAME_ROOMS.idFromName(String(roomId));
  const stub = env.GAME_ROOMS.get(id);
  return stub.fetch(new Request(url.toString(), request));
}

async function handleAssets(request, env, path) {
  if (!env.ASSETS || !path.startsWith("/assets/")) return null;

  const key = path.slice("/assets/".length);
  const object = await env.ASSETS.get(key);
  if (!object) return json({ error: "ASSET_NOT_FOUND" }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("cache-control", "public, max-age=31536000, immutable");
  return new Response(object.body, { headers });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }), request, env);
    }

    if (url.pathname === "/health" || url.pathname === API_PREFIX + "/health") {
      let db = "unbound";
      try {
        await env.DB.prepare("SELECT 1").first();
        db = "ok";
      } catch (_) {}

      return withCors(json({
        ok: true,
        service: "nexo-cloudflare",
        mode: "adapter",
        database: db,
        realtime: "durable-objects",
        assets: env.ASSETS ? "r2" : "unbound",
      }), request, env);
    }

    const path = apiPath(url);

    const assetResponse = await handleAssets(request, env, path);
    if (assetResponse) return withCors(assetResponse, request, env);

    if (path === "/ws" || path === "/realtime") {
      return withCors(await handleRealtime(request, env), request, env);
    }

    // Contract-preserving migration: the Flutter API paths remain unchanged.
    // Un-migrated endpoints go to the current Node/PostgreSQL backend.
    return withCors(await proxyLegacy(request, env, path), request, env);
  },
};

export class NexoGameRoom {
  constructor(state) {
    this.state = state;
    this.sockets = new Set();
  }

  async fetch(request) {
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return json({ error: "WEBSOCKET_REQUIRED" }, 426);
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    server.accept();

    const userId = new URL(request.url).searchParams.get("userId") || "anonymous";
    this.sockets.add(server);

    server.addEventListener("message", event => {
      let message;
      try { message = JSON.parse(String(event.data)); }
      catch (_) { return; }

      const envelope = JSON.stringify({
        ...message,
        roomUserId: userId,
        serverTime: new Date().toISOString(),
      });

      for (const socket of this.sockets) {
        try { socket.send(envelope); } catch (_) {}
      }
    });

    const cleanup = () => {
      this.sockets.delete(server);
      try { server.close(); } catch (_) {}
    };

    server.addEventListener("close", cleanup);
    server.addEventListener("error", cleanup);

    server.send(JSON.stringify({
      type: "realtime_ready",
      roomUserId: userId,
      serverTime: new Date().toISOString(),
    }));

    return new Response(null, { status: 101, webSocket: client });
  }
}
