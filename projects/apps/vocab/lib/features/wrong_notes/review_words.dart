import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cell.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_repository.dart';

/// 오답 노트 화면의 한 줄: 노트 + 단어 내용.
typedef WrongEntry = ({WrongNote note, Word word});

/// 칸의 오답 노트에 단어 내용을 붙인다. 최근에 틀린 것이 위(칸 홈의 오답 수·오답 노트 화면).
/// 단어 파일에 없는 id(단어를 고치거나 뺀 경우)는 보이지 않는다.
final wrongEntriesProvider = FutureProvider.autoDispose
    .family<List<WrongEntry>, Cell>((ref, cell) async {
      final notes = await ref.watch(wrongNotesProvider(cell.level).future);
      final words = {
        for (final w in await ref.watch(cellWordsProvider(cell).future))
          w.id: w,
      };
      return [
        for (final n in notes)
          if (n.cell == cell)
            if (words[n.wordId] case final word?) (note: n, word: word),
      ];
    });

/// 칸의 단어 중 오답 노트에 있는 것(단어 파일 순서). 오답 다시 보기·오답 시험이 쓴다.
///
/// 오답 노트 화면에서 돌아올 때 노트를 다시 읽으면 이 값도 바뀐다 — 그래서 다시 보기·오답 시험 화면은
/// 처음 받은 목록을 회차 동안 붙잡아 쓴다(목록이 중간에 바뀌어 카드를 건너뛰지 않게).
final reviewWordsProvider = FutureProvider.autoDispose.family<List<Word>, Cell>(
  (ref, cell) async {
    final all = await ref.watch(cellWordsProvider(cell).future);
    final notes = await ref.watch(wrongNotesProvider(cell.level).future);
    final ids = {
      for (final n in notes)
        if (n.cell == cell) n.wordId,
    };
    return [
      for (final w in all)
        if (ids.contains(w.id)) w,
    ];
  },
);
