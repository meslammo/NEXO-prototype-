# NEXO

QA release build branch: nexo/release-qa-20261002.

The Android release workflow no longer hardcodes a Railway API URL. When no online API is supplied, the app provides a local QA login so the APK can be opened and tested without a backend.

QA login:
- Username: nexo_demo
- Password: 12345678


## NEXO CHANGE 65 — 2026-10-04
Cloudflare adapter scaffold added; Font Color is now the single UI label for former Power items; Daily Missions uses the real Missions screen; APK API URL is build-time configurable. The current Flutter API contract remains unchanged during migration.
