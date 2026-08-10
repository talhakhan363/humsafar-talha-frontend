import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

// Wrapping the whole app in ProviderScope is what makes Riverpod state
// available everywhere below it.
void main() {
  runApp(
    const ProviderScope(
      child: HumsafarApp(),
    ),
  );
}

class HumsafarApp extends ConsumerWidget {
  const HumsafarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Humsafar',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
