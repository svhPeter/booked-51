import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
  }
  return 'Something went wrong. Please try again.';
}

class ChatMessage {
  final String id;
  final String appointmentId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String senderName;

  ChatMessage({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      appointmentId: json['appointmentId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      senderName: json['senderName'] ?? '',
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _apiClient;
  io.Socket? _socket;
  Timer? _pollTimer;
  String? _appointmentId;

  ChatNotifier(this._apiClient) : super(const ChatState());

  String get _socketBaseUrl {
    final base = ApiConstants.baseUrl;
    return base.replaceAll(RegExp(r'/api/v1/?$'), '');
  }

  Future<void> openChat(String appointmentId, String userId) async {
    _appointmentId = appointmentId;
    await fetchMessages(appointmentId);
    await markRead(appointmentId);
    _connectSocket(appointmentId, userId);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_appointmentId != null) fetchMessages(_appointmentId!, silent: true);
    });
  }

  void _connectSocket(String appointmentId, String userId) {
    _socket?.dispose();
    _socket = io.io(
      _socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) {
      _socket!.emit('join', userId);
      _socket!.emit('join-appointment', {
        'appointmentId': appointmentId,
        'userId': userId,
      });
    });
    _socket!.on('message:new', (data) {
      if (data is Map && data['appointmentId'] == appointmentId) {
        final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        if (!state.messages.any((m) => m.id == msg.id)) {
          state = state.copyWith(messages: [...state.messages, msg]);
        }
      }
    });
  }

  Future<void> fetchMessages(String appointmentId, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get('/appointments/$appointmentId/messages');
      final list = (res.data['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(messages: list, isLoading: false);
    } catch (e) {
      if (!silent) state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> sendMessage(String appointmentId, String content) async {
    try {
      final res = await _apiClient.post(
        '/appointments/$appointmentId/messages',
        data: {'content': content},
      );
      final msg = ChatMessage.fromJson(
        Map<String, dynamic>.from(res.data['message'] ?? res.data),
      );
      if (!state.messages.any((m) => m.id == msg.id)) {
        state = state.copyWith(messages: [...state.messages, msg]);
      }
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
    }
  }

  Future<String?> uploadVoiceBytes(List<int> bytes) async {
    try {
      final res = await _apiClient.post(
        '/uploads/audio',
        data: bytes,
      );
      return res.data['url'] as String?;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return null;
    }
  }

  Future<void> markRead(String appointmentId) async {
    try {
      await _apiClient.put('/appointments/$appointmentId/messages/read');
      state = state.copyWith(unreadCount: 0);
    } catch (_) {}
  }

  Future<int> fetchUnreadCount(String appointmentId) async {
    try {
      final res = await _apiClient.get('/appointments/$appointmentId/messages/unread-count');
      final count = res.data['count'] ?? 0;
      state = state.copyWith(unreadCount: count is int ? count : int.parse('$count'));
      return state.unreadCount;
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  void closeChat() {
    _pollTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _appointmentId = null;
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(apiClientProvider));
});
