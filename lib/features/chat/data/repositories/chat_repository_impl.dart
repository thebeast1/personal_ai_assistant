import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/error_handler.dart';
import '../../../../core/network/error/failure.dart';
import '../../domain/entities/chat_event.dart';
import '../../domain/params/init_chat_params.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_sources/chat_data_source.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required this.chatDataSource});

  final ChatDataSource chatDataSource;

  @override
  Future<Either<Failure, Unit>> init({required InitChatParams params}) async {
    try {
      await chatDataSource.init(onProgress: params.onProgress);
      return const Right(unit);
    } catch (e) {
      log('ChatRepository.init: $e');
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Stream<ChatEvent> send({required Message message}) =>
      chatDataSource.send(message: message);

  @override
  Future<Either<Failure, Unit>> clear() async {
    try {
      await chatDataSource.reset();
      return const Right(unit);
    } catch (e) {
      log('ChatRepository.clear: $e');
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
