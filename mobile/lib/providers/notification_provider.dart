import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../core/network/api_client.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final bool isLoadingMore;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.isLoadingMore = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    bool? isLoadingMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;

  NotificationNotifier(this._apiClient) : super(NotificationState());

  Future<void> fetchNotifications({bool loadMore = false}) async {
    if (loadMore && state.isLoadingMore) return;
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = loadMore ? state.page + 1 : 1;
      final response = await _apiClient.get('/notifications?page=$page&limit=20');
      final data = response.data;
      final list = (data['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        notifications: loadMore ? [...state.notifications, ...list] : list,
        total: data['total'] as int,
        page: page,
        totalPages: data['totalPages'] as int,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      state = state.copyWith(
        unreadCount: response.data['count'] as int,
      );
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.put('/notifications/$id/read');
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              title: n.title,
              body: n.body,
              type: n.type,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.put('/notifications/read-all');
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  data: n.data,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
            .toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return NotificationNotifier(apiClient);
});
