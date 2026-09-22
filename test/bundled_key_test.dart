import 'package:flutter_test/flutter_test.dart';
import 'package:tandi/config/app_config.dart';
import 'package:tandi/services/settings_store.dart';
import 'package:tandi/state/settings_controller.dart';

class _Store extends SettingsStore {
  _Store(this._key);
  final String? _key;

  @override
  Future<SettingsBackend> get backend async => SettingsBackend.keychain;
  @override
  Future<String?> readApiKey() async => _key;
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
  test('사용자가 넣은 키가 빌드에 심어 둔 키보다 우선한다', () async {
    final controller = SettingsController(_Store('user-key'));
    await controller.load();

    expect(controller.apiKey, 'user-key');
    expect(controller.userApiKey, 'user-key');
    expect(controller.hasApiKey, isTrue);
    expect(controller.usesBundledKey, isFalse);
  });

  test('사용자 키가 없으면 심어 둔 키로 넘어간다', () async {
    final controller = SettingsController(_Store(null));
    await controller.load();

    // 심어 둔 키가 있고 없고에 따라 기대값이 갈린다. 두 빌드 모두에서 돌아야 한다.
    if (AppConfig.hasBundledHikerKey) {
      expect(controller.apiKey, AppConfig.hikerApiKey);
      expect(controller.hasApiKey, isTrue);
      expect(controller.usesBundledKey, isTrue);
    } else {
      expect(controller.apiKey, isNull);
      expect(controller.hasApiKey, isFalse);
      expect(controller.usesBundledKey, isFalse);
    }
    // 어느 쪽이든 입력칸에는 아무것도 뜨지 않아야 한다.
    expect(controller.userApiKey, isNull);
  });
}
