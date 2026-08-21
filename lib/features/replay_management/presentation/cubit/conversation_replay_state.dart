import 'package:equatable/equatable.dart';
import '../../../notification_management/domain/entities/simulated_notification.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart'; // ← add this

enum ReplayScreen {
  home,
  conversation,
}

enum ReplayStartMethod {
  time,
  message,
}

enum ReplayNotificationInteraction {
  none,
  tapped,
  swiped,
  expired,
}

enum ReplayVisualInteraction {
  none,
  notificationTap,
  notificationSwipe,
  backTap,
}

class ReplayNotificationEvent {
  final SimulatedNotification notification;
  final int triggerIndex;
  final NotificationInteraction interaction;

  const ReplayNotificationEvent({
    required this.notification,
    required this.triggerIndex,
    required this.interaction,
  });
}

class ConversationReplayState extends Equatable {
  final List<Message> visibleMessages;
  final bool playing;
  final bool paused;
  final bool finished;
  final int currentIndex;
  final bool typing;
  final String? typingPersonId;
  final String? onlinePersonId;
  final String composerText;
  final String? pressedKey;
  final bool keyboardVisible;
  final bool shiftEnabled;
  final bool shiftPressed;
  final bool emojiKeyboardVisible;
  final String? pressedEmoji;
  final List<String> availableEmojis;
  final String? lastPressedEmoji;
  final int emojiPressCount;
  final ReplayScreen screen;
  final String? currentProjectId;
  final SimulatedNotification? replayNotification;
  final ReplayNotificationInteraction replayNotificationInteraction;
  final int? replayNotificationMessageCount;
  final DateTime? replayStartTime;
  final DateTime? replayEndTime;
  final DateTime? availableStartTime;
  final DateTime? availableEndTime;
  final ReplayStartMethod replayStartMethod;
  final String? replayStartMessageId;
  final String? swipingMessageId;
  final double swipeOffset;
  final String? replyPreviewText;
  final String? replyPreviewSenderName;
  final Set<String> selectedMessageIds;
  final bool deleteIconPressed;
  final bool showDeleteConfirmation;
  final bool deleteDialogVisible;
  final bool deleteCancelPressed;
  final bool deleteForMePressed;
  final String? deletingMessageId;
  final ReplayVisualInteraction visualInteraction;

  const ConversationReplayState({
    this.visibleMessages = const [],
    this.playing = false,
    this.paused = false,
    this.finished = false,
    this.currentIndex = 0,
    this.typing = false,
    this.typingPersonId,
    this.onlinePersonId,
    this.composerText = '',
    this.pressedKey,
    this.keyboardVisible = false,
    this.shiftEnabled = true,
    this.shiftPressed = false,
    this.emojiKeyboardVisible = false,
    this.pressedEmoji,
    this.availableEmojis = const [],
    this.lastPressedEmoji,
    this.emojiPressCount = 0,
    this.screen = ReplayScreen.home,
    this.currentProjectId,
    this.replayNotification,
    this.replayNotificationInteraction = ReplayNotificationInteraction.none,
    this.replayNotificationMessageCount,
    this.replayStartTime,
    this.replayEndTime,
    this.availableStartTime,
    this.availableEndTime,
    this.replayStartMethod = ReplayStartMethod.time,
    this.replayStartMessageId,
    this.swipingMessageId,
    this.swipeOffset = 0,
    this.replyPreviewText,
    this.replyPreviewSenderName,
    this.selectedMessageIds = const {},
    this.deleteIconPressed = false,
    this.showDeleteConfirmation = false,
    this.deleteDialogVisible = false,
    this.deleteCancelPressed = false,
    this.deleteForMePressed = false,
    this.deletingMessageId,
    this.visualInteraction = ReplayVisualInteraction.none,
  });

  ConversationReplayState copyWith({
    List<Message>? visibleMessages,
    bool? playing,
    bool? paused,
    bool? finished,
    int? currentIndex,
    bool? typing,
    String? typingPersonId,
    String? onlinePersonId,
    String? composerText,
    String? pressedKey,
    bool? keyboardVisible,
    bool? shiftEnabled,
    bool? shiftPressed,
    bool? emojiKeyboardVisible,
    String? pressedEmoji,
    List<String>? availableEmojis,
    String? lastPressedEmoji,
    int? emojiPressCount,
    ReplayScreen? screen,
    String? currentProjectId,
    SimulatedNotification? replayNotification,
    ReplayNotificationInteraction? replayNotificationInteraction,
    int? replayNotificationMessageCount,
    DateTime? replayStartTime,
    DateTime? replayEndTime,
    DateTime? availableStartTime,
    DateTime? availableEndTime,
    ReplayStartMethod? replayStartMethod,
    String? replayStartMessageId,
    String? swipingMessageId,
    double? swipeOffset,
    String? replyPreviewText,
    String? replyPreviewSenderName,
    Set<String>? selectedMessageIds,
    bool? deleteIconPressed,
    bool? showDeleteConfirmation,
    bool clearSwipe = false,
    bool clearReplyPreview = false,
    bool clearSelection = false,
    bool clearReplayNotification = false,
    bool? deleteDialogVisible,
    bool? deleteCancelPressed,
    bool? deleteForMePressed,
    String? deletingMessageId,
    ReplayVisualInteraction? visualInteraction,
  }) {
    return ConversationReplayState(
      visibleMessages: visibleMessages ?? this.visibleMessages,
      playing: playing ?? this.playing,
      paused: paused ?? this.paused,
      finished: finished ?? this.finished,
      currentIndex: currentIndex ?? this.currentIndex,
      typing: typing ?? this.typing,
      typingPersonId: typingPersonId ?? this.typingPersonId,
      onlinePersonId: onlinePersonId ?? this.onlinePersonId,
      composerText: composerText ?? this.composerText,
      pressedKey: pressedKey ?? this.pressedKey,
      keyboardVisible: keyboardVisible ?? this.keyboardVisible,
      shiftEnabled: shiftEnabled ?? this.shiftEnabled,
      shiftPressed: shiftPressed ?? this.shiftPressed,
      emojiKeyboardVisible: emojiKeyboardVisible ?? this.emojiKeyboardVisible,
      pressedEmoji: pressedEmoji ?? this.pressedEmoji,
      deleteDialogVisible: deleteDialogVisible ?? this.deleteDialogVisible,
      deleteCancelPressed: deleteCancelPressed ?? this.deleteCancelPressed,
      deleteForMePressed: deleteForMePressed ?? this.deleteForMePressed,
      replayNotification: clearReplayNotification
          ? null
          : (replayNotification ?? this.replayNotification),
      replayNotificationInteraction:
          replayNotificationInteraction ?? this.replayNotificationInteraction,
      replayNotificationMessageCount:
          replayNotificationMessageCount ?? this.replayNotificationMessageCount,
      replayStartTime: replayStartTime ?? this.replayStartTime,
      replayEndTime: replayEndTime ?? this.replayEndTime,
      availableStartTime: availableStartTime ?? this.availableStartTime,
      availableEndTime: availableEndTime ?? this.availableEndTime,
      replayStartMethod: replayStartMethod ?? this.replayStartMethod,
      replayStartMessageId: replayStartMessageId ?? this.replayStartMessageId,
      deletingMessageId: deletingMessageId ?? this.deletingMessageId,
      availableEmojis: availableEmojis ?? this.availableEmojis,
      lastPressedEmoji: lastPressedEmoji ?? this.lastPressedEmoji,
      emojiPressCount: emojiPressCount ?? this.emojiPressCount,
      screen: screen ?? this.screen,
      currentProjectId: currentProjectId ?? this.currentProjectId,
      swipingMessageId:
          clearSwipe ? null : (swipingMessageId ?? this.swipingMessageId),
      swipeOffset: clearSwipe ? 0 : (swipeOffset ?? this.swipeOffset),
      replyPreviewText: clearReplyPreview
          ? null
          : (replyPreviewText ?? this.replyPreviewText),
      replyPreviewSenderName: clearReplyPreview
          ? null
          : (replyPreviewSenderName ?? this.replyPreviewSenderName),
      selectedMessageIds:
          clearSelection ? {} : (selectedMessageIds ?? this.selectedMessageIds),
      deleteIconPressed: deleteIconPressed ?? this.deleteIconPressed,
      showDeleteConfirmation:
          showDeleteConfirmation ?? this.showDeleteConfirmation,
      visualInteraction: visualInteraction ?? this.visualInteraction,
    );
  }

  @override
  List<Object?> get props => [
        visibleMessages,
        playing,
        paused,
        finished,
        currentIndex,
        typing,
        typingPersonId,
        onlinePersonId,
        composerText,
        pressedKey,
        keyboardVisible,
        shiftEnabled,
        shiftPressed,
        emojiKeyboardVisible,
        pressedEmoji,
        availableEmojis,
        lastPressedEmoji,
        emojiPressCount,
        screen,
        currentProjectId,
        replayNotification,
        replayNotificationInteraction,
        replayNotificationMessageCount,
        replayStartTime,
        replayEndTime,
        availableStartTime,
        availableEndTime,
        replayStartMethod,
        replayStartMessageId,
        swipingMessageId,
        swipeOffset,
        replyPreviewText,
        replyPreviewSenderName,
        selectedMessageIds,
        deleteIconPressed,
        showDeleteConfirmation,
        deleteDialogVisible,
        deleteCancelPressed,
        deleteForMePressed,
        deletingMessageId,
        visualInteraction,
      ];
}
