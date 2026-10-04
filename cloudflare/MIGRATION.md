# NEXO Cloudflare Migration — CHANGE 65

## Verified current backend

The current NEXO backend is Node.js 20 + Fastify + PostgreSQL, with JWT/bcrypt,
Fastify WebSocket, server-side Chess/Ludo/Domino modules, and Google Play
purchase verification. The repository still contains a Render deployment file.
The Flutter API configuration still defaults to the old Hatchable API.

The repository also contains a separate qa_server.js using in-memory state.
That file is not the production server because the Docker image starts
backend/src/server.js.

## Safe migration decision

Do not rewrite the Flutter API contract.

The Worker keeps these paths stable:
- /auth/guest
- /auth/register
- /auth/login
- /catalog
- /wallet
- /inventory
- /profile/equipped
- /gifts/*
- /chat/*
- /presence
- /signal/*
- /missions/*
- /games/chess/*
- /games/ludo/*
- /games/domino/*
- /games/rooms/*

Until migration is verified, un-migrated paths are proxied through
LEGACY_API_ORIGIN. This is the compatibility layer.

## Target architecture

Cloudflare Worker = API contract + security
Cloudflare D1 = persistent application data
Durable Objects = game-room ownership + real-time state + WebSockets
Cloudflare R2 = NEXO images/assets
Vercel = Web/Admin only, when useful
GitHub = source, CI/CD, APK artifacts

## Migration order

1. Auth + /me
2. Wallet / Energy / Inventory
3. Catalog + Font Color / Name Style
4. Gifts + Profile equipped
5. Daily / Tribe / VIP / SVIP missions
6. Chat / Presence / signaling
7. Chess
8. Domino
9. Ludo 2–4 player
10. Payments + Google Play verification
11. Remove the legacy proxy only after two-device QA

The Worker files in this change are source code and a migration scaffold.
A live Cloudflare account/Worker/D1/R2 deployment requires the account
resources and Cloudflare deployment credentials. No claim of live
Cloudflare provisioning is made by this change.
