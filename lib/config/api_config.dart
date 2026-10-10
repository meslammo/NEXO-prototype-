class NexoApiConfig {
  // Cloudflare is the public API entry point. The Worker keeps legacy routes
  // working through Railway until each subsystem passes migration QA.
  static const String baseUrl = String.fromEnvironment(
    'NEXO_API_URL',
    defaultValue: 'https://nexo-prototype.meslammohamed423.workers.dev/api/nexo',
  );
  static const String iceServersJson = String.fromEnvironment(
    'NEXO_ICE_SERVERS',
    defaultValue: '[{"urls":["stun:stun.l.google.com:19302"]}]',
  );
  static bool get configured =>
      baseUrl.trim().isNotEmpty && Uri.tryParse(baseUrl)?.host.isNotEmpty == true;

  static String get websocketUrl {
    if (!configured) return '';
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    // The adapter accepts the legacy-compatible /ws path at the Worker root.
    return uri.replace(scheme: scheme, path: '/ws').toString();
  }
}
