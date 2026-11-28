import 'package:dartz/dartz.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../../../../core/network/error/failure.dart';
import '../entities/chat_event.dart';
import '../params/init_chat_params.dart';

abstract class ChatRepository {
  Future<Either<Failure, Unit>> init({required InitChatParams params});

  /// Errors come through the stream, so the caller can keep the text that
  /// arrived before them.
  Stream<ChatEvent> send({required Message message});

  Future<Either<Failure, Unit>> clear();
}
