/// The phone's local time, with the time zone it's in.
class CurrentTime {
  const CurrentTime({
    required this.local,
    required this.timeZoneName,
    required this.utcOffset,
  });

  final DateTime local;

  /// Short zone name from the phone, for example `EET`.
  final String timeZoneName;

  final Duration utcOffset;
}
