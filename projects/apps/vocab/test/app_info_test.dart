import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/app_info.dart';

void main() {
  test('메뉴에 보이는 버전은 pubspec.yaml의 version과 같다', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final version = line.substring('version:'.length).trim().split('+').first;
    expect(appVersion, version);
  });
}
