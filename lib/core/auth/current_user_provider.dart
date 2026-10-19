import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_user.dart';

/// The signed-in user for this session, or null when logged out. Screens
/// read this to decide what to show; `RealAuthRepository` writes to it on
/// login/register/logout — nothing else should set it directly.
final currentUserProvider = StateProvider<AppUser?>((ref) => null);
