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

final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => WordRepository(rootBundle),
);

final cellWordsProvider = FutureProvider.family<List<Word>, Cell>(
  (ref, cell) => ref.watch(wordRepositoryProvider).wordsOf(cell),
);

/// 화면에서 숨기는 학교급. 단어가 덜 찬 학교급은 다 채워질 때까지 이 집합에 넣어 고르기 화면에서 숨긴다.
/// 지금은 비어 있다 — 심화는 2026-11-27 다 채워 열었다(docs/plan-words-phase4.md 6단계).
final hiddenLevelsProvider = Provider<Set<SchoolLevel>>(
  (_) => const {},
);

/// 칸·이름 있는 단어장의 단어. 카드 학습·시험·오답 노트 화면은 이것으로 읽는다.
/// 칸과 이름 있는 단어장(바탕 칸의 파일) 모두 단어 파일 순서.
final deckWordsProvider = FutureProvider.autoDispose.family<List<Word>, Deck>(
  (ref, deck) => switch (deck) {
    Cell() => ref.watch(cellWordsProvider(deck).future),
    StudyDeck() => ref.watch(cellWordsProvider(deck.base).future),
  },
);
