
const CORE_PATHS = new Set([
  "/auth/guest", "/auth/register", "/auth/login", "/me", "/wallet",
  "/inventory", "/catalog", "/gifts", "/profile/equipped",
]);

function json(data, status = 200, extra = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...extra,
    },
  });
}

function randomId() { return crypto.randomUUID(); }
function nowIso() { return new Date().toISOString(); }

function base64url(value) {
  const bytes = new TextEncoder().encode(value);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64urlBytes(input) {
  const padded = input.replace(/-/g, "+").replace(/_/g, "/") +
    "=".repeat((4 - input.length % 4) % 4);
  const raw = atob(padded);
  return Uint8Array.from(raw, c => c.charCodeAt(0));
}

function base64urlJson(input) {
  return JSON.parse(new TextDecoder().decode(base64urlBytes(input)));
}

async function signJwt(payload, secret) {
  const header = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = base64url(JSON.stringify(payload));
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "HMAC", key, new TextEncoder().encode(header + "." + body)
  );
  let binary = "";
  for (const b of new Uint8Array(signature)) binary += String.fromCharCode(b);
  const sig = btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  return header + "." + body + "." + sig;
}

async function verifyJwt(token, secret) {
  try {
    const [a, b, sig] = token.split(".");
    if (!a || !b || !sig) return null;
    const payload = base64urlJson(b);
    if (payload.exp && Number(payload.exp) < Math.floor(Date.now() / 1000)) return null;
    const key = await crypto.subtle.importKey(
      "raw", new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" }, false, ["verify"]
    );
    const ok = await crypto.subtle.verify(
      "HMAC", key, base64urlBytes(sig), new TextEncoder().encode(a + "." + b)
    );
    return ok ? payload : null;
  } catch (_) {
    return null;
  }
}

function hexBytes(hex) {
  const clean = String(hex || "").replace(/^0x/, "");
  if (!clean || clean.length % 2) return new Uint8Array();
  const out = new Uint8Array(clean.length / 2);
  for (let i = 0; i < out.length; i++) out[i] = Number.parseInt(clean.slice(i * 2, i * 2 + 2), 16);
  return out;
}

function constantTimeEqual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

async function verifyLegacyPbkdf2(password, encoded) {
  try {
    const parts = String(encoded).split("$");
    if (parts.length !== 4 || parts[0] !== "pbkdf2sha256") return false;
    const iterations = Number(parts[1]);
    const salt = hexBytes(parts[2]);
    const expected = hexBytes(parts[3]);
    if (!Number.isInteger(iterations) || iterations < 10000 || !salt.length || expected.length !== 32) return false;

    const key = await crypto.subtle.importKey(
      "raw", new TextEncoder().encode(password), "PBKDF2", false, ["deriveBits"]
    );
    const bits = await crypto.subtle.deriveBits(
      { name: "PBKDF2", hash: "SHA-256", salt, iterations }, key, 256
    );
    return constantTimeEqual(new Uint8Array(bits), expected);
  } catch (_) {
    return false;
  }
}

async function hashPassword(password, env) {
  const configured = Number.parseInt(String(env.PBKDF2_ITERATIONS || "60000"), 10);
  const iterations = Number.isInteger(configured) && configured >= 30000 ? Math.min(configured, 250000) : 60000;
  const salt = new Uint8Array(16);
  crypto.getRandomValues(salt);
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(password), "PBKDF2", false, ["deriveBits"]
  );
  const bits = await crypto.subtle.deriveBits(
    { name: "PBKDF2", hash: "SHA-256", salt, iterations }, key, 256
  );
  const toHex = bytes => Array.from(bytes, b => b.toString(16).padStart(2, "0")).join("");
  return "pbkdf2sha256$" + iterations + "$" + toHex(salt) + "$" + toHex(new Uint8Array(bits));
}

async function verifyPassword(password, encoded) {
  return verifyLegacyPbkdf2(password, encoded);
}

function publicUser(u) {
  if (!u) return null;
  return {
    id: u.id,
    username: u.username,
    displayName: u.display_name,
    avatar: u.avatar,
    gems: Number(u.gems),
    energy: Number(u.energy),
    level: Number(u.level),
    experience: Number(u.experience),
    reputation: Number(u.reputation),
    vipLevel: u.vip_level,
    nameColor: u.name_color,
    glow: Boolean(Number(u.glow)),
    createdAt: u.created_at,
    lastActive: u.last_active,
    role: u.role,
    banned: Boolean(Number(u.banned)),
  };
}

async function first(env, sql, ...params) {
  return env.DB.prepare(sql).bind(...params).first();
}

async function all(env, sql, ...params) {
  return env.DB.prepare(sql).bind(...params).all();
}

async function run(env, sql, ...params) {
  return env.DB.prepare(sql).bind(...params).run();
}

function legacyOrigin(env) {
  return String(env.LEGACY_API_ORIGIN || "").replace(/\/$/, "");
}

async function legacyJson(env, path, { method = "GET", token = "", body } = {}) {
  const origin = legacyOrigin(env);
  if (!origin) return { response: null, data: null };
  const headers = new Headers({ accept: "application/json" });
  if (token) headers.set("authorization", "Bearer " + token);
  if (body !== undefined) headers.set("content-type", "application/json");

  const response = await fetch(origin + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
    redirect: "manual",
  });

  const raw = await response.text();
  let data = null;
  try { data = raw ? JSON.parse(raw) : null; } catch (_) {}
  return { response, data };
}

async function ensureCatalog(env) {
  const countRow = await first(env, "SELECT COUNT(*) AS count FROM catalog_items");
  if (Number(countRow?.count || 0) > 0) return;

  const legacy = await legacyJson(env, "/catalog");
  if (!legacy.response?.ok || !Array.isArray(legacy.data)) return;

  const statements = legacy.data.slice(0, 2000).map(item => env.DB.prepare(
    "INSERT INTO catalog_items " +
    "(id,name,rarity,gems,tradeable,image,tagline,active,item_type,category,description,animation," +
    "market_visible,sort_order,featured,limited,tags_json,metadata_json) " +
    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) " +
    "ON CONFLICT(id) DO UPDATE SET name=excluded.name,rarity=excluded.rarity,gems=excluded.gems," +
    "tradeable=excluded.tradeable,image=excluded.image,tagline=excluded.tagline,active=excluded.active," +
    "item_type=excluded.item_type,category=excluded.category,description=excluded.description," +
    "animation=excluded.animation,market_visible=excluded.market_visible,sort_order=excluded.sort_order," +
    "featured=excluded.featured,limited=excluded.limited,tags_json=excluded.tags_json," +
    "metadata_json=excluded.metadata_json"
  ).bind(
    String(item.id || ""),
    String(item.name || item.id || ""),
    String(item.rarity || "Common"),
    Number(item.gems || 0),
    item.tradeable ? 1 : 0,
    String(item.image || ""),
    String(item.tagline || ""),
    item.active === false ? 0 : 1,
    String(item.itemType || item.item_type || "gift"),
    String(item.category || "gifts"),
    String(item.description || ""),
    String(item.animation || "pulse"),
    item.marketVisible === false ? 0 : 1,
    Number(item.sortOrder || 0),
    item.featured ? 1 : 0,
    item.limited ? 1 : 0,
    JSON.stringify(item.tags ?? []),
    JSON.stringify(item.metadata ?? {}),
  ));

  if (statements.length) await env.DB.batch(statements);
}

async function upsertUser(env, user, passwordHash = null) {
  const id = String(user.id || randomId());
  const username = String(user.username || "").toLowerCase();
  const email = user.email ? String(user.email).toLowerCase() : null;
  const displayName = String(user.displayName || user.display_name || username);

  await run(env,
    "INSERT INTO users " +
    "(id,username,email,password_hash,display_name,avatar,gems,energy,level,experience,reputation," +
    "vip_level,name_color,glow,role,banned,created_at,last_active,svip_active,svip_expires_at,aristocracy_level) " +
    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) " +
    "ON CONFLICT(id) DO UPDATE SET username=excluded.username,email=COALESCE(excluded.email,users.email)," +
    "password_hash=COALESCE(excluded.password_hash,users.password_hash),display_name=excluded.display_name," +
    "avatar=excluded.avatar,gems=excluded.gems,energy=excluded.energy,level=excluded.level," +
    "experience=excluded.experience,reputation=excluded.reputation,vip_level=excluded.vip_level," +
    "name_color=excluded.name_color,glow=excluded.glow,role=excluded.role,banned=excluded.banned," +
    "last_active=excluded.last_active,svip_active=excluded.svip_active," +
    "svip_expires_at=excluded.svip_expires_at,aristocracy_level=excluded.aristocracy_level",
    id, username, email, passwordHash, displayName, String(user.avatar || "001.jpg"),
    Number(user.gems ?? 1000), Number(user.energy ?? 50), Number(user.level ?? 1),
    Number(user.experience ?? 0), Number(user.reputation ?? 0),
    String(user.vipLevel ?? user.vip_level ?? "Base"),
    String(user.nameColor ?? user.name_color ?? "#54d6ff"),
    user.glow === false ? 0 : 1, String(user.role || "user"), user.banned ? 1 : 0,
    String(user.createdAt || user.created_at || nowIso()),
    String(user.lastActive || user.last_active || nowIso()),
    user.svipActive ? 1 : 0, user.svipExpiresAt || null, Number(user.aristocracyLevel || 0)
  );
  return id;
}

async function syncLegacyUserState(env, legacyToken, legacyUser, password = "") {
  let wallet = null;
  let inventory = [];
  let equipped = [];

  const [walletRes, inventoryRes, equippedRes] = await Promise.all([
    legacyJson(env, "/wallet", { token: legacyToken }),
    legacyJson(env, "/inventory", { token: legacyToken }),
    legacyJson(env, "/profile/equipped", { token: legacyToken }),
  ]);

  wallet = walletRes.data || null;
  inventory = Array.isArray(inventoryRes.data) ? inventoryRes.data : [];
  equipped = Array.isArray(equippedRes.data) ? equippedRes.data : [];

  const merged = {
    ...legacyUser,
    gems: wallet?.gems ?? legacyUser?.gems,
    energy: wallet?.energy ?? legacyUser?.energy,
    level: wallet?.level ?? legacyUser?.level,
    experience: wallet?.experience ?? legacyUser?.experience,
    reputation: wallet?.reputation ?? legacyUser?.reputation,
    vipLevel: wallet?.vip_level ?? wallet?.vipLevel ?? legacyUser?.vipLevel,
    nameColor: wallet?.name_color ?? wallet?.nameColor ?? legacyUser?.nameColor,
    glow: wallet?.glow ?? legacyUser?.glow,
    svipActive: wallet?.svip_active ?? false,
    svipExpiresAt: wallet?.svip_expires_at ?? null,
    aristocracyLevel: wallet?.aristocracy_level ?? 0,
    lastActive: nowIso(),
  };

  const passwordHash = password ? await hashPassword(password, env) : null;
  const userId = await upsertUser(env, merged, passwordHash);

  if (inventory.length) {
    const statements = inventory.map(item => env.DB.prepare(
      "INSERT INTO inventory(user_id,item_id,quantity) " +
      "SELECT ?,id,? FROM catalog_items WHERE id=? " +
      "ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=excluded.quantity"
    ).bind(userId, Number(item.quantity || 0), String(item.id || "")));
    await env.DB.batch(statements);
  }

  if (equipped.length) {
    const statements = equipped.filter(item => item.slot && item.id).map(item => env.DB.prepare(
      "INSERT INTO user_equipped(user_id,slot,item_id,updated_at) VALUES (?,?,?,?) " +
      "ON CONFLICT(user_id,slot) DO UPDATE SET item_id=excluded.item_id,updated_at=excluded.updated_at"
    ).bind(userId, String(item.slot), String(item.id), nowIso()));
    if (statements.length) await env.DB.batch(statements);
  }

  return first(env, "SELECT * FROM users WHERE id=?", userId);
}

function bearerToken(request) {
  const raw = request.headers.get("Authorization") || "";
  return raw.startsWith("Bearer ") ? raw.slice(7).trim() : "";
}

async function requireUser(request, env) {
  const secret = String(env.JWT_SECRET || "");
  if (secret.length < 32) return { error: json({ error: "JWT_SECRET_NOT_CONFIGURED" }, 503) };

  const token = bearerToken(request);
  const claims = token ? await verifyJwt(token, secret) : null;
  if (!claims?.sub) return { error: json({ error: "UNAUTHORIZED" }, 401) };

  let user = await first(env, "SELECT * FROM users WHERE id=?", String(claims.sub));
  if (!user) {
    const legacy = await legacyJson(env, "/me", { token });
    if (legacy.response?.ok && legacy.data?.user) {
      await syncLegacyUserState(env, token, legacy.data.user);
      user = await first(env, "SELECT * FROM users WHERE id=?", String(claims.sub));
    }
  }

  if (!user) return { error: json({ error: "USER_NOT_FOUND" }, 404) };
  if (Number(user.banned)) return { error: json({ error: "ACCOUNT_BANNED" }, 403) };
  return { claims, user, token };
}

async function issueToken(env, user) {
  const secret = String(env.JWT_SECRET || "");
  if (secret.length < 32) throw new Error("JWT_SECRET_NOT_CONFIGURED");
  const now = Math.floor(Date.now() / 1000);
  return signJwt({
    sub: user.id,
    username: user.username,
    iat: now,
    exp: now + (60 * 60 * 24 * 30),
  }, secret);
}

async function nativeGuest(request, env) {
  const body = await request.json().catch(() => ({}));
  const deviceId = String(body?.deviceId || "").trim().slice(0, 60);
  const username = ("guest_" + (deviceId || randomId().slice(0, 12))).toLowerCase();

  await ensureCatalog(env);
  let user = await first(env, "SELECT * FROM users WHERE username=?", username);

  if (!user) {
    const id = randomId();
    await upsertUser(env, {
      id, username, displayName: "NEXO Guest", avatar: "001.jpg",
      gems: 1000, energy: 50, level: 1, experience: 0, reputation: 0,
      vipLevel: "Base", nameColor: "#54d6ff", glow: true,
      role: "user", banned: false, createdAt: nowIso(), lastActive: nowIso(),
    });

    const starter = [
      ["neon-heart", 2], ["shadow-flame", 1], ["galaxy-aura", 1], ["crown-shine", 1],
      ["frame-cyan", 1], ["asset-cosmic", 1], ["emoji-heart", 2], ["crafted-shadow-mask", 1],
      ["power_chat_spark", 1], ["power_glow_frame", 1],
    ];
    await env.DB.batch(starter.map(([itemId, qty]) => env.DB.prepare(
      "INSERT INTO inventory(user_id,item_id,quantity) SELECT ?,id,? FROM catalog_items WHERE id=? " +
      "ON CONFLICT(user_id,item_id) DO NOTHING"
    ).bind(id, qty, itemId)));

    user = await first(env, "SELECT * FROM users WHERE id=?", id);
  }

  return { token: await issueToken(env, user), user: publicUser(user) };
}

async function nativeRegister(request, env) {
  const body = await request.json().catch(() => ({}));
  const email = String(body?.email || "").trim().toLowerCase();
  const username = String(body?.username || "").trim().toLowerCase();
  const password = String(body?.password || "");
  if (!email || !username || password.length < 8) return json({ error: "INVALID_INPUT" }, 400);

  await ensureCatalog(env);
  const exists = await first(env,
    "SELECT id FROM users WHERE lower(username)=lower(?) OR lower(email)=lower(?) LIMIT 1",
    username, email
  );
  if (exists) return json({ error: "ACCOUNT_EXISTS" }, 409);

  const id = randomId();
  const hash = await hashPassword(password, env);
  await run(env,
    "INSERT INTO users(id,username,email,password_hash,display_name,avatar,gems,energy,last_active) " +
    "VALUES (?,?,?,?,?,?,?,?,?)",
    id, username, email, hash, username, "001.jpg", 1000, 50, nowIso()
  );

  const user = await first(env, "SELECT * FROM users WHERE id=?", id);
  return { token: await issueToken(env, user), user: publicUser(user) };
}

async function nativeLogin(request, env) {
  const body = await request.json().catch(() => ({}));
  const identity = String(
    body?.identity || body?.identifier || body?.email || body?.username || ""
  ).trim().toLowerCase();
  const password = String(body?.password || "");
  if (!identity || !password) return json({ error: "LOGIN_REQUIRED" }, 400);

  let user = await first(env,
    "SELECT * FROM users WHERE lower(username)=lower(?) OR lower(email)=lower(?) LIMIT 1",
    identity, identity
  );

  if (user?.password_hash) {
    if (Number(user.banned)) return json({ error: "ACCOUNT_BANNED" }, 403);
    const valid = await verifyPassword(password, user.password_hash);
    if (!valid) return json({ error: "INVALID_CREDENTIALS" }, 401);
    await run(env, "UPDATE users SET last_active=? WHERE id=?", nowIso(), user.id);
    user = await first(env, "SELECT * FROM users WHERE id=?", user.id);
    return { token: await issueToken(env, user), user: publicUser(user) };
  }

  // Gradual migration of an existing account:
  // legacy authenticates the credentials once; the password is immediately converted
  // to a Worker-side PBKDF2 hash and future logins are D1-native.
  const legacy = await legacyJson(env, "/auth/login", { method: "POST", body });
  if (!legacy.response?.ok || !legacy.data?.user || !legacy.data?.token) {
    return json(
      legacy.data || { error: legacy.response?.status === 403 ? "ACCOUNT_BANNED" : "INVALID_CREDENTIALS" },
      legacy.response?.status || 401
    );
  }

  await ensureCatalog(env);
  user = await syncLegacyUserState(env, legacy.data.token, legacy.data.user, password);
  return { token: await issueToken(env, user), user: publicUser(user) };
}

async function nativeMe(request, env) {
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;
  const user = await first(env, "SELECT * FROM users WHERE id=?", auth.user.id);
  return { user: publicUser(user) };
}

async function nativeWallet(request, env) {
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;
  return await first(env,
    "SELECT gems,energy,level,experience,reputation,vip_level,name_color,glow," +
    "svip_active,svip_expires_at,aristocracy_level FROM users WHERE id=?",
    auth.user.id
  );
}

async function nativeInventory(request, env) {
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;

  const r = await all(env,
    "SELECT i.item_id AS id,c.name,c.rarity,c.gems,c.tradeable,c.image,c.tagline,c.description," +
    "c.item_type AS itemType,c.category,c.animation,c.market_visible AS marketVisible,i.quantity " +
    "FROM inventory i JOIN catalog_items c ON c.id=i.item_id " +
    "WHERE i.user_id=? AND i.quantity>0 ORDER BY c.item_type,c.sort_order,c.gems",
    auth.user.id
  );
  return r.results || [];
}

function catalogRow(row) {
  let tags = [], metadata = {};
  try { tags = JSON.parse(row.tags_json || "[]"); } catch (_) {}
  try { metadata = JSON.parse(row.metadata_json || "{}"); } catch (_) {}

  return {
    id: row.id,
    name: row.name,
    rarity: row.rarity,
    gems: Number(row.gems),
    tradeable: Boolean(Number(row.tradeable)),
    image: row.image,
    tagline: row.tagline,
    description: row.description,
    itemType: row.item_type,
    category: row.category,
    animation: row.animation,
    marketVisible: Boolean(Number(row.market_visible)),
    active: Boolean(Number(row.active)),
    sortOrder: Number(row.sort_order),
    featured: Boolean(Number(row.featured)),
    limited: Boolean(Number(row.limited)),
    tags,
    metadata,
  };
}

async function nativeCatalog(request, env) {
  await ensureCatalog(env);
  const url = new URL(request.url);
  const type = String(url.searchParams.get("type") || "").trim().toLowerCase();
  const category = String(url.searchParams.get("category") || "").trim().toLowerCase();
  const market = url.searchParams.get("market") === "1";

  const where = ["active=1"];
  const params = [];
  if (type) { params.push(type); where.push("item_type=?"); }
  if (category) { params.push(category); where.push("category=?"); }
  if (market) where.push("market_visible=1");

  const r = await all(env,
    "SELECT * FROM catalog_items WHERE " + where.join(" AND ") +
    " ORDER BY sort_order,gems,name",
    ...params
  );
  return (r.results || []).map(catalogRow);
}

async function nativeGifts(request, env) {
  const url = new URL(request.url);
  const query = new URLSearchParams(url.search);
  query.set("type", "gift");
  return nativeCatalog(
    new Request(new URL("/catalog?" + query.toString(), url).toString(), request),
    env
  );
}

async function nativeEquipped(request, env) {
  const auth = await requireUser(request, env);
  if (auth.error) return auth.error;

  if (request.method === "GET") {
    const r = await all(env,
      "SELECT e.slot,c.id,c.name,c.item_type AS itemType,c.image,c.rarity,c.gems," +
      "c.tradeable,c.animation,c.description FROM user_equipped e " +
      "LEFT JOIN catalog_items c ON c.id=e.item_id WHERE e.user_id=? ORDER BY e.slot",
      auth.user.id
    );
    return r.results || [];
  }

  const body = await request.json().catch(() => ({}));
  const slot = String(body?.slot || "").trim();
  const itemId = String(body?.itemId || "").trim();
  const allowed = new Set([
    "frame","profile_asset","emoji","name_effect","name_color",
    "entrance_effect","room_background","power"
  ]);
  if (!allowed.has(slot)) return json({ error: "INVALID_SLOT" }, 400);

  if (!itemId) {
    await run(env, "DELETE FROM user_equipped WHERE user_id=? AND slot=?", auth.user.id, slot);
    return { ok: true, slot, itemId: null };
  }

  const expected = {
    frame:"frame", profile_asset:"asset", emoji:"emoji", name_effect:"gift",
    name_color:"name_color", entrance_effect:"entrance_effect",
    room_background:"room_background", power:"power",
  };

  const item = await first(env,
    "SELECT id,item_type,active,metadata_json FROM catalog_items WHERE id=?", itemId
  );
  if (!item || !Number(item.active)) return json({ error: "ITEM_NOT_FOUND" }, 404);
  if (item.item_type !== expected[slot]) return json({ error: "ITEM_SLOT_MISMATCH" }, 400);

  const own = await first(env,
    "SELECT quantity FROM inventory WHERE user_id=? AND item_id=?",
    auth.user.id, itemId
  );
  if (!own || Number(own.quantity) < 1) return json({ error: "ITEM_NOT_OWNED" }, 409);

  const statements = [
    env.DB.prepare(
      "INSERT INTO user_equipped(user_id,slot,item_id,updated_at) VALUES (?,?,?,?) " +
      "ON CONFLICT(user_id,slot) DO UPDATE SET item_id=excluded.item_id,updated_at=excluded.updated_at"
    ).bind(auth.user.id, slot, itemId, nowIso())
  ];

  if (slot === "name_color") {
    let metadata = {};
    try { metadata = JSON.parse(item.metadata_json || "{}"); } catch (_) {}
    if (!metadata.hex) return json({ error: "NO_COLOR_VALUE" }, 400);
    statements.push(env.DB.prepare(
      "UPDATE users SET name_color=?,last_active=? WHERE id=?"
    ).bind(String(metadata.hex), nowIso(), auth.user.id));
  }

  await env.DB.batch(statements);
  return { ok: true, slot, itemId };
}

export async function handleNativeCore(request, env, path) {
  if (!CORE_PATHS.has(path)) return null;
  if (String(env.NATIVE_CORE || "0") !== "1") return null;
  if (!env.DB) return json({ error: "NATIVE_CORE_REQUIRES_D1" }, 503);

  try {
    switch (path) {
      case "/auth/guest": return json(await nativeGuest(request, env));
      case "/auth/register": return json(await nativeRegister(request, env));
      case "/auth/login": return json(await nativeLogin(request, env));
      case "/me": return json(await nativeMe(request, env));
      case "/wallet": return json(await nativeWallet(request, env));
      case "/inventory": return json(await nativeInventory(request, env));
      case "/catalog": return json(await nativeCatalog(request, env));
      case "/gifts": return json(await nativeGifts(request, env));
      case "/profile/equipped": return json(await nativeEquipped(request, env));
      default: return null;
    }
  } catch (error) {
    return json({ error: "NATIVE_CORE_ERROR", message: String(error?.message || error) }, 500);
  }
}
