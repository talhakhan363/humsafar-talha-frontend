import 'package:flutter/material.dart';

import '../../../core/theme/humsafar_colors.dart';

/// One titled block of plain text on the Privacy Policy / Terms screens —
/// shared by both so the two "simple scrolling text screens" (Sarim's 23
/// Nov spec, `docs/design/1.12_identity_access/README.md`'s "Consent
/// line, Privacy Policy and Terms" section) look identical apart from
/// their content.
class LegalSection extends StatelessWidget {
  const LegalSection({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HumsafarColors.text)),
        ],
      ),
    );
  }
}
