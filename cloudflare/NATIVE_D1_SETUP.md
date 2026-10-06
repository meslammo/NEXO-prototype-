# NEXO native D1 core — one-time Cloudflare activation

This change keeps NATIVE_CORE=0 until D1 and JWT are actually bound. Password storage uses the same pbkdf2sha256 format the Node backend already accepts, avoiding a JS bcrypt dependency inside the Worker.

## 1) Create D1
Run from the cloudflare/ directory after authenticating Wrangler:

npx wrangler d1 create nexo-production

Cloudflare returns the database UUID. Put that UUID into the DB binding in wrangler.jsonc:

"d1_databases": [
  {
    "binding": "DB",
    "database_name": "nexo-production",
    "database_id": "<THE-UUID-CLOUDFLARE-RETURNS>",
    "migrations_dir": "migrations"
  }
]

## 2) Apply migrations

npx wrangler d1 migrations apply nexo-production --remote

## 3) Add the JWT secret

The value must be the SAME 32+ character JWT secret currently used by the Node backend.
Do not commit or paste it into Git.

npx wrangler secret put JWT_SECRET --name nexo-api-adapter

## 4) Enable native Core only after the database exists

Set:
NATIVE_CORE=1
NATIVE_REALTIME=0
NATIVE_GAMES=0
PAYMENTS_READY=0

## 5) Existing-user migration

On the first successful login while native Core is enabled, an account that is not yet in D1 is authenticated once against the legacy API. The Worker then copies the user/wallet/inventory/equipped state into D1 and hashes the submitted password with Worker PBKDF2. Future logins for that account are D1-native.

## 6) QA gate

Against:
https://nexo-prototype.meslammohamed423.workers.dev/api/nexo

Test:
POST /auth/register
POST /auth/login
GET /me
GET /wallet
GET /inventory
GET /catalog

Then test one existing account. Keep NATIVE_REALTIME and NATIVE_GAMES disabled until all Core checks pass.
