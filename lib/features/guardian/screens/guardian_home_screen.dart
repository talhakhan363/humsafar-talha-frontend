import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch mode (dev only)',
            onPressed: () => context.go('/role-select'),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Guardian home screen placeholder.\n'
            'Real dashboard content lands from Phase 2 onward.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
