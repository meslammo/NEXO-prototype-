import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/config/api_config.dart';

void main() {
  test('NEXO config exposes a websocket endpoint when API is configured', () {
    if (!NexoApiConfig.configured) {
      expect(NexoApiConfig.websocketUrl, isEmpty);
      return;
    }
    final uri = Uri.parse(NexoApiConfig.websocketUrl);
    expect(uri.scheme, anyOf('wss', 'ws'));
    expect(uri.path, '/ws');
  });
}
