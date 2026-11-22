import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cell.dart';
import 'word.dart';

/// 내장 단어를 `assets/words/<칸>.json`에서 읽는다. 바뀌는 기록(학습·오답·단어장)은 sqflite에 둔다.
class WordRepository {
  WordRepository(this._bundle);

  final AssetBundle _bundle;

  Future<List<Word>> wordsOf(Cell cell) async {
    final text = await _bundle.loadString(cell.assetPath);
    final list = jsonDecode(text) as List<dynamic>;
    return list
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

final wordRepositoryProvider =
    Provider<WordRepository>((ref) => WordRepository(rootBundle));

final cellWordsProvider = FutureProvider.family<List<Word>, Cell>(
  (ref, cell) => ref.watch(wordRepositoryProvider).wordsOf(cell),
);

/// 칸·이름 있는 단어장의 단어. 카드 학습·시험·오답 노트 화면은 이것으로 읽는다.
/// 칸과 이름 있는 단어장(바탕 칸의 파일) 모두 단어 파일 순서.
final deckWordsProvider = FutureProvider.autoDispose.family<List<Word>, Deck>(
  (ref, deck) => switch (deck) {
    Cell() => ref.watch(cellWordsProvider(deck).future),
    StudyDeck() => ref.watch(cellWordsProvider(deck.base).future),
  },
);
