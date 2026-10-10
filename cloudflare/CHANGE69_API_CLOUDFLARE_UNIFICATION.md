# NEXO CHANGE 69 — API unification and D1 binding

## What this change does

- Sets Flutter's default public API base to the existing NEXO Cloudflare Worker:
  `https://nexo-prototype.meslammohamed423.workers.dev/api/nexo`.
- Adds a root `wrangler.jsonc` so the repo-root command `npx wrangler deploy` has an explicit Worker entry point at `cloudflare/src/index.js`.
- Binds the verified Cloudflare D1 database `nexo-production` to Worker binding `DB`.
- Keeps the legacy Railway API as `LEGACY_API_ORIGIN` for routes not migrated yet.
- Keeps `NATIVE_CORE`, `NATIVE_REALTIME`, `NATIVE_GAMES`, and `PAYMENTS_READY` disabled; this change does not redirect core API routes to D1.
- Adds a GitHub Actions dry-run check for the root Worker configuration.

## D1 status and safety

The verified database is `nexo-production`, UUID `0c181357-1d32-4393-8375-6e5c5dc548f2`. Cloudflare's dashboard showed zero tables and zero queries at the time of inspection.

The repository search did not find a `cloudflare/migrations` directory or SQL schema migrations in the branch. Therefore this change adds only the D1 binding; it does not create tables or apply migrations. A successful `SELECT 1` health probe would prove connectivity only, not that the NEXO application schema exists.

Before routing authentication, wallet, inventory, catalog, missions, rooms, or games to D1:
1. Design and review schema migrations against the current backend data model.
2. Confirm backup/rollback and data migration requirements.
3. Apply migrations to the verified database only after reviewing the exact SQL.
4. Add the existing backend's matching JWT secret as a Cloudflare Worker secret; never commit the value.
5. Verify `/health`, then test auth, wallet, inventory, catalog and equipped-profile endpoints before enabling any native route.

## Rollback and deployment

Railway remains available behind the adapter. The source change alone does not deploy production. Do not enable native routes until the D1 schema and API contract tests pass. For an APK rollback, use the existing `NEXO_API_URL` dart define set to the verified legacy API URL.
