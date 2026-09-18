# NEXO Production Readiness

## Ready in code
- Unified server catalog for Gifts, Frames, Assets, Emoji and Crafted items.
- Server-owned inventory and item tradeability.
- Server-owned equipped cosmetics with Profile slots.
- Admin Control Center for catalog CRUD/toggle, users, wallet controls, bans, announcements, trades and security logs.
- Idempotent purchases and crafting.
- WebRTC ICE configuration reads RTC_ICE_SERVERS_JSON.
- Google Play verification endpoint reads GOOGLE_SERVICE_ACCOUNT_JSON and ANDROID_PACKAGE_NAME.
- Android workflow keeps a stable package organization/name and can load a persistent signing key from GitHub Actions secrets.
- Windows CI uses PowerShell-compatible project generation.
- Device push-token registry endpoints are present at /push/register and /push/unregister.

## External production configuration still required
These cannot be invented or safely committed as source code:
- DATABASE_URL for production PostgreSQL.
- JWT_SECRET (32+ random characters).
- NEXO_ADMIN_KEY (24+ random characters) for the Admin Panel.
- RTC_ICE_SERVERS_JSON containing a real TURN service for production voice/video; STUN fallback is development-only.
- NEXO_KEYSTORE_BASE64, NEXO_KEY_ALIAS, NEXO_KEY_PASSWORD, NEXO_STORE_PASSWORD for stable Android updates.
- ANDROID_PACKAGE_NAME (default: com.nexo.nexo_app) must match the Play Console package.
- GOOGLE_SERVICE_ACCOUNT_JSON and Google Play product configuration for real Play billing verification.
- Firebase/APNs provider credentials and a client-side push SDK/configuration for actual push delivery. The backend token registry is ready, but delivery credentials are external.
- Apple signing certificates/profiles for signed iOS distribution.
- Windows packaging/signing certificate if a signed installer is required.

## Release rule
Do not claim a production-signed Android/iOS/Windows release until the corresponding external credentials and platform signing steps pass in CI.
