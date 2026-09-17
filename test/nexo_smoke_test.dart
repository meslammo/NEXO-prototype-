import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/config/api_config.dart';

void main() {
  test('NEXO API config is valid', () {
    expect(NexoApiConfig.baseUrl, isNotEmpty);
    expect(NexoApiConfig.websocketUrl, contains('/ws'));
  });

  test('NEXO API converts HTTPS to WSS', () {
    final uri = Uri.parse(NexoApiConfig.websocketUrl);
    expect(uri.scheme, 'wss');
  });
}
