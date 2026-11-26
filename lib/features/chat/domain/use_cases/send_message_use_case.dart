import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../entities/chat_event.dart';
import '../repositories/chat_repository.dart';

/// Streams the reply instead of returning an `Either`, so it doesn't extend
/// [UseCase]: the UI needs each token as it arrives.
@injectable
class SendMessageUseCase {
  SendMessageUseCase({required this.chatRepository});

  final ChatRepository chatRepository;

  Stream<ChatEvent> call(Message message) =>
      chatRepository.send(message: message);
}
