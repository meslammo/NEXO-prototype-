# NEXO CHANGE 69 — API unification and D1 gate

## What this change does

- Sets Flutter's default public API base to the existing NEXO Cloudflare Worker:
  `https://nexo-prototype.meslammohamed423.workers.dev/api/nexo`.
- Adds a root `wrangler.jsonc` so the repo-root command `npx wrangler deploy` has an explicit Worker entry point at `cloudflare/src/index.js`.
- Keeps the legacy Railway API as `LEGACY_API_ORIGIN` for routes not migrated yet.
- Keeps `NATIVE_CORE`, `NATIVE_REALTIME`, `NATIVE_GAMES`, and `PAYMENTS_READY` disabled; this change does not redirect core API routes to D1.
- Adds a GitHub Actions dry-run check for the root Worker configuration.

## D1 status — deliberately not enabled

The production D1 database UUID has not been verified through the Cloudflare account in this task. A fabricated or placeholder UUID must not be put into the deployable root config because that can break deployment and does not bind the real database.

Until the actual `nexo-production` database UUID is confirmed and the binding is added, Worker health is expected to report `database: "unbound"`. Do not set `NATIVE_CORE=1` or apply migrations to an unverified database.

Once the real ID is confirmed:
1. Add a `d1_databases` binding with `binding: "DB"`, `database_name: "nexo-production"`, that exact `database_id`, and `migrations_dir: "cloudflare/migrations"`.
2. Confirm the target database has the expected migration history before applying new migrations.
3. Run the existing D1 migrations against that exact database.
4. Add the existing backend's matching JWT secret as a Cloudflare Worker secret; never commit the value.
5. Verify `/health`, then test auth, wallet, inventory, catalog and equipped-profile endpoints before enabling any native route.

## Rollback and safety

Railway remains available behind the adapter. For an APK rollback, use the existing `NEXO_API_URL` dart define set to the verified legacy API URL. No production deployment is performed by this source change alone.
