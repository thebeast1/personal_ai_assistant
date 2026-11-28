/// What the domain and presentation layers see when something goes wrong.
/// Repositories turn exceptions into one of these through [ErrorHandler].
///
/// Messages are in English on purpose: tools send them to Gemma, which
/// explains the problem to the user in their own language.
abstract class Failure {
  String get message;
}

class ServerFailure extends Failure {
  @override
  String get message => 'The service is not available right now.';
}

class NetworkFailure extends Failure {
  @override
  String get message => 'No internet connection.';
}

class NotFoundFailure extends Failure {
  NotFoundFailure({this.error});

  final String? error;

  @override
  String get message => error ?? 'Nothing was found.';
}

class LocationFailure extends Failure {
  @override
  String get message => 'The location is not available.';
}

class CacheFailure extends Failure {
  @override
  String get message => 'Could not save the setting.';
}
