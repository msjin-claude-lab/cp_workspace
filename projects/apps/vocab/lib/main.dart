import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_info.dart';
import 'features/reminder/reminder_host.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: VocabApp()));
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appTitle,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.indigo)),
      routerConfig: appRouter,
      // 매일 알림: 처음 실행 때 권한 묻기, 예약, 알림을 누르면 오늘의 단어(2026-11-28 사용자 결정)
      builder: (context, child) =>
          ReminderHost(router: appRouter, child: child ?? const SizedBox()),
    );
  }
}
