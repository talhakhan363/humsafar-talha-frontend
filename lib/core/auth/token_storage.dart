import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, encrypted-at-rest storage for the JWT access/refresh token
/// pair (Android Keystore / iOS Keychain backed) — deliberately NOT
/// shared_preferences, since these tokens grant access to a Dependent's
/// medical data (NFR-04, SDS Security Design's encryption-at-rest
/// requirement extends in spirit to credentials, not just records).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'humsafar_access_token';
  static const _refreshTokenKey = 'humsafar_refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
