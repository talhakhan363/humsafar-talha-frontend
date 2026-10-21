/// One message, as returned by `POST /messages`, `GET /messages`, and
/// `POST /messages/voice` (messaging_contract.md). `type` is `"text"` or
/// `"priority_voice"`; a text message's `contentUrl`/`durationS` are
/// null, a priority_voice message's `body` is null.
class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.body,
    required this.contentUrl,
    required this.priority,
    required this.sentAt,
    required this.readAt,
    required this.fromMe,
    required this.durationS,
    this.alreadySent = false,
  });

  final String messageId;
  final String senderId;
  final String receiverId;
  final String type; // "text" | "priority_voice"
  final String? body;
  final String? contentUrl;
  final String priority; // "standard" | "critical"
  final DateTime sentAt;
  final DateTime? readAt;
  final bool fromMe;
  final int? durationS;

  /// True when this reply is a safe-retry repeat (`client_id` reused) —
  /// not currently branched on anywhere: a repeat carries the exact same
  /// message data as the original, so the caller treats it as an
  /// ordinary success either way.
  final bool alreadySent;

  bool get isVoice => type == 'priority_voice';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messageId: json['message_id'] as String,
        senderId: json['sender_id'] as String,
        receiverId: json['receiver_id'] as String,
        type: json['type'] as String? ?? 'text',
        body: json['body'] as String?,
        contentUrl: json['content_url'] as String?,
        priority: json['priority'] as String? ?? 'standard',
        sentAt: DateTime.parse(json['sent_at'] as String),
        readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
        fromMe: json['from_me'] as bool? ?? false,
        durationS: json['duration_s'] as int?,
        alreadySent: json['already_sent'] as bool? ?? false,
      );
}
