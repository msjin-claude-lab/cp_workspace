import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/word_repository.dart';

/// 정해 둔 문자열을 돌려주는 가짜 에셋 묶음.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, String> files;
  final List<String> requested = [];

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    requested.add(key);
    final text = files[key];
    if (text == null) throw StateError('no asset $key');
    return text;
  }
}

void main() {
  test('칸은 12개이고 id·파일 경로·이름이 학교급×난이도로 정해진다', () {
    expect(Cell.values, hasLength(12));
    expect(Cell.middleHard.id, 'middle_hard');
    expect(Cell.middleHard.assetPath, 'assets/words/middle_hard.json');
    expect(Cell.middleHard.label, '중등 [난이도 : 어려움]');
    expect(Cell.of(SchoolLevel.high, Difficulty.easy), Cell.highEasy);
    expect(Cell.values.map((c) => c.id).toSet(), hasLength(12));
    expect(Cell.advancedEasy.id, 'advanced_easy');
    expect(Cell.advancedHard.label, '심화 [난이도 : 어려움]');
  });

  test('칸의 JSON 파일에서 단어를 읽는다', () async {
    final bundle = _FakeBundle({
      'assets/words/elementary_easy.json': '''
[
  {"id": "ee-001", "word": "apple", "meaning": "사과", "example": "I eat an apple.", "exampleMeaning": "나는 사과를 먹는다."},
  {"id": "ee-002", "word": "book", "meaning": "책", "example": "This is my book.", "exampleMeaning": "이것은 내 책이다."}
]''',
    });

    final words = await WordRepository(bundle).wordsOf(Cell.elementaryEasy);

    expect(bundle.requested, ['assets/words/elementary_easy.json']);
    expect(words.map((w) => w.word), ['apple', 'book']);
    expect(words.first.id, 'ee-001');
    expect(words.first.meaning, '사과');
    expect(words.first.example, 'I eat an apple.');
    expect(words.first.exampleMeaning, '나는 사과를 먹는다.');
  });

  test('필드가 빠진 단어는 읽기에 실패한다', () async {
    final bundle = _FakeBundle({
      'assets/words/high_hard.json': '[{"id": "hh-001", "word": "x"}]',
    });

    expect(
      WordRepository(bundle).wordsOf(Cell.highHard),
      throwsA(isA<TypeError>()),
    );
  });
}
