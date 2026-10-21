/// One row from `GET /messages/conversations` (messaging_contract.md):
/// one entry per person the signed-in user can message — a linked
/// Dependent for a Guardian, or a linked Guardian for a Dependent.
///
/// [lastMessagePreview]/[lastMessageIsVoice] are parsed defensively: the
/// contract names the field `last_message` but doesn't pin down its
/// exact shape (a nested message-like object vs. a plain string), so
/// this reads either without assuming one or the other — same
/// "grounded in what's locked in the contract, defensive about what
/// isn't" approach as `MissedDoseScreen`'s handling of `open_alert_tier`
/// (Task 3.14).
class ConversationSummary {
  const ConversationSummary({
    required this.userId,
    required this.name,
    required this.role,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.lastMessageIsVoice,
  });

  final String userId;
  final String name;
  final String? role; // "primary" | "secondary" | other/null
  final int unreadCount;
  final String? lastMessagePreview;
  final bool lastMessageIsVoice;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    String? preview;
    var isVoice = false;
    if (last is Map<String, dynamic>) {
      isVoice = last['type'] == 'priority_voice';
      preview = last['body'] as String?;
    } else if (last is String) {
      preview = last;
    }
    return ConversationSummary(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      role: json['role'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessagePreview: preview,
      lastMessageIsVoice: isVoice,
    );
  }
}
