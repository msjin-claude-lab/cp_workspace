import 'package:material_ui/material_ui.dart';

import '../../app_info.dart';

/// 앱 정보(☰ 메뉴 맨 아래 → 앱 정보): 앱 이름·버전과 오픈소스 라이선스
/// (2026-11-23 사용자 결정). 단어 출처(인용 문구)는 그 목록으로 단어를 실제로 넣을 때 여기에 더한다.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 정보')),
      body: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              key: ValueKey('about-app'),
              leading: Icon(Icons.menu_book_outlined),
              title: Text(appTitle),
              subtitle: Text('버전 $appVersion'),
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('about-licenses'),
              leading: const Icon(Icons.description_outlined),
              title: const Text('오픈소스 라이선스'),
              subtitle: const Text('이 앱이 쓰는 소프트웨어의 라이선스'),
              trailing: const Icon(Icons.chevron_right),
              // 목록은 Flutter가 앱에 든 패키지에서 자동으로 만든다
              onTap: () => showLicensePage(
                context: context,
                applicationName: appTitle,
                applicationVersion: appVersion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
