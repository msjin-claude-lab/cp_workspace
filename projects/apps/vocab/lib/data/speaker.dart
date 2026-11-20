import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 영단어를 소리 내어 읽는다(TTS). 시험에서는 가짜로 바꾼다.
/// 소리를 못 내도(엔진 없음 등) 예외를 밖으로 내지 않는다 — 학습은 계속된다.
abstract interface class Speaker {
  Future<void> speak(String text);
}

/// 기기의 TTS 엔진(flutter_tts)으로 미국 영어 발음을 낸다.
class TtsSpeaker implements Speaker {
  final FlutterTts _tts = FlutterTts();

  /// 언어 설정은 처음 한 번만. 연달아 불려도 같은 Future를 기다린다.
  Future<void>? _init;

  @override
  Future<void> speak(String text) async {
    try {
      await (_init ??= _tts.setLanguage('en-US'));
      await _tts.stop(); // 앞 단어를 읽는 중이면 끊고 새 단어를 읽는다
      await _tts.speak(text);
    } catch (e) {
      _init = null; // 다음에 다시 설정을 시도한다
      debugPrint('TTS 실패: $e');
    }
  }
}

final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());
