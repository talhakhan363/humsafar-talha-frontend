import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// Task 4.7 — shared Voice/Video picker, used by both `ChatScreen`'s
/// AppBar call button and `DependentDetailScreen`'s direct "Call"
/// button, so the choice is asked the same way from either entry point
/// instead of two near-identical bottom sheets. Returns `true` for
/// video, `false` for voice, `null` if dismissed without a choice.
Future<bool?> showCallTypePicker(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.call),
            title: Text(l10n.voiceCallOption),
            onTap: () => Navigator.of(sheetContext).pop(false),
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: Text(l10n.videoCallOption),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    ),
  );
}
