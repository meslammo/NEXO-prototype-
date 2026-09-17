import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/config/api_config.dart';

void main() {
  test('NEXO API configuration is present', () {
    expect(NexoApiConfig.baseUrl, 'https://nexo-api-production-05d3.up.railway.app');
    expect(NexoApiConfig.configured, isTrue);
  });

  test('NEXO websocket endpoint is derived from HTTPS API', () {
    final uri = Uri.parse(NexoApiConfig.websocketUrl);
    expect(uri.scheme, 'wss');
    expect(uri.path, '/ws');
  });
}
