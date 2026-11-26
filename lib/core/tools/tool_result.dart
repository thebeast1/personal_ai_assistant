/// What a tool hands back after it runs. [toModelResponse] is the map
/// Gemma reads as the tool's answer.
sealed class ToolResult {
  const ToolResult();

  Map<String, dynamic> toModelResponse();
}

final class ToolSuccess extends ToolResult {
  const ToolSuccess(this.data);

  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toModelResponse() => data;
}

/// [code] is a short snake_case reason the model can act on, for example
/// `city_not_found` or `no_internet`.
final class ToolFailure extends ToolResult {
  const ToolFailure({required this.code, required this.message});

  final String code;
  final String message;

  @override
  Map<String, dynamic> toModelResponse() => {'error': code, 'message': message};
}
