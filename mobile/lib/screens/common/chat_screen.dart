import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String title;

  const ChatScreen({super.key, required this.appointmentId, required this.title});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        ref.read(chatProvider.notifier).openChat(widget.appointmentId, userId);
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    ref.read(chatProvider.notifier).closeChat();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _sendMessage(text);
  }

  void _sendMessage(String content) {
    ref.read(chatProvider.notifier).sendMessage(widget.appointmentId, content);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startRecording() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recording is currently unavailable in this build.')),
    );
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _sendVoiceNote() async {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatState = ref.watch(chatProvider);
    final myId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: scheme.outlineVariant, height: 0.8),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.primarySurfaceColor,
              child: Text(
                widget.title.isNotEmpty ? widget.title[0].toUpperCase() : 'D',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Online • Secure connection',
                    style: TextStyle(fontSize: 10, color: scheme.secondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: scheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: context.primarySurfaceColor.withValues(alpha: 0.8),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appointment scoped chat. Strictly confidential.',
                    style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      final isMine = msg.senderId == myId;

                      // Parse Voice note
                      bool isVoice = false;
                      double voiceDuration = 0.0;
                      String voiceUrl = '';
                      if (msg.content.startsWith('{') && msg.content.endsWith('}')) {
                        try {
                          final data = jsonDecode(msg.content);
                          if (data['type'] == 'voice') {
                            isVoice = true;
                            voiceDuration = (data['duration'] as num).toDouble();
                            voiceUrl = data['audioUrl'] ?? '';
                          }
                        } catch (_) {}
                      }

                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMine) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 6, bottom: 4),
                                child: Text(
                                  msg.senderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                ),
                              ),
                            ],
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: isVoice
                                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.76,
                              ),
                              decoration: BoxDecoration(
                                color: isMine ? scheme.primary : scheme.surfaceVariant,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                border: isMine ? null : Border.all(color: scheme.outlineVariant, width: 0.8),
                                boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
                              ),
                              child: isVoice
                                  ? _VoicePlayerBubble(
                                      audioUrl: voiceUrl,
                                      duration: voiceDuration,
                                      isMine: isMine,
                                    )
                                  : Text(
                                      msg.content,
                                      style: TextStyle(
                                        color: isMine ? Colors.white : scheme.onSurface,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: scheme.error.withValues(alpha: 0.1),
              width: double.infinity,
              child: Text(
                chatState.error!,
                style: TextStyle(color: scheme.error, fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _isRecording
                  ? Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.primarySurfaceColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const _PulsingRedDot(),
                          const SizedBox(width: 10),
                          Text(
                            'Recording: ${_formatDuration(_recordSeconds)}',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: scheme.error),
                            onPressed: _cancelRecording,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.send, color: scheme.secondary),
                            onPressed: _sendVoiceNote,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: scheme.outlineVariant, width: 0.8),
                              boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Type a message...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onSubmitted: (_) => _send(),
                                  ),
                                ),
                                if (ApiConstants.enableVoiceNotes)
                                  IconButton(
                                    icon: Icon(Icons.mic, color: scheme.primary),
                                    onPressed: _startRecording,
                                    tooltip: 'Record voice note',
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _send,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: scheme.primary,
                            child: const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: scheme.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VoicePlayerBubble extends StatelessWidget {
  final String audioUrl;
  final double duration;
  final bool isMine;

  const _VoicePlayerBubble({
    required this.audioUrl,
    required this.duration,
    required this.isMine,
  });

  String _formatDisplay(double seconds) {
    final s = seconds.toInt();
    final m = s ~/ 60;
    final rem = s % 60;
    return '$m:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = isMine ? Colors.white : scheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mic_none_outlined,
          color: activeColor.withValues(alpha: 0.6),
          size: 28,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voice Message',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMine ? Colors.white : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatDisplay(duration)} • Playback unavailable in web',
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white70 : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
