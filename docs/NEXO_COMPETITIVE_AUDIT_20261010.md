# NEXO Competitive Audit — 2026-10-10

## Scope and safety

This audit is based on source files fetched from `nexo/xena-social-market-missions-20261006`. It is an initial source review, not a successful build or live-device QA report. No production deployment was performed. Work is isolated on `nexo/competitive-audit-20261010`; `main` was not changed.

## Verified source findings

### 1. Flutter app and navigation
- `lib/main.dart` initializes AuthService, RealtimeService, catalog, economy, notifications and the app shell.
- The social-first navigation includes Home, Chat, Tribe, Market and Profile. Games are described in code comments as reachable from Home and live rooms.
- This proves these screens are wired into the Flutter shell; it does not prove every action or backend workflow works.

### 2. Voice rooms
- `lib/screens/room_screen.dart` implements room listing, create/join, nine seat slots, microphone toggle and entry points to Ludo, Domino and Chess.
- The screen refreshes room state through polling (room list every 3 seconds; room state every 2 seconds).
- `lib/services/room_voice_service.dart` uses WebRTC peer connections and realtime signaling for audio between peers.
- Source review alone does not verify audio quality, NAT traversal, multi-peer stability, permissions, reconnection, moderation, or real-device behavior.
- `lib/config/api_config.dart` defaults ICE configuration to Google's public STUN server only. No TURN server is visible in this default; difficult mobile networks may therefore fail to establish media paths.

### 3. API and Cloudflare migration
- `lib/config/api_config.dart` defaults `NEXO_API_URL` to `https://nexo-api-production-05d3.up.railway.app/api/nexo`.
- `cloudflare/wrangler.jsonc` names the Worker `nexo-api-adapter`, sets `LEGACY_API_ORIGIN` to the Railway API, and has `NATIVE_REALTIME` set to `0`.
- `cloudflare/src/index.js` proxies normal API paths to the legacy origin. Its health endpoint attempts `env.DB.prepare("SELECT 1")`, but the inspected Wrangler config does not declare a D1 `DB` binding. The health response can therefore report database as unbound.
- Result: this inspected branch is an adapter/proxy stage, not evidence of a completed D1 backend migration. Do not remove Railway or switch production flags until endpoint coverage, schema, auth, migration and rollback are verified.

### 4. Online games
- `lib/games/ludo/nexo_ludo_online_screen.dart` calls server endpoints for room creation, quick match, join, ready, start, roll and move, and polls room state every second.
- The room screen links to online Ludo, Domino and Chess screens.
- The source review does not establish that all three game APIs exist in the deployed backend, enforce legal moves server-side, recover correctly after reconnect, or pass multi-device testing.

### 5. Store and missions
- `lib/screens/market_screen.dart` and `lib/screens/missions_screen.dart` exist and are integrated as screens.
- `lib/main.dart` hydrates wallet and inventory from API endpoints after login.
- Screen presence is not proof of complete catalog coverage, transactional consistency, claim deduplication, purchase verification, or admin controls. Those require endpoint and integration tests.

## Competitive gaps to prioritize

1. **P0 — Protect current release:** build/CI baseline, login/session, API health, wallet/inventory reads; do not change `main` or deploy automatically.
2. **P0 — Backend truth:** document each API route, current owner (Railway/Worker), auth contract, response schema, and live health result. Verify Worker bindings and current endpoint configuration.
3. **P1 — Voice-room reliability:** verify real two-device audio first, then three-device mesh; add TURN configuration via server-side configuration where needed; verify mic permissions, mute, join/leave cleanup, reconnection, seat ownership, host/moderator permissions, block/report.
4. **P1 — Game correctness:** run two- and three-device tests for Ludo/Chess/Domino; verify server-side turn/move validation, invite codes, ready/start rules, reconnect and finished-game state.
5. **P1 — Economy integrity:** server-authoritative Gems and inventory; idempotent transactions; purchase receipt verification; claim-once mission rewards; audit trail. Do not treat client-side balances as authoritative.
6. **P2 — Competitive social features:** room discovery/favorites/following, host profiles, gift animations and room events after core reliability is proven.
7. **P2 — Admin panel:** role-based access enforced on the server, user/room moderation, reports, catalog/missions configuration, transaction review, and audit logs.

## Required test evidence before claiming completion

- CI/build passes on the exact commit.
- Login/register/session refresh works against the intended production-like API.
- Chat messages persist and appear between two separate accounts/devices.
- Voice audio is heard in both directions on two physical devices, then tested with a third device and on different networks.
- Ludo, Chess and Domino synchronize authoritative state between devices and reject invalid/out-of-turn actions server-side.
- Gems, inventory, purchases and mission rewards survive relaunch and cannot be duplicated by retries.
- Admin endpoints reject normal-user tokens and log privileged actions.
- Worker health reports the expected database/bindings and a deliberate rollback path exists.

## Next safe implementation step

Do not attempt a large redesign yet. First create a route inventory and run the available Flutter/Worker checks on this branch. Then fix one verified blocker at a time in a small reviewed PR. The most consequential finding to resolve before more features is the API/Cloudflare target mismatch and the still-legacy proxy path.
