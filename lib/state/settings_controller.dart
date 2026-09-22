import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../services/settings_store.dart';

/// 설정 화면과 나머지 앱이 공유하는 상태.
///
/// API 키는 [HikerClient] 가 매 호출마다 동기적으로 읽어가므로, 저장소 값을
/// 메모리에 캐시해 두고 여기서 내어 준다.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  final SettingsStore _store;

  String? _apiKey;
  QualityPreference _quality = QualityPreference.best;
  bool _saveToGallery = true;
  bool _isLoaded = false;
  SettingsBackend _backend = SettingsBackend.keychain;

  /// 실제로 API 호출에 쓸 키.
  ///
  /// 사용자가 설정 화면에서 넣은 키가 우선이고, 없으면 빌드에 심어 둔 키를 쓴다.
  /// 덕분에 키를 심어 배포하면 사용자는 아무것도 입력하지 않아도 되고, 자기 키를
  /// 쓰고 싶은 사용자는 설정에서 덮어쓸 수 있다.
  String? get apiKey {
    final own = _apiKey;
    if (own != null && own.isNotEmpty) return own;
    return AppConfig.hasBundledHikerKey ? AppConfig.hikerApiKey : null;
  }

  /// 사용자가 직접 넣어 둔 키만. 설정 화면 입력칸이 이 값을 보여 준다.
  /// 심어 둔 키가 입력칸에 노출되거나 키체인에 옮겨 적히지 않게 하려는 것이다.
  String? get userApiKey => _apiKey;

  /// 심어 둔 키로 동작 중인지. 설정 화면이 그대로 안내한다.
  bool get usesBundledKey =>
      (_apiKey == null || _apiKey!.isEmpty) && AppConfig.hasBundledHikerKey;
  QualityPreference get quality => _quality;
  bool get saveToGallery => _saveToGallery;

  /// 저장소에서 값을 읽어오기 전에는 "키 없음" 화면을 띄우지 않기 위한 플래그.
  bool get isLoaded => _isLoaded;

  bool get hasApiKey => (apiKey?.isNotEmpty ?? false);

  /// 설정값이 실제로 어디에 저장되는지. 설정 화면이 그대로 표시한다.
  SettingsBackend get backend => _backend;

  Future<void> load() async {
    _backend = await _store.backend;
    _apiKey = await _store.readApiKey();
    _quality = await _store.readQuality();
    _saveToGallery = await _store.readSaveToGallery();
    _isLoaded = true;
    notifyListeners();
  }

  /// 키를 저장한다. 키체인 쓰기가 실패하면 false 를 돌려주지만, 메모리에는
  /// 반영해 두므로 이번 실행 동안에는 그대로 쓸 수 있다.
  Future<bool> setApiKey(String value) async {
    final trimmed = value.trim();
    _apiKey = trimmed.isEmpty ? null : trimmed;
    notifyListeners();
    return _store.writeApiKey(trimmed);
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
