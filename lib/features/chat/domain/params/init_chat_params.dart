class InitChatParams {
  InitChatParams({required this.onProgress});

  /// Model download progress, 0 to 100.
  final void Function(int percent) onProgress;
}
