import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/utils/wav_info.dart';

/// 16 kHz mono 16-bit WAV, like `record` writes: a tone that gets louder.
Uint8List _wav(Duration length) {
  const rate = 16000;
  final frames = rate * length.inMilliseconds ~/ 1000;
  final data = ByteData(frames * 2);
  for (var i = 0; i < frames; i++) {
    final amp = 30000 * i / frames;
    data.setInt16(i * 2, (amp * math.sin(i / 8)).round(), Endian.little);
  }
  final header = ByteData(44);
  void tag(int o, String s) {
    for (var i = 0; i < 4; i++) {
      header.setUint8(o + i, s.codeUnitAt(i));
    }
  }
  tag(0, 'RIFF');
  header.setUint32(4, 36 + frames * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, rate, Endian.little);
  header.setUint32(28, rate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  tag(36, 'data');
  header.setUint32(40, frames * 2, Endian.little);
  return Uint8List.fromList([
    ...header.buffer.asUint8List(),
    ...data.buffer.asUint8List(),
  ]);
}

void main() {
  test('reads the length of a 16 kHz mono WAV', () {
    final info = WavInfo.parse(_wav(const Duration(seconds: 3)));
    expect(info, isNotNull);
    expect(info!.duration, const Duration(seconds: 3));
  });

  test('waveform follows loudness and is normalised', () {
    final bars = WavInfo.parse(_wav(const Duration(seconds: 3)))!.waveform(28);
    expect(bars, hasLength(28));
    expect(bars.last, closeTo(1.0, 0.05));
    expect(bars.first, lessThan(bars.last));
    expect(bars.every((b) => b >= 0.1 && b <= 1.0), isTrue);
  });

  test('returns null for data that is not a WAV', () {
    expect(WavInfo.parse(null), isNull);
    expect(WavInfo.parse(Uint8List(100)), isNull);
  });
}
