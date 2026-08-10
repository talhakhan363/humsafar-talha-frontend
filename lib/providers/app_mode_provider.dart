import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { guardian, dependent }

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.guardian);
