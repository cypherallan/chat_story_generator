import 'package:equatable/equatable.dart';
import '../../../notification_management/domain/entities/simulated_notification.dart';
import '../../../message_management/domain/entities/message.dart';

enum ReplayScreen {
  home,
  conversation,
}

enum ReplayNotificationInteraction {
  none,
  tapped,
  swiped,
  expired,
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

  // Swipe + reply preview
  final String? swipingMessageId;
  final double swipeOffset;
  final String? replyPreviewText;
  final String? replyPreviewSenderName;

  // NEW – selection driven by cubit (for visual long-press + delete)
  final Set<String> selectedMessageIds;
  final bool deleteIconPressed; // true while the delete icon is being “tapped”
  final bool showDeleteConfirmation;
  final bool deleteDialogVisible;
  final bool deleteCancelPressed;
  final bool deleteForMePressed;
  final String? deletingMessageId;

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
      ];
}
