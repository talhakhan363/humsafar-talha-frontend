import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) context.go('/role-select');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Not `const` anymore: AppLocalizations.of(context) needs the context,
    // so this subtree can no longer be built ahead of time.
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.appTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
