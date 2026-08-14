import 'package:equatable/equatable.dart';

import '../../domain/entities/replay_notification.dart';

class ReplayNotificationState extends Equatable {
  final List<ReplayNotification> notifications;
  final bool loading;
  final String? error;

  const ReplayNotificationState({
    this.notifications = const [],
    this.loading = false,
    this.error,
  });

  ReplayNotificationState copyWith({
    List<ReplayNotification>? notifications,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ReplayNotificationState(
      notifications: notifications ?? this.notifications,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        loading,
        error,
      ];
}
