import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/network/auth_interceptor.dart';

void main() {
  group('buildAuthHeaders', () {
    test('attaches an Authorization header when a token exists', () async {
      final headers = await buildAuthHeaders(() async => 'test-token-123');

      expect(headers['Authorization'], 'Bearer test-token-123');
    });

    test('returns no headers when there is no token', () async {
      final headers = await buildAuthHeaders(() async => null);

      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers, isEmpty);
    });
  });
}
