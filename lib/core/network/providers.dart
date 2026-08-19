import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../auth/token_storage.dart';
import 'api_client.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(readAccessToken: tokenStorage.readAccessToken);
});

/// Swap the implementation here at Task 2.5 — every screen/provider that
/// needs auth should depend on `authRepositoryProvider`, never construct
/// `UnimplementedAuthRepository` directly, so wiring in the real
/// implementation later is a one-line change in this file instead of a
/// search-and-replace across the app.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const UnimplementedAuthRepository();
});
