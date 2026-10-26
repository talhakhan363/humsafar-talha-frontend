import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../models/conversation_summary.dart';

/// Task 4.6 — mockups 17 (Guardian: one row per Dependent) and 25
/// (Dependent: one row per Guardian). One screen for both roles:
/// `GET /messages/conversations` already scopes by the caller's own
/// identity (messaging_contract.md point 3 — each Guardian has their
/// own private thread with the Dependent), so there's nothing
/// role-specific left to branch on here beyond each row's own `role`
/// field.
///
/// Reached from `GuardianHomeScreen`'s new AppBar icon, the new
/// "Messages" button on `DependentHomeScreen`, and — for a Guardian —
/// also directly per-Dependent via `DependentDetailScreen`'s "Message"
/// button (which skips this inbox and opens `ChatScreen` straight away,
/// since the peer is already known there).
///
/// Named scope cut: mockup 25's per-row "Call" button is not built
/// here — Task 4.7 (calls) hasn't shipped yet, so there's nothing for
/// it to call. Flagged in the delivery notes and the test case log, not
/// silently dropped; 4.7 adds it once `POST /calls` exists to wire it
/// to.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  List<ConversationSummary>? _conversations;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/messages/conversations');
      if (!mounted) return;
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ConversationSummary.fromJson)
          .toList();
      setState(() => _conversations = items);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Maps the peer's own `role` (their Guardian role, from this user's
  /// point of view — only meaningful when the signed-in user is a
  /// Dependent looking at their Guardians) to its Urdu-capable label,
  /// reusing the same keys `DependentDetailScreen`/`GuardianHomeScreen`
  /// already use. Anything else (e.g. a Guardian's own Dependents,
  /// which this field isn't documented for) shows no badge rather than
  /// guessing a label.
  String? _roleLabel(AppLocalizations l10n, String? role) {
    switch (role) {
      case 'primary':
        return l10n.primaryGuardianFullLabel;
      case 'secondary':
        return l10n.secondaryGuardianFullLabel;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messagesScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    final conversations = _conversations ?? [];
    if (conversations.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(l10n.noConversationsYetMessage, textAlign: TextAlign.center),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: conversations.map((c) {
        final roleLabel = _roleLabel(l10n, c.role);
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
            title: Text(c.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (roleLabel != null)
                  Text(roleLabel, style: const TextStyle(fontSize: 12, color: HumsafarColors.muted)),
                Row(
                  children: [
                    if (c.lastMessageIsVoice) ...[
                      const Icon(Icons.mic, size: 16, color: HumsafarColors.warning),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        c.lastMessageIsVoice
                            ? l10n.urgentVoiceMessageLabel
                            : (c.lastMessagePreview ?? l10n.noMessagesYetPreview),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: roleLabel != null,
            trailing: c.unreadCount > 0
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: HumsafarColors.danger,
                    child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => context.push('/messages/chat', extra: {'peerId': c.userId, 'peerName': c.name}),
          ),
        );
      }).toList(),
    );
  }
}
