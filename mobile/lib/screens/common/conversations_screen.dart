import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_components.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _isLoading = false;
  List<dynamic> _conversations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/appointments/conversations/active');
      setState(() {
        _conversations = res.data['conversations'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load messages inbox';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);
    final isDoctor = authState.user?.role.name == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: scheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchConversations,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No active conversations',
                      subtitle: isDoctor
                          ? 'Patient chats will appear here once you confirm their appointment requests.'
                          : 'You can chat with your doctor once they confirm your appointment request.',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchConversations,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        itemCount: _conversations.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: scheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final appointmentId = conv['appointmentId'];
                          final name = conv['otherParticipantName'] ?? 'DocBook User';
                          final specialty = conv['otherParticipantSpecialty'] ?? '';
                          final rawMessage = conv['latestMessage'] ?? '';
                          final timeText = _formatTime(conv['latestMessageTime']);
                          final unreadCount = conv['unreadCount'] ?? 0;
                          final status = conv['status'] ?? 'confirmed';

                          // Parse JSON message (for audio/voice preview)
                          String previewText = rawMessage;
                          if (rawMessage.startsWith('{') && rawMessage.endsWith('}')) {
                            try {
                              if (rawMessage.contains('"type":"voice"') || rawMessage.contains('"type": "voice"')) {
                                previewText = '🎤 Voice note';
                              }
                            } catch (_) {}
                          }

                          return InkWell(
                            onTap: () async {
                              final chatPath = isDoctor
                                  ? '/doctor/appointment/$appointmentId/chat'
                                  : '/patient/appointment/$appointmentId/chat';
                              await context.push(chatPath);
                              _fetchConversations(); // refresh unread count on return
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                                    fontSize: 15,
                                                    color: scheme.onSurface,
                                                  ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              timeText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (specialty.isNotEmpty) ...[
                                          Text(
                                            specialty,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                        ],
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                previewText,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                                  color: unreadCount > 0 ? scheme.onSurface : scheme.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (status == 'completed') ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: scheme.outlineVariant,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                  child: Text(
                                                    'Ended',
                                                    style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                            if (unreadCount > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: scheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                                child: Text(
                                                  '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
