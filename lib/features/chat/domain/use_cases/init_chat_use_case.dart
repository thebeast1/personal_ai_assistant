import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../params/init_chat_params.dart';
import '../repositories/chat_repository.dart';

@injectable
class InitChatUseCase extends UseCase<Unit, InitChatParams> {
  InitChatUseCase({required this.chatRepository});

  final ChatRepository chatRepository;

  @override
  Future<Either<Failure, Unit>> call(InitChatParams params) async =>
      await chatRepository.init(params: params);
}
