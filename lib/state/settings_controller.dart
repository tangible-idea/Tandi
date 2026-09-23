import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../services/settings_store.dart';

/// 설정 화면과 나머지 앱이 공유하는 상태.
///
/// API 키는 [HikerClient] 가 매 호출마다 동기적으로 읽어간다.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  final SettingsStore _store;

  QualityPreference _quality = QualityPreference.best;
  bool _saveToGallery = true;
  bool _isLoaded = false;
  SettingsBackend _backend = SettingsBackend.keychain;

  /// 실제로 API 호출에 쓸 키. 빌드에 심어 둔 키만 쓰며, 사용자가 바꿀 수 없다.
  /// 예전 버전에서 키체인에 저장해 둔 사용자 키가 있어도 무시한다.
  String? get apiKey =>
      AppConfig.hasBundledHikerKey ? AppConfig.hikerApiKey : null;

  QualityPreference get quality => _quality;
  bool get saveToGallery => _saveToGallery;

  /// 저장소에서 값을 읽어오기 전에는 "키 없음" 화면을 띄우지 않기 위한 플래그.
  bool get isLoaded => _isLoaded;

  bool get hasApiKey => (apiKey?.isNotEmpty ?? false);

  /// 설정값이 실제로 어디에 저장되는지. 설정 화면이 그대로 표시한다.
  SettingsBackend get backend => _backend;

  Future<void> load() async {
    _backend = await _store.backend;
    _quality = await _store.readQuality();
    _saveToGallery = await _store.readSaveToGallery();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setQuality(QualityPreference value) async {
    if (_quality == value) return;
    _quality = value;
    notifyListeners();
    await _store.writeQuality(value);
  }

  Future<void> setSaveToGallery(bool value) async {
    if (_saveToGallery == value) return;
    _saveToGallery = value;
    notifyListeners();
    await _store.writeSaveToGallery(value);
  }
}
