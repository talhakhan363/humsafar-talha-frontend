import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart' show ResponseType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/auth/current_user_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../calls/widgets/call_type_picker.dart';
import '../models/chat_message.dart';
import '../widgets/voice_recorder_sheet.dart';

/// Task 4.6/4.8 — mockups 17b (Guardian) and 25b (Dependent). One
/// screen for both roles, branching only on `currentUserProvider`'s
/// role (mic button + no quick replies for a Guardian; quick replies +
/// no mic for a Dependent, per mockup 25b's "no mic" note) — the rest
/// (loading, sending, retry, read receipts, pagination, voice playback)
/// is identical either way.
///
/// `_messages` is kept in the API's own newest-first order and rendered
/// in a `reverse: true` ListView — the standard Flutter chat idiom:
/// index 0 (newest) anchors at the visible bottom with no manual scroll
/// management needed. A fresh outgoing draft is the newest thing in the
/// thread, so it's inserted at index 0 too; "load earlier" results are
/// older, so they're appended at the end of the list (which is the
/// visual *top*, where the "Load earlier messages" button also lives).
///
/// Task 4.7 (2026-10-22): added a Guardian-only "Call" AppBar icon
/// (mockup 17b's call bar, simplified to one icon + a Voice/Video
/// picker rather than a dedicated bar — see `call_type_picker.dart`),
/// opening `OutgoingCallScreen`. A Dependent never sees it — same
/// "only a Guardian initiates" shape as the mic button above, inferred
/// from the mockup set (17d-17f are Guardian-side, 25d is only
/// "Incoming call") since `call_contract.md` itself hasn't been read
/// fresh in this sandbox — flagged alongside this task's other named
/// field-name caveats, see `outgoing_call_screen.dart`'s doc comment.
///
/// Named scope cuts (flagged, not silently dropped):
/// - **Playing a received urgent voice message does not call
///   `POST /notifications/{id}/acknowledge`.** The chat message object
///   has no `notification_id` on it (only the *notification* carries
///   `data.message_id`/`data.from_user_id` — messaging_contract.md
///   doesn't expose the reverse link from a message back to its
///   notification), so there's no id to acknowledge with here. Playing
///   the bubble is treated as "heard it" for this screen's own UI (the
///   icon flips to a played state), but the underlying critical
///   `voice_message` notification stays technically unacknowledged.
///   Flagged for Abdullah: either expose `notification_id` on the
///   message, or accept acknowledging by `message_id` directly.
/// - **A push tap for `message`/`voice_message` opens this screen's
///   inbox (`MessagesScreen`), not a specific thread directly** — see
///   `push_service.dart`'s updated `routeForNotificationType` doc
///   comment for why (same "self-resolving list, don't trust push
///   payload data for navigation" reasoning as the Alerts screen).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.peerId, required this.peerName});

  final String peerId;
  final String peerName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

enum _DraftStatus { sending, failed }

class _Draft {
  _Draft({required this.clientId, required this.body, required this.status});
  final String clientId;
  final String body;
  _DraftStatus status;
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final List<_Draft> _drafts = [];
  String? _nextBefore;
  bool _isLoading = true;
  bool _isLoadingEarlier = false;
  String? _loadError;
  String? _playingMessageId;
  String? _loadingAudioMessageId;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            '/messages',
            queryParameters: {'with_user_id': widget.peerId, 'limit': 30},
          );
      final items =
          (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(items);
        _nextBefore = response.data?['next_before'] as String?;
      });
      unawaited(_markRead());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead() async {
    try {
      await ref.read(apiClientProvider).post('/messages/read', data: {'with_user_id': widget.peerId});
    } on ApiException {
      // best-effort — read receipts are a nicety, never worth blocking
      // or erroring the chat over, same reasoning as every other
      // best-effort call in this app (e.g. push-token registration).
    }
  }

  Future<void> _loadEarlier() async {
    final before = _nextBefore;
    if (before == null) return;
    setState(() => _isLoadingEarlier = true);
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            '/messages',
            queryParameters: {'with_user_id': widget.peerId, 'limit': 30, 'before': before},
          );
      final items =
          (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _messages.addAll(items);
        _nextBefore = response.data?['next_before'] as String?;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoadingEarlier = false);
    }
  }

  String _newClientId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  Future<void> _sendText() async {
    final body = _textController.text.trim();
    if (body.isEmpty) return;
    _textController.clear();
    await _queueAndSend(body);
  }

  Future<void> _sendQuickReply(String text) => _queueAndSend(text);

  Future<void> _queueAndSend(String body) async {
    final clientId = _newClientId();
    setState(() => _drafts.add(_Draft(clientId: clientId, body: body, status: _DraftStatus.sending)));
    await _attemptSend(clientId, body);
  }

  Future<void> _attemptSend(String clientId, String body) async {
    final draft = _drafts.firstWhere((d) => d.clientId == clientId);
    setState(() => draft.status = _DraftStatus.sending);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            '/messages',
            data: {'receiver_id': widget.peerId, 'body': body, 'client_id': clientId},
          );
      final message = ChatMessage.fromJson(response.data!);
      if (!mounted) return;
      setState(() {
        _messages.insert(0, message);
        _drafts.removeWhere((d) => d.clientId == clientId);
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => draft.status = _DraftStatus.failed);
    }
  }

  Future<void> _startCall() async {
    final isVideo = await showCallTypePicker(context);
    if (isVideo == null || !mounted) return;
    context.push('/calls/outgoing', extra: {'calleeId': widget.peerId, 'calleeName': widget.peerName, 'isVideo': isVideo});
  }

  Future<void> _openVoiceRecorder() async {
    final result = await showModalBottomSheet<ChatMessage>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VoiceRecorderSheet(receiverId: widget.peerId, peerName: widget.peerName),
    );
    if (result != null && mounted) {
      setState(() => _messages.insert(0, result));
    }
  }

  Future<void> _toggleVoicePlayback(ChatMessage message) async {
    final player = ref.read(audioPlayerSourceProvider);
    if (_playingMessageId == message.messageId) {
      await player.stop();
      if (mounted) setState(() => _playingMessageId = null);
      return;
    }
    setState(() => _loadingAudioMessageId = message.messageId);
    try {
      final response =
          await ref.read(apiClientProvider).get<List<int>>(message.contentUrl!, responseType: ResponseType.bytes);
      final bytes = Uint8List.fromList(response.data ?? []);
      await player.playBytes(bytes);
      if (!mounted) return;
      setState(() {
        _playingMessageId = message.messageId;
        _loadingAudioMessageId = null;
      });
      unawaited(player.onComplete.first.then((_) {
        if (mounted && _playingMessageId == message.messageId) setState(() => _playingMessageId = null);
      }));
    } on ApiException {
      if (!mounted) return;
      setState(() => _loadingAudioMessageId = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.audioDownloadFailedMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final isGuardian = user?.isGuardian ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        actions: [
          if (isGuardian) IconButton(onPressed: _startCall, icon: const Icon(Icons.call), tooltip: l10n.callButtonTooltip),
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(l10n)),
          _buildComposer(l10n, isGuardian),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppLocalizations l10n) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadMessages, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    final displayDrafts = _drafts.reversed.toList();
    if (displayDrafts.isEmpty && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.startConversationMessage, textAlign: TextAlign.center),
        ),
      );
    }
    String? lastFromMeId;
    for (final m in _messages) {
      if (m.fromMe) {
        lastFromMeId = m.messageId;
        break;
      }
    }
    final hasEarlier = _nextBefore != null;
    final itemCount = displayDrafts.length + _messages.length + (hasEarlier ? 1 : 0);
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < displayDrafts.length) {
          return _buildDraftBubble(l10n, displayDrafts[index]);
        }
        final messageIndex = index - displayDrafts.length;
        if (messageIndex < _messages.length) {
          final message = _messages[messageIndex];
          final showRead = message.fromMe && message.messageId == lastFromMeId && message.readAt != null;
          return _buildMessageBubble(l10n, message, showReadCaption: showRead);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: _isLoadingEarlier
                ? const CircularProgressIndicator()
                : TextButton(onPressed: _loadEarlier, child: Text(l10n.loadEarlierMessagesButton)),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(AppLocalizations l10n, ChatMessage message, {required bool showReadCaption}) {
    final isMe = message.fromMe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isVoice ? HumsafarColors.warningTint : (isMe ? HumsafarColors.primarySoft : HumsafarColors.tabTrack),
                borderRadius: BorderRadius.circular(12),
              ),
              child: message.isVoice ? _buildVoiceBubbleContent(l10n, message) : Text(message.body ?? ''),
            ),
          ),
          if (showReadCaption)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l10n.readLabel, style: const TextStyle(fontSize: 11, color: HumsafarColors.muted)),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubbleContent(AppLocalizations l10n, ChatMessage message) {
    final isPlaying = _playingMessageId == message.messageId;
    final isLoading = _loadingAudioMessageId == message.messageId;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isLoading
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(
                onPressed: () => _toggleVoicePlayback(message),
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: HumsafarColors.warning),
              ),
        const SizedBox(width: 4),
        Text(l10n.urgentVoiceMessageLabel),
        if (message.durationS != null) ...[
          const SizedBox(width: 6),
          Text(formatCountdown(Duration(seconds: message.durationS!)), style: const TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildDraftBubble(AppLocalizations l10n, _Draft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: HumsafarColors.primaryTint, borderRadius: BorderRadius.circular(12)),
              child: Text(draft.body),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: draft.status == _DraftStatus.sending
                ? Text(l10n.sendingLabel, style: const TextStyle(fontSize: 11, color: HumsafarColors.muted))
                : GestureDetector(
                    onTap: () => _attemptSend(draft.clientId, draft.body),
                    child: Text(
                      l10n.notSentTapToRetryLabel,
                      style: const TextStyle(fontSize: 11, color: HumsafarColors.warning, decoration: TextDecoration.underline),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(AppLocalizations l10n, bool isGuardian) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGuardian)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quickReplyChip(l10n.quickReplyIAmFine),
                    _quickReplyChip(l10n.quickReplyCallMe),
                    _quickReplyChip(l10n.quickReplyYes),
                    _quickReplyChip(l10n.quickReplyNo),
                  ],
                ),
              ),
            Row(
              children: [
                if (isGuardian)
                  IconButton(
                    onPressed: _openVoiceRecorder,
                    icon: const Icon(Icons.mic),
                    tooltip: l10n.recordUrgentVoiceSheetTitle,
                  ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLength: 2000,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: l10n.messageInputHint),
                    buildCounter: (context, {required currentLength, required isFocused, required maxLength}) =>
                        currentLength >= 1800 ? Text('$currentLength/$maxLength') : null,
                  ),
                ),
                IconButton(onPressed: _sendText, icon: const Icon(Icons.send), tooltip: l10n.messageSendTooltip),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickReplyChip(String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ActionChip(label: Text(label), onPressed: () => _sendQuickReply(label)),
      );
}
