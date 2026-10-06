class NexoApiConfig {
  // CHANGE 66: Cloudflare is the public API entry point.
  // Railway remains behind the adapter during the migration.
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
    return uri.replace(scheme: scheme, path: '${uri.path}/ws').toString();
  }
}
