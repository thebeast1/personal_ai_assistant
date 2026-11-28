import 'package:dartz/dartz.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/chat/domain/entities/chat_entry.dart';
import 'package:personal_ai_assistant/features/chat/domain/entities/chat_event.dart';
import 'package:personal_ai_assistant/features/chat/domain/params/init_chat_params.dart';
import 'package:personal_ai_assistant/features/chat/domain/use_cases/clear_chat_use_case.dart';
import 'package:personal_ai_assistant/features/chat/domain/use_cases/init_chat_use_case.dart';
import 'package:personal_ai_assistant/features/chat/domain/use_cases/send_message_use_case.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';

class _MockInitChat extends Mock implements InitChatUseCase {}

class _MockSendMessage extends Mock implements SendMessageUseCase {}

class _MockClearChat extends Mock implements ClearChatUseCase {}

void main() {
  late _MockInitChat initChat;
  late _MockSendMessage sendMessage;
  late _MockClearChat clearChat;
  late ChatProvider provider;
  final userMessage = Message.text(text: 'Hello', isUser: true);

  setUpAll(() {
    registerFallbackValue(Message.text(text: '', isUser: true));
    registerFallbackValue(const NoParams());
    registerFallbackValue(InitChatParams(onProgress: (_) {}));
  });

  setUp(() {
    initChat = _MockInitChat();
    sendMessage = _MockSendMessage();
    clearChat = _MockClearChat();
    provider = ChatProvider(
      initChatUseCase: initChat,
      sendMessageUseCase: sendMessage,
      clearChatUseCase: clearChat,
    );
  });

  void replyWith(Stream<ChatEvent> events) =>
      when(() => sendMessage(any())).thenAnswer((_) => events);

  test('init finishes initializing on success', () async {
    when(() => initChat(any())).thenAnswer((_) async => const Right(unit));
    await provider.init();
    expect(provider.isInitializing, isFalse);
  });

  test('streamed text becomes one assistant message', () async {
    replyWith(Stream.fromIterable([TextChunk('Hi'), TextChunk('!')]));

    await provider.send(userMessage);

    expect(provider.chatList, hasLength(2));
    expect((provider.chatList[0] as MessageEntry).message, userMessage);
    final reply = (provider.chatList[1] as MessageEntry).message;
    expect(reply.text, 'Hi!');
    expect(reply.isUser, isFalse);
    expect(provider.isGeneratingRespond, isFalse);
    expect(provider.draftMessage.isEmpty, isTrue);
  });

  test('a successful tool adds its card before the reply', () async {
    replyWith(
      Stream.fromIterable([
        ToolExecuted('get_weather', const ToolSuccess({'city': 'Cairo'})),
        TextChunk('Sunny'),
      ]),
    );

    await provider.send(userMessage);

    expect(provider.chatList, hasLength(3));
    final card = provider.chatList[1] as ToolResultEntry;
    expect(card.toolName, 'get_weather');
    expect(card.data, {'city': 'Cairo'});
    expect((provider.chatList[2] as MessageEntry).message.text, 'Sunny');
  });

  test('a failed tool adds no card', () async {
    replyWith(
      Stream.fromIterable([
        ToolExecuted(
          'get_weather',
          const ToolFailure(code: 'no_internet', message: 'offline'),
        ),
        TextChunk('No internet'),
      ]),
    );

    await provider.send(userMessage);

    expect(provider.chatList.whereType<ToolResultEntry>(), isEmpty);
  });

  test('an error mid-reply keeps the partial text and stops generating',
      () async {
    replyWith(
      Stream.fromIterable([TextChunk('Par')]).followedBy(
        Stream.error(StateError('boom')),
      ),
    );

    await provider.send(userMessage);

    expect((provider.chatList.last as MessageEntry).message.text, 'Par');
    expect(provider.isGeneratingRespond, isFalse);
  });

  test('clear empties the list', () async {
    replyWith(Stream.fromIterable([TextChunk('Hi')]));
    when(() => clearChat(any())).thenAnswer((_) async => const Right(unit));
    await provider.send(userMessage);

    await provider.clear();

    verify(() => clearChat(any())).called(1);
    expect(provider.chatList, isEmpty);
  });
}

extension<T> on Stream<T> {
  Stream<T> followedBy(Stream<T> next) async* {
    yield* this;
    yield* next;
  }
}
