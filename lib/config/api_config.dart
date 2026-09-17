class NexoApiConfig {
  static const String baseUrl = String.fromEnvironment('NEXO_API_URL', defaultValue: '');
  static const String iceServersJson = String.fromEnvironment(
    'NEXO_ICE_SERVERS',
    defaultValue: '[{"urls":["stun:stun.l.google.com:19302"]}]',
  );
  static bool get configured => baseUrl.trim().isNotEmpty;
  static String get websocketUrl {
    if (!configured) return '';
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme, path: '/ws').toString();
  }
}