import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_settings.dart';
import '../../data/cell.dart';
import '../../data/counts.dart';

/// 설정: 그 단어장의 카드 학습 단어 수와 시험 문항 수(2026-11-22 사용자 결정 — 단어장마다 따로).
/// 고르는 즉시 저장한다(저장 버튼 없음). 진행 중인 회차에는 영향이 없고 다음 회차부터 쓴다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.deck});

  final StudyDeck deck;

  Future<void> _change(
    BuildContext context,
    Future<bool> Function() set,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await set();
    if (saved) return;
    // 값은 이번 실행에서 그대로 쓴다. 다시 켜면 이전 값으로 돌아간다는 것을 알린다
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('설정을 저장하지 못했습니다. 이번에만 적용됩니다')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(deckSettingsProvider(deck));
    final notifier = ref.read(deckSettingsProvider(deck).notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${deck.label} - 설정',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: switch (settings) {
          AsyncData(value: final s) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _CountSetting(
                keyPrefix: 'settings-card',
                title: '카드 학습 단어 수',
                caption: '한 번에 볼 카드 수',
                value: s.cardCount,
                onChanged: (n) =>
                    _change(context, () => notifier.setCardCount(n)),
              ),
              const SizedBox(height: 32),
              _CountSetting(
                keyPrefix: 'settings-quiz',
                title: '시험 문항 수',
                caption: '한 번에 풀 문제 수',
                value: s.quizCount,
                onChanged: (n) =>
                    _change(context, () => notifier.setQuizCount(n)),
              ),
              const SizedBox(height: 32),
              Text(
                '이 단어장에만 적용됩니다. 단어가 더 적으면 있는 단어를 모두 씁니다',
                key: const ValueKey('settings-note'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// 제목 + 설명 + 10/20/30/50 중 하나 또는 직접 입력을 고르는 줄. 버튼 키는 `<keyPrefix>-<수>`, 직접 입력은 `<keyPrefix>-custom`.
class _CountSetting extends StatelessWidget {
  const _CountSetting({
    required this.keyPrefix,
    required this.title,
    required this.caption,
    required this.value,
    required this.onChanged,
  });

  final String keyPrefix;
  final String title;
  final String caption;
  final int value;
  final ValueChanged<int> onChanged;

  bool get custom => !countChoices.contains(value);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleMedium),
        const SizedBox(height: 2),
        Text(caption, style: text.bodySmall),
        const SizedBox(height: 12),
        // 직접 입력한 값이면 어느 조각도 선택되지 않는다(아래 "직접 입력"이 선택됨)
        SegmentedButton<int>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final n in countChoices)
              ButtonSegment(
                value: n,
                label: Text('$n', key: ValueKey('$keyPrefix-$n')),
              ),
          ],
          selected: custom ? <int>{} : {value},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onChanged(s.first);
          },
        ),
        const SizedBox(height: 8),
        // 조각 다섯 개는 폭 360dp 폰에서 글자가 잘리므로 직접 입력은 따로 한 줄에 둔다
        ChoiceChip(
          key: ValueKey('$keyPrefix-custom'),
          label: Text(custom ? '직접 입력 ($value)' : '직접 입력'),
          selected: custom,
          onSelected: (_) async {
            final n = await showDialog<int>(
              context: context,
              builder: (_) => _CustomCountDialog(
                keyPrefix: keyPrefix,
                title: title,
                initial: value,
              ),
            );
            if (n != null) onChanged(n);
          },
        ),
      ],
    );
  }
}

/// 직접 입력 창(2026-11-22 사용자 결정). 1~999가 아니면 창을 닫지 않고 그 자리에 안내한다.
class _CustomCountDialog extends StatefulWidget {
  const _CustomCountDialog({
    required this.keyPrefix,
    required this.title,
    required this.initial,
  });

  final String keyPrefix;
  final String title;
  final int initial;

  @override
  State<_CustomCountDialog> createState() => _CustomCountDialogState();
}

class _CustomCountDialogState extends State<_CustomCountDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initial}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final n = int.tryParse(_controller.text.trim());
    if (!isValidCount(n)) {
      setState(() => _error = '$minCount에서 $maxCount 사이의 숫자를 입력하세요');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: ValueKey('${widget.keyPrefix}-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          key: ValueKey('${widget.keyPrefix}-save'),
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
