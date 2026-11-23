import 'dart:math' as math;
import 'dart:typed_data';

/// Length and a coarse waveform of a PCM WAV clip (what `record` writes with
/// `AudioEncoder.wav`). Returns null for anything that isn't a readable WAV.
class WavInfo {
  const WavInfo._(this.duration, this._bytes, this._dataOffset, this._dataSize,
      this._bitsPerSample, this._blockAlign);

  final Duration duration;
  final Uint8List _bytes;
  final int _dataOffset;
  final int _dataSize;
  final int _bitsPerSample;
  final int _blockAlign;

  static WavInfo? parse(Uint8List? bytes) {
    if (bytes == null || bytes.length < 44) return null;
    final view = ByteData.sublistView(bytes);
    String tag(int offset) => String.fromCharCodes(bytes, offset, offset + 4);
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') return null;

    int? byteRate, bitsPerSample, blockAlign, dataOffset, dataSize;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = tag(offset);
      final size = view.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ' && body + 16 <= bytes.length) {
        byteRate = view.getUint32(body + 8, Endian.little);
        blockAlign = view.getUint16(body + 12, Endian.little);
        bitsPerSample = view.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataOffset = body;
        // A recorder that was stopped abruptly may leave the size unset.
        dataSize = math.min(size, bytes.length - body);
        break;
      }
      offset = body + size + (size.isOdd ? 1 : 0);
    }
    if (byteRate == null || byteRate == 0 || dataOffset == null) return null;

    final ms = dataSize! * 1000 ~/ byteRate;
    return WavInfo._(Duration(milliseconds: ms), bytes, dataOffset, dataSize,
        bitsPerSample ?? 16, math.max(blockAlign ?? 2, 1));
  }

  /// [bars] loudness values between 0 and 1 (16-bit PCM only; flat otherwise).
  /// Samples sparsely, so it stays cheap for a full 60 s clip.
  List<double> waveform(int bars) {
    final frames = _dataSize ~/ _blockAlign;
    if (_bitsPerSample != 16 || frames == 0) return List.filled(bars, 0.3);

    final view = ByteData.sublistView(_bytes);
    final perBar = math.max(frames ~/ bars, 1);
    final step = math.max(perBar ~/ 200, 1); // at most ~200 reads per bar
    final peaks = <double>[];
    for (var b = 0; b < bars; b++) {
      var peak = 0;
      for (var f = b * perBar; f < (b + 1) * perBar && f < frames; f += step) {
        final sample = view
            .getInt16(_dataOffset + f * _blockAlign, Endian.little)
            .abs();
        if (sample > peak) peak = sample;
      }
      peaks.add(peak / 32768);
    }
    // Normalise so quiet recordings still show a visible shape.
    final loudest = peaks.fold<double>(0, math.max);
    if (loudest == 0) return List.filled(bars, 0.1);
    return [for (final p in peaks) (p / loudest).clamp(0.1, 1.0)];
  }
}
