import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tandi/services/file_saver.dart';
import 'package:tandi/services/settings_store.dart';

/// 실제 기기에서만 확인할 수 있는 것들을 점검한다.
///
/// 유닛 테스트는 플러그인 채널을 타지 않으므로, 키체인 저장과 다운로드 폴더
/// 접근이 정말 되는지는 여기서만 알 수 있다.
/// 실행: `flutter test integration_test/platform_smoke_test.dart -d macos`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('보안 저장소', () {
    final store = SettingsStore();

    tearDown(() async {
      await store.writeApiKey('');
    });

    test('어떤 백엔드를 쓰는지 확정된다', () async {
      final backend = await store.backend;
      // 어느 쪽이든 동작해야 한다. 실제로 무엇이 선택됐는지는 로그로 남긴다.
      expect(SettingsBackend.values, contains(backend));
      debugPrint('설정 저장 백엔드: $backend');
    });

    test('API 키를 쓰고 다시 읽을 수 있다', () async {
      final saved = await store.writeApiKey('test-access-key-123');
      expect(
        saved,
        isTrue,
        reason: '저장이 실패하면 설정 화면에서 키가 유지되지 않는다',
      );
      expect(await store.readApiKey(), 'test-access-key-123');
    });

    test('빈 값을 쓰면 키가 지워진다', () async {
      await store.writeApiKey('temp');
      await store.writeApiKey('');
      expect(await store.readApiKey(), isNull);
    });

    test('화질 설정이 왕복한다', () async {
      await store.writeQuality(QualityPreference.smallest);
      expect(await store.readQuality(), QualityPreference.smallest);
      await store.writeQuality(QualityPreference.best);
      expect(await store.readQuality(), QualityPreference.best);
    });
  });

  group('저장 경로', () {
    test('파일을 쓸 수 있는 기본 폴더를 얻는다', () async {
      final base = MediaFileSaver.isDesktop
          ? await getDownloadsDirectory() ??
                await getApplicationDocumentsDirectory()
          : await getApplicationDocumentsDirectory();

      final dir = Directory('${base.path}/Tandi/_smoke_test');
      await dir.create(recursive: true);

      final file = File('${dir.path}/probe.txt');
      await file.writeAsString('ok');
      expect(await file.readAsString(), 'ok');

      await dir.delete(recursive: true);
    });

    test('임시 폴더에 스트리밍 버퍼를 만들 수 있다', () async {
      final temp = await getTemporaryDirectory();
      // DownloadService 와 같은 순서로 확인한다. 샌드박스 컨테이너에서는 이
      // 폴더가 아직 없어서, 만들지 않고 열면 PathNotFoundException 이 난다.
      await temp.create(recursive: true);

      final file = File('${temp.path}/tandi_probe.bin');
      final sink = file.openWrite();
      sink.add(List<int>.filled(1024, 7));
      await sink.flush();
      await sink.close();

      expect(await file.length(), 1024);
      await file.delete();
    });
  });
}
