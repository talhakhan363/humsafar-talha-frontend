import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DependentHomeScreen extends StatelessWidget {
  const DependentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dependent App'),
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
            'Dependent home screen placeholder.\n'
            'The 3 safety actions (Panic Mode, Wellness Check, Medication) '
            'land here from Task 3.10 onward.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
