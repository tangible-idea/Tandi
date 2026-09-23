import 'dart:async';

import 'package:flutter/services.dart';

/// 다른 앱의 공유 시트로 넘어온 링크를 받는다.
///
/// iOS 는 공유 확장이 `townloader://share?url=...` 로 앱을 열고, Android 는
/// ACTION_SEND 인텐트로 들어온다. 네이티브 쪽이 둘 다 같은 채널로 넘겨 준다.
/// 공유 기능이 없는 플랫폼(데스크톱·테스트)에서는 조용히 아무것도 하지 않는다.
class ShareIntake {
  static const _channel = MethodChannel('townloader/share');

  final _links = StreamController<String>.broadcast();

  /// 공유된 링크. 캡션과 섞인 텍스트는 첫 URL 만 골라 낸다.
  Stream<String> get links => _links.stream;

  /// 실행 중 공유를 듣기 시작하고, 공유로 앱이 켜졌다면 그 링크를 내보낸다.
  Future<void> start() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShare' && call.arguments is String) {
        _emit(call.arguments as String);
      }
    });

    try {
      final initial = await _channel.invokeMethod<String>('getInitialShare');
      if (initial != null) _emit(initial);
    } on MissingPluginException {
      // 공유 채널이 없는 플랫폼.
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _links.close();
  }

  void _emit(String text) {
    final link = extractLink(text);
    if (link.isNotEmpty && !_links.isClosed) _links.add(link);
  }

  static final _urlPattern = RegExp(r'https?://\S+');

  /// "이 게시물 보세요 https://..." 처럼 링크 앞뒤에 글이 붙어 오는 경우가 많다.
  /// URL 이 있으면 첫 URL 을, 없으면 원문을 그대로 돌려준다(@계정명 등).
  static String extractLink(String text) =>
      _urlPattern.firstMatch(text)?.group(0) ?? text.trim();
}
