import 'package:material_ui/material_ui.dart';

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
