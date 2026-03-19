import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../wardrobe/data/wardrobe_repository.dart';
import '../data/stylist_repository.dart';
import '../models/stylist_models.dart';

part 'stylist_provider.g.dart';

/// All past stylist sessions for the user.
@riverpod
Future<List<StylistSession>> stylistSessions(Ref ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(stylistRepositoryProvider).getSessions();
}

/// Messages in a given session.
@riverpod
Future<List<StylistMessage>> sessionMessages(
  Ref ref,
  String sessionId,
) async {
  return ref.watch(stylistRepositoryProvider).getMessages(sessionId);
}

/// All saved outfits.
@riverpod
Future<List<SavedOutfit>> savedOutfits(Ref ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(stylistRepositoryProvider).getOutfits();
}

// ────────────────────────────────────────────────────────────
// Active Chat Notifier
// Manages the live conversation state in StylistScreen
// ────────────────────────────────────────────────────────────

sealed class StylistChatState {}

class StylistChatIdle extends StylistChatState {
  final String sessionId;
  final List<StylistMessage> messages;
  StylistChatIdle(this.sessionId, this.messages);
}

class StylistChatSending extends StylistChatState {
  final String sessionId;
  final List<StylistMessage> messages;
  StylistChatSending(this.sessionId, this.messages);
}

class StylistChatError extends StylistChatState {
  final String sessionId;
  final List<StylistMessage> messages;
  final String error;
  StylistChatError(this.sessionId, this.messages, this.error);
}

@riverpod
class StylistChatNotifier extends _$StylistChatNotifier {
  @override
  StylistChatState build() => StylistChatIdle('', []);

  /// Start or resume a session.
  Future<void> initSession({String? existingSessionId, String? initialMessage}) async {
    final repo = ref.read(stylistRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    String sessionId;
    List<StylistMessage> messages;

    if (existingSessionId != null) {
      sessionId = existingSessionId;
      messages = await repo.getMessages(sessionId);
    } else {
      final session = await repo.createSession();
      sessionId = session.id;
      messages = [];
    }

    state = StylistChatIdle(sessionId, messages);

    if (initialMessage != null && initialMessage.isNotEmpty) {
      await sendMessage(initialMessage);
    }
  }

  /// Send a user message and get AI response.
  Future<void> sendMessage(String content) async {
    final currentState = state;
    final String sessionId;
    final List<StylistMessage> currentMessages;

    if (currentState is StylistChatIdle) {
      sessionId = currentState.sessionId;
      currentMessages = currentState.messages;
    } else if (currentState is StylistChatError) {
      sessionId = currentState.sessionId;
      currentMessages = currentState.messages;
    } else {
      return; // already sending
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repo = ref.read(stylistRepositoryProvider);
    final wardrobeRepo = ref.read(wardrobeRepositoryProvider);

    // Optimistically add user message to UI
    final optimisticUserMsg = StylistMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      userId: user.id,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );

    state = StylistChatSending(sessionId, [...currentMessages, optimisticUserMsg]);

    try {
      // Get wardrobe context
      final wardrobeSummary = await wardrobeRepo.getWardrobeSummary(user.id);
      final wardrobeIds = wardrobeSummary.map((w) => w['id'] as String).toList();

      // Save user message to DB
      final userMsg = await repo.addUserMessage(
        sessionId: sessionId,
        userId: user.id,
        content: content,
        wardrobeItemIds: wardrobeIds,
      );

      // Call AI Edge Function
      final response = await supabase.functions.invoke(
        'ai-stylist',
        body: {
          'session_id': sessionId,
          'message': content,
          'wardrobe': wardrobeSummary,
          'history': currentMessages
              .takeLast(6) // last 3 exchanges for context
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        },
      );

      if (response.status != 200) {
        throw Exception('Stilist yanıt vermedi (${response.status})');
      }

      final responseData = response.data as Map<String, dynamic>;
      final displayText = responseData['message'] as String? ?? '';

      // Save assistant message
      final assistantMsg = await repo.addAssistantMessage(
        sessionId: sessionId,
        userId: user.id,
        content: displayText,
        structuredData: responseData,
      );

      // Update session title on first message
      if (currentMessages.isEmpty) {
        final title = content.length > 40
            ? '${content.substring(0, 40)}...'
            : content;
        await repo.updateSessionTitle(sessionId, title);
      }

      // Replace optimistic message with real one, add assistant reply
      final newMessages = [
        ...currentMessages,
        userMsg,
        assistantMsg,
      ];

      state = StylistChatIdle(sessionId, newMessages);
      ref.invalidate(stylistSessionsProvider);
    } catch (e) {
      final messagesWithUser = [...currentMessages, optimisticUserMsg];
      state = StylistChatError(sessionId, messagesWithUser, e.toString());
    }
  }

  /// Save an AI-suggested outfit.
  Future<bool> saveOutfit({
    required OutfitSuggestion suggestion,
    required String userId,
    String? sessionId,
  }) async {
    try {
      await ref.read(stylistRepositoryProvider).saveOutfit(
            userId: userId,
            name: suggestion.name,
            wardrobeItemIds: suggestion.itemIds,
            aiReasoning: suggestion.reasoning,
            occasion: suggestion.occasion,
            sessionId: sessionId,
          );
      ref.invalidate(savedOutfitsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Quick-access helper to get the last N messages from a list.
extension on List<StylistMessage> {
  List<StylistMessage> takeLast(int n) =>
      length <= n ? this : sublist(length - n);
}
