import 'package:equatable/equatable.dart';

import '../../domain/entities/simulated_notification.dart';

class SimulatedNotificationState extends Equatable {
  final SimulatedNotification? notification;
  final bool visible;

  const SimulatedNotificationState({
    this.notification,
    this.visible = false,
  });

  SimulatedNotificationState copyWith({
    SimulatedNotification? notification,
    bool? visible,
    bool clearNotification = false,
  }) {
    return SimulatedNotificationState(
      notification:
          clearNotification ? null : (notification ?? this.notification),
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [
        notification,
        visible,
      ];
}
