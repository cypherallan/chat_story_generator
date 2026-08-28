import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/profile_avatar.dart';
import '../cubit/simulated_notification_cubit.dart';
import '../cubit/simulated_notification_state.dart';
import '../../domain/entities/simulated_notification.dart';

class SimulatedNotificationBanner extends StatefulWidget {
  final void Function(SimulatedNotification notification) onTap;

  const SimulatedNotificationBanner({
    super.key,
    required this.onTap,
  });

  @override
  State<SimulatedNotificationBanner> createState() =>
      _SimulatedNotificationBannerState();
}

class _SimulatedNotificationBannerState
    extends State<SimulatedNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
      value: 0.0,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // IMPORTANT:
    // The notification may already be visible before this widget
    // is created (for example, when entering Replay).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = context.read<SimulatedNotificationCubit>().state;

      if (state.visible && state.notification != null) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showBanner() {
    if (!mounted) return;

    _animationController.forward();
  }

  void _hideBanner() {
    if (!mounted) return;

    _animationController.reverse();
  }

  void _dismiss() {
    context.read<SimulatedNotificationCubit>().recordSwipe();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SimulatedNotificationCubit, SimulatedNotificationState>(
      listenWhen: (previous, current) =>
          previous.visible != current.visible ||
          previous.notification?.id != current.notification?.id,
      listener: (context, state) {
        if (state.visible && state.notification != null) {
          _showBanner();
        } else {
          _hideBanner();
        }
      },
      child:
          BlocBuilder<SimulatedNotificationCubit, SimulatedNotificationState>(
        builder: (context, state) {
          final notification = state.notification;

          if (notification == null || !state.visible) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Dismissible(
                    key: ValueKey(notification.id),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) {
                      _dismiss();
                    },
                    child: GestureDetector(
                      onTap: () {
                        context.read<SimulatedNotificationCubit>().recordTap();

                        widget.onTap(notification);
                      },
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfileAvatar(
                                imagePath: notification.isGroup
                                    ? notification.groupAvatarPath ??
                                        notification.senderAvatarPath
                                    : notification.senderAvatarPath,
                                name: notification.isGroup
                                    ? notification.groupName!
                                    : notification.senderName,
                                radius: 25,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification.isGroup
                                                ? notification.groupName!
                                                : notification.senderName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('now',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        if (notification.imagePath != null) ...[
                                          Icon(Icons.image_outlined,
                                              size: 16,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            notification.isGroup
                                                ? '${notification.senderName}: ${notification.messageText.isEmpty ? 'Photo' : notification.messageText}'
                                                : notification
                                                        .messageText.isEmpty
                                                    ? 'Photo'
                                                    : notification.messageText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
