import 'package:equatable/equatable.dart';

import '../../domain/entities/notification.dart';

class NotificationState extends Equatable {
  final List<Notification> notifications;
  final bool loading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.loading = false,
    this.error,
  });

  NotificationState copyWith({
    List<Notification>? notifications,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
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
