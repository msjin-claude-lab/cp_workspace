import 'package:material_ui/material_ui.dart';

import '../../data/study_records.dart';

/// 날짜별 기록을 월 달력으로 보여 준다(2026-11-22 사용자 결정 — 전에는 날짜 목록).
/// 공부한 날은 색을 칠하고, 날짜를 누르면 아래에 그날의 공부 수·시험 맞힌 수를 보여 준다.
/// ‹ ›로 달을 넘긴다. 처음에는 이번 달, 오늘이 골라져 있다.
class ProgressCalendar extends StatefulWidget {
  const ProgressCalendar({super.key, required this.days, required this.today});

  final List<DayStat> days;

  /// 오늘(기기 날짜). 시험에서 날짜를 고정하려고 밖에서 받는다.
  final DateTime today;

  @override
  State<ProgressCalendar> createState() => _ProgressCalendarState();
}

class _ProgressCalendarState extends State<ProgressCalendar> {
  /// 보고 있는 달의 1일.
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  /// 고른 날.
  late DateTime _selected = DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day,
  );

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  void _move(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = {for (final d in widget.days) d.day: d};
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // 일요일을 첫 칸으로: DateTime.weekday는 월=1 … 일=7
    final leading = DateTime(_month.year, _month.month).weekday % 7;
    final todayKey = dayKey(widget.today);
    final selectedKey = dayKey(_selected);
    final selectedStat = stats[selectedKey];

    Widget cell(int day) {
      final date = DateTime(_month.year, _month.month, day);
      final key = dayKey(date);
      final studied = stats.containsKey(key);
      final selected = key == selectedKey;
      return InkWell(
        key: ValueKey('cal-$key'),
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _selected = date),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 공부한 날은 채우고, 고른 날은 테두리를 굵게, 오늘은 얇은 테두리
            color: studied ? theme.colorScheme.primaryContainer : null,
            border: selected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : key == todayKey
                ? Border.all(color: theme.colorScheme.outline)
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: studied ? FontWeight.bold : null,
                ),
              ),
              // 공부한 날은 숫자 아래 작은 점도 찍는다 — 오늘·고른 날의 테두리와 겹쳐도 공부한 날임이 보인다
              // (2026-11-22 사용자 결정(UX 점검)). 점이 없는 날도 같은 높이를 차지해 숫자가 흔들리지 않는다
              const SizedBox(height: 2),
              Container(
                key: studied ? ValueKey('cal-dot-$key') : null,
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: studied ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget legendMark({
      Color? fill,
      Color? border,
      double borderWidth = 1,
      bool dot = false,
    }) => Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border == null
            ? null
            : Border.all(color: border, width: borderWidth),
      ),
      child: dot
          ? Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
    );

    Widget legendItem(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('cal-prev'),
              tooltip: '이전 달',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _move(-1),
            ),
            Expanded(
              child: Text(
                '${_month.year}년 ${_month.month}월',
                key: const ValueKey('cal-month'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              key: const ValueKey('cal-next'),
              tooltip: '다음 달',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _move(1),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(child: Text(w, style: theme.textTheme.bodySmall)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++) cell(day),
          ],
        ),
        const SizedBox(height: 8),
        // 범례: 달력의 표시가 무엇인지
        Wrap(
          key: const ValueKey('cal-legend'),
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 4,
          children: [
            legendItem(
              legendMark(fill: theme.colorScheme.primaryContainer, dot: true),
              '공부한 날',
            ),
            legendItem(legendMark(border: theme.colorScheme.outline), '오늘'),
            legendItem(
              legendMark(border: theme.colorScheme.primary, borderWidth: 2),
              '고른 날',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          selectedStat == null
              ? '${_selected.month}월 ${_selected.day}일 · 공부한 기록이 없습니다'
              : '${_selected.month}월 ${_selected.day}일 · 카드 ${selectedStat.cards}장'
                    '${selectedStat.answered == 0 ? '' : ' · 시험 ${selectedStat.correct}/${selectedStat.answered}문제 맞힘'}',
          key: const ValueKey('cal-selected'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
