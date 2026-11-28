import 'package:material_ui/material_ui.dart';

import '../../app_info.dart';

/// 단어 출처의 인용 문구. 형식은 각 자료가 정한 것이라 고치지 않는다
/// (근거와 받은 날짜는 docs/wordlist/README.md).
const String cefrjCitation =
    'The CEFR-J Wordlist Version 1.6. Compiled by Yukio Tono, Tokyo University of '
    'Foreign Studies. Retrieved from https://www.cefr-j.org/download.html on 23/11/26.';
const String frequencyCitation =
    'Word frequency: Google Books Ngram dataset (version 20200217), licensed under '
    'CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), as compiled in '
    'hackerb9/gwordlist (https://github.com/hackerb9/gwordlist).';

/// 앱 정보(☰ 메뉴 맨 아래 → 앱 정보): 앱 이름·버전, 오픈소스 라이선스, 단어 출처
/// (2026-11-23 사용자 결정). 나중에 문의 연락처·개인정보 처리방침도 여기에 둔다.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
            const Divider(height: 1),
            // 단어 출처: 초·중·고·심화 단어 모두 CEFR-J에서 골랐다(docs/plan-words-phase1.md · phase2 · phase3 · phase4)
            Padding(
              key: const ValueKey('about-sources'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('단어 출처', style: text.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '단어의 선정과 난이도 구분은 아래 자료를 바탕으로 했습니다. 뜻과 예문은 직접 썼습니다',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(cefrjCitation, style: text.bodySmall),
                  const SizedBox(height: 8),
                  Text(frequencyCitation, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
