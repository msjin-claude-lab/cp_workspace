import 'package:material_ui/material_ui.dart';

import '../../data/word.dart';

/// 단어 입력 창에서 받은 값(앞뒤 공백을 뗀 것). 예문·해석은 비어 있을 수 있다.
typedef WordInput = ({
  String word,
  String meaning,
  String example,
  String exampleMeaning,
});

/// 단어장 이름 길이 제한(2026-11-22 사용자 결정(UX 점검)). 이미 있는 더 긴 이름은 그대로 보이고,
/// 고칠 때만 이 길이까지 쓴다.
const int bookNameMaxLength = 20;

/// 단어장 이름을 받는다(만들기·이름 바꾸기). 취소하면 null. 앞뒤 공백은 뗀다.
/// `confirmLabel`은 확인 버튼 글자 — 새 단어장 만들기는 이름 다음에 고르는 단계가 이어지므로 `다음`.
Future<String?> showBookNameDialog(
  BuildContext context, {
  String initial = '',
  required String title,
  String confirmLabel = '저장',
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _NameDialog(initial: initial, title: title, confirmLabel: confirmLabel),
);

/// 단어를 받는다(추가·고치기). `initial`이 있으면 그 내용으로 채운다. 취소하면 null.
Future<WordInput?> showWordForm(BuildContext context, {Word? initial}) =>
    showDialog<WordInput>(
      context: context,
      builder: (_) => _WordFormDialog(initial: initial),
    );

/// 지우기 전에 묻는다. 지우기를 누르면 true.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          key: const ValueKey('confirm-delete'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('지우기'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.initial,
    required this.title,
    required this.confirmLabel,
  });

  final String initial;
  final String title;
  final String confirmLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);

  /// 저장을 눌렀나. 빠르게 두 번 누르면 창 뒤의 화면까지 닫히므로 한 번만 닫는다.
  bool _done = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_done || !_form.currentState!.validate()) return;
    _done = true;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const ValueKey('book-name-field'),
          controller: _name,
          autofocus: true,
          // 글자 수 표시가 함께 나온다. 더 긴 옛 이름은 지우며 줄일 수 있다
          maxLength: bookNameMaxLength,
          decoration: const InputDecoration(labelText: '단어장 이름'),
          validator: (v) => (v ?? '').trim().isEmpty ? '이름을 입력하세요' : null,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          key: const ValueKey('book-name-save'),
          onPressed: _save,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _WordFormDialog extends StatefulWidget {
  const _WordFormDialog({this.initial});

  final Word? initial;

  @override
  State<_WordFormDialog> createState() => _WordFormDialogState();
}

class _WordFormDialogState extends State<_WordFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _word = TextEditingController(text: widget.initial?.word);
  late final _meaning = TextEditingController(text: widget.initial?.meaning);
  late final _example = TextEditingController(text: widget.initial?.example);
  late final _exampleMeaning = TextEditingController(
    text: widget.initial?.exampleMeaning,
  );

  /// 저장을 눌렀나. 빠르게 두 번 누르면 창 뒤의 화면까지 닫히므로 한 번만 닫는다.
  bool _done = false;

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _example.dispose();
    _exampleMeaning.dispose();
    super.dispose();
  }

  void _save() {
    if (_done || !_form.currentState!.validate()) return;
    _done = true;
    Navigator.of(context).pop<WordInput>((
      word: _word.text.trim(),
      meaning: _meaning.text.trim(),
      example: _example.text.trim(),
      exampleMeaning: _exampleMeaning.text.trim(),
    ));
  }

  /// 영단어·뜻은 꼭 넣고, 예문·해석은 선택(명세).
  static String? Function(String?) _required(String message) =>
      (v) => (v ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '단어 추가' : '단어 고치기'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('word-field-word'),
                controller: _word,
                autofocus: true,
                decoration: const InputDecoration(labelText: '영단어'),
                validator: _required('영단어를 입력하세요'),
              ),
              TextFormField(
                key: const ValueKey('word-field-meaning'),
                controller: _meaning,
                decoration: const InputDecoration(labelText: '뜻'),
                validator: _required('뜻을 입력하세요'),
              ),
              TextFormField(
                key: const ValueKey('word-field-example'),
                controller: _example,
                decoration: const InputDecoration(labelText: '예문 (선택)'),
              ),
              TextFormField(
                key: const ValueKey('word-field-example-meaning'),
                controller: _exampleMeaning,
                decoration: const InputDecoration(labelText: '예문 해석 (선택)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          key: const ValueKey('word-save'),
          onPressed: _save,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
