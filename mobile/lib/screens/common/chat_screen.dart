import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_helper.dart';
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
  late final AudioHelper _audioHelper;

  @override
  void initState() {
    super.initState();
    _audioHelper = AudioHelper.create()..init();
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
    _audioHelper.dispose();
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
    final hasPerm = await _audioHelper.hasPermission();
    if (!hasPerm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required to record voice notes.')),
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
    });
    await _audioHelper.startRecording();
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    _audioHelper.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _sendVoiceNote() async {
    _recordTimer?.cancel();
    final duration = _recordSeconds > 0 ? _recordSeconds : 3;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    try {
      final bytes = await _audioHelper.stopRecording();
      if (bytes == null || bytes.isEmpty) return;

      final url = await ref.read(chatProvider.notifier).uploadVoiceBytes(bytes);
      if (url == null) throw Exception("Failed to upload audio file");

      final voicePayload = jsonEncode({
        'type': 'voice',
        'audioUrl': url,
        'duration': duration.toDouble(),
      });

      _sendMessage(voicePayload);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading voice note: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final myId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 0.8),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                widget.title.isNotEmpty ? widget.title[0].toUpperCase() : 'D',
                style: const TextStyle(
                  color: AppColors.primary,
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online • Secure connection',
                    style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primarySurface.withValues(alpha: 0.8),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Appointment scoped chat. Strictly confidential.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
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
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
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
                                color: isMine ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                border: isMine ? null : Border.all(color: AppColors.border, width: 0.8),
                                boxShadow: AppShadows.sm,
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
                                        color: isMine ? Colors.white : AppColors.textPrimary,
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
              color: AppColors.error.withValues(alpha: 0.1),
              width: double.infinity,
              child: Text(
                chatState.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
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
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const _PulsingRedDot(),
                          const SizedBox(width: 10),
                          Text(
                            'Recording: ${_formatDuration(_recordSeconds)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: _cancelRecording,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: AppColors.secondary),
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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border, width: 0.8),
                              boxShadow: AppShadows.sm,
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
                                    icon: const Icon(Icons.mic, color: AppColors.primary),
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
                            backgroundColor: AppColors.primary,
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
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VoicePlayerBubble extends StatefulWidget {
  final String audioUrl;
  final double duration;
  final bool isMine;

  const _VoicePlayerBubble({required this.audioUrl, required this.duration, required this.isMine});

  @override
  State<_VoicePlayerBubble> createState() => _VoicePlayerBubbleState();
}

class _VoicePlayerBubbleState extends State<_VoicePlayerBubble> {
  bool _isPlaying = false;
  double _progress = 0.0;
  double _displayDuration = 0.0;
  late final AudioHelper _audioHelper;

  @override
  void initState() {
    super.initState();
    _displayDuration = widget.duration;
    _audioHelper = AudioHelper.create()..init();
  }

  @override
  void dispose() {
    _audioHelper.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioHelper.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });

      _audioHelper.play(
        widget.audioUrl,
        onComplete: () {
          setState(() {
            _isPlaying = false;
            _progress = 0.0;
          });
        },
        onProgress: (progress, duration) {
          setState(() {
            _progress = progress;
            if (duration > 0) {
              _displayDuration = duration;
            }
          });
        },
      );
    }
  }

  String _formatDisplay(double seconds) {
    final s = seconds.toInt();
    final m = s ~/ 60;
    final rem = s % 60;
    return '$m:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMine ? Colors.white : AppColors.primary;
    final trackColor = widget.isMine ? Colors.white24 : AppColors.border;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: activeColor,
            size: 36,
          ),
          onPressed: _togglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 12,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: activeColor,
                    inactiveTrackColor: trackColor,
                    thumbColor: activeColor,
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (val) {
                      setState(() {
                        _progress = val;
                      });
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDisplay(_progress * _displayDuration),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatDisplay(_displayDuration),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
