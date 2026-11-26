import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../repositories/chat_repository.dart';

@injectable
class ClearChatUseCase extends UseCase<Unit, NoParams> {
  ClearChatUseCase({required this.chatRepository});

  final ChatRepository chatRepository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async =>
      await chatRepository.clear();
}
