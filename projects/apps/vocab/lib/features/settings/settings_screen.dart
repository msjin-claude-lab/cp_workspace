import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_settings.dart';
import '../../data/cell.dart';
import '../../data/counts.dart';
import '../../data/reminder_settings.dart';
import '../../data/word_repository.dart';
import '../reminder/reminder_controller.dart';
import '../reminder/reminder_notifications.dart';

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
    // "전체" 칩에 보일 단어 수 — 읽는 중이거나 실패하면 수 없이 "전체"만
    final wordCount = ref.watch(deckWordsProvider(deck)).value?.length;
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
                allWords: true,
                wordCount: wordCount,
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
              _DailyCountSetting(
                value: s.dailyCount,
                onChanged: (n) => _change(context, () async {
                  final saved = await notifier.setDailyCount(n);
                  // 알림 문구의 개수를 맞춘다
                  await ref
                      .read(reminderControllerProvider.notifier)
                      .reschedule();
                  return saved;
                }),
              ),
              const SizedBox(height: 32),
              Text(
                '이 단어장에만 적용됩니다. 단어가 더 적으면 있는 단어를 모두 씁니다',
                key: const ValueKey('settings-note'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const _ReminderSection(),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// 오늘의 단어 개수: 5·10·15·20 중 하나(2026-11-28 사용자 결정, 기본 10). 바꾸면 다음에 고를 때
/// (다음 날)부터 쓴다 — 오늘 고른 단어는 그대로. 버튼 키는 `settings-daily-<수>`.
class _DailyCountSetting extends StatelessWidget {
  const _DailyCountSetting({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('오늘의 단어 개수', style: text.titleMedium),
        const SizedBox(height: 2),
        Text('하루에 볼 단어 수 — 다음 날부터 적용됩니다', style: text.bodySmall),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final n in dailyCountChoices)
              ButtonSegment(
                value: n,
                label: Text('$n', key: ValueKey('settings-daily-$n')),
              ),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

/// 앱 전체 설정 — 매일 알림 켜기/끄기와 시각(2026-11-28 사용자 결정 — 단어장 설정 화면 안에 따로,
/// 어느 단어장에서 열어도 같은 값). 켤 때 권한이 없으면 다시 묻고, 그래도 없으면 시스템 설정을 안내한다.
class _ReminderSection extends ConsumerWidget {
  const _ReminderSection();

  static String _time(ReminderSettings s) =>
      '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifications = ref.read(reminderNotificationsProvider);
    final ok = await ref
        .read(reminderControllerProvider.notifier)
        .setEnabled(on);
    if (ok) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('reminder-denied'),
          content: const Text('알림이 허용되지 않았습니다. 휴대폰 설정에서 Vocara 알림을 허용해 주세요'),
          action: SnackBarAction(
            label: '설정 열기',
            onPressed: () async {
              try {
                await notifications.openSettings();
              } catch (_) {
                // 설정 화면을 열지 못하면 안내 문구만 남는다
              }
            },
          ),
        ),
      );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings s,
  ) async {
    final controller = ref.read(reminderControllerProvider.notifier);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
    );
    if (picked != null) await controller.setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(reminderControllerProvider).value;
    return Column(
      key: const ValueKey('reminder-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('앱 전체 — 매일 알림', style: text.titleMedium),
        const SizedBox(height: 2),
        Text('지금 고른 단어장의 오늘의 단어를 다 보지 않은 날 알려 줍니다', style: text.bodySmall),
        if (settings case final s?) ...[
          SwitchListTile(
            key: const ValueKey('reminder-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('매일 알림 받기'),
            value: s.enabled,
            onChanged: (on) => _toggle(context, ref, on),
          ),
          ListTile(
            key: const ValueKey('reminder-time'),
            contentPadding: EdgeInsets.zero,
            enabled: s.enabled,
            title: const Text('알림 시각'),
            trailing: Text(_time(s), style: text.titleMedium),
            onTap: () => _pickTime(context, ref, s),
          ),
        ],
      ],
    );
  }
}

/// 제목 + 설명 + 10/20/30/50/100 중 하나, (카드만) 전체, 또는 직접 입력을 고르는 줄.
/// 버튼 키는 `<keyPrefix>-<수>`, 전체는 `<keyPrefix>-all`, 직접 입력은 `<keyPrefix>-custom`.
class _CountSetting extends StatelessWidget {
  const _CountSetting({
    required this.keyPrefix,
    required this.title,
    required this.caption,
    required this.value,
    required this.onChanged,
    this.allWords = false,
    this.wordCount,
  });

  final String keyPrefix;
  final String title;
  final String caption;
  final int value;
  final ValueChanged<int> onChanged;

  /// "전체"(그 단어장의 단어 모두) 칩을 보일까 — 카드 학습만(2026-11-24 사용자 결정).
  final bool allWords;

  /// 전체 칩에 보일 단어 수. 모르면 null.
  final int? wordCount;

  bool get all => value == allCardsCount;
  bool get custom => !countChoices.contains(value) && !all;

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
        // 직접 입력·전체이면 어느 조각도 선택되지 않는다(아래 "직접 입력"이나 "전체"가 선택됨)
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
          selected: custom || all ? <int>{} : {value},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onChanged(s.first);
          },
        ),
        const SizedBox(height: 8),
        // 글자가 긴 전체·직접 입력은 폭 360dp 폰에서 조각에 넣으면 잘리므로 따로 한 줄에 둔다
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allWords)
              ChoiceChip(
                key: ValueKey('$keyPrefix-all'),
                label: Text(wordCount == null ? '전체' : '전체 ($wordCount)'),
                selected: all,
                onSelected: (_) => onChanged(allCardsCount),
              ),
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
                    // 전체에서 직접 입력을 열면 9999 대신 기본값부터 보인다(직접 입력은 1~999)
                    initial: all ? defaultCardCount : value,
                  ),
                );
                if (n != null) onChanged(n);
              },
            ),
          ],
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
