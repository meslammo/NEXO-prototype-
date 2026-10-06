# NEXO CHANGE 66 — Cloudflare Unification

## Safe architecture

NEXO APK -> Cloudflare Worker -> current Railway/PostgreSQL backend.

Railway remains the compatibility source of truth until each native Cloudflare subsystem passes QA. No destructive cutover is performed by this change.

## Phase 2 — API unification

Public API:
https://nexo-prototype.meslammohamed423.workers.dev/api/nexo

Flutter now defaults to the Cloudflare URL. The Worker preserves the existing API contract and proxies unmigrated endpoints to Railway.

Rollback: build with --dart-define=NEXO_API_URL=<legacy-api-url>.

## Phase 3 — D1 core

Migration order:
1. users/auth
2. wallet + energy ledger
3. catalog/inventory/equipped
4. missions
5. notifications

D1 becomes source-of-truth only after export/import reconciliation and endpoint QA.

Required production bindings/secrets:
- D1 binding: DB
- Workers secret: JWT_SECRET
- one-time reconciliation/admin secret, if used

## Phase 4 — realtime/social

Migration order:
1. presence
2. chat persistence
3. signaling queue
4. room membership
5. WebRTC configuration

Durable Objects coordinate rooms. WebRTC carries media; Worker is not a media relay.

## Phase 5 — games

Authoritative lifecycle:
Create Room -> Join Code -> Ready -> Start -> Gameplay -> Result.

Chess, Ludo and Domino must validate moves server-side. Durable Objects coordinate live room state; D1 stores durable room/move/result records.

The existing Durable Object is a safe room primitive. Native realtime remains disabled until JWT and two-device QA pass.

## Phase 6 — payments

Payment endpoints remain provider-specific and server-authoritative.

Google Play production preparation:
- fixed Android application ID
- signed release build
- Play product IDs
- service-account credentials stored only as secrets
- purchase-token verification
- acknowledgement/consumption
- idempotency by provider transaction/purchase token
- refund/revoke handling
- Gems ledger

PAYMENTS_READY remains off until sandbox/provider credentials are configured and tested.

## Final cutover gate

Do not remove Railway until:
- API compatibility tests pass
- D1 reconciliation is complete
- two-device chat/presence/signaling passes
- Chess/Ludo/Domino room lifecycle and authoritative move tests pass
- payment sandbox/idempotency tests pass
- rollback build is verified
