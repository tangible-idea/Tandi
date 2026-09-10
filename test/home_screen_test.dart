import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tandi/data/hiker_client.dart';
import 'package:tandi/data/ig_repository.dart';
import 'package:tandi/data/threads_client.dart';
import 'package:tandi/services/download_service.dart';
import 'package:tandi/services/settings_store.dart';
import 'package:tandi/state/resolve_controller.dart';
import 'package:tandi/state/settings_controller.dart';
import 'package:tandi/ui/home_screen.dart';

class _NoKeyStore extends SettingsStore {
  @override
  Future<SettingsBackend> get backend async => SettingsBackend.keychain;

  @override
  Future<String?> readApiKey() async => null;

  @override
  Future<bool> writeApiKey(String? value) async => true;

  @override
  Future<QualityPreference> readQuality() async => QualityPreference.best;

  @override
  Future<bool> writeQuality(QualityPreference value) async => true;

  @override
  Future<bool> readSaveToGallery() async => true;

  @override
  Future<bool> writeSaveToGallery(bool value) async => true;
}

void main() {
  testWidgets('API 키가 없어도 Threads 게시물을 정상적으로 가져와 화면에 표시한다', (tester) async {
    final store = _NoKeyStore();
    final settings = SettingsController(store);
    await settings.load();

    final threadsHttpClient = MockClient((request) async {
      return http.Response('''
        <div class="OuterContainer">
          <a class="HeaderLink"><span>testuser</span></a>
          <div class="SoloMediaContainer">
            <img src="https://cdn.example/photo.jpg" width="1080" height="1080">
          </div>
        </div>
      ''', 200);
    });

    final hikerClient = HikerClient(readApiKey: () => settings.apiKey);
    final threadsClient = ThreadsClient(httpClient: threadsHttpClient);
    final repository = IgRepository(hikerClient, threadsClient: threadsClient);
    final resolveController = ResolveController(repository);
    final downloadService = DownloadService(settings: store);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: downloadService),
          ChangeNotifierProvider.value(value: resolveController),
        ],
        child: MaterialApp(
          home: HomeScreen(
            onOpenSettings: () {},
            onOpenProfile: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 초기 상태에서 Threads는 키 없이 바로 받을 수 있다는 안내가 표시된다.
    expect(find.textContaining('Threads: API 키 없이 바로 다운로드 가능'), findsOneWidget);

    // Threads 주소를 입력하고 가져오기를 누른다.
    await tester.enterText(
      find.byType(TextField),
      'https://www.threads.com/@testuser/post/C1234567890',
    );
    await tester.tap(find.text('가져오기'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Threads 게시물 결과가 화면에 나타난다.
    expect(find.text('@testuser · Threads · 사진'), findsOneWidget);
  });

  testWidgets('API 키가 없을 때 인스타그램 링크를 조회하면 HikerAPI 키 설정 안내를 표시한다', (tester) async {
    final store = _NoKeyStore();
    final settings = SettingsController(store);
    await settings.load();

    final hikerClient = HikerClient(readApiKey: () => settings.apiKey);
    final repository = IgRepository(hikerClient);
    final resolveController = ResolveController(repository);
    final downloadService = DownloadService(settings: store);

    var settingsOpened = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: downloadService),
          ChangeNotifierProvider.value(value: resolveController),
        ],
        child: MaterialApp(
          home: HomeScreen(
            onOpenSettings: () => settingsOpened = true,
            onOpenProfile: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 인스타그램 주소 입력 후 가져오기
    await tester.enterText(
      find.byType(TextField),
      'https://www.instagram.com/reel/C1234567890/',
    );
    await tester.tap(find.text('가져오기'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 오류 안내와 설정 열기 버튼이 표시된다.
    expect(find.text('가져오지 못했습니다'), findsOneWidget);
    expect(find.textContaining('HikerAPI 액세스 키가 설정되지 않았습니다'), findsOneWidget);
    expect(find.text('설정 열기'), findsOneWidget);

    await tester.tap(find.text('설정 열기'));
    expect(settingsOpened, isTrue);
  });
}
