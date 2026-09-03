import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// HikerAPI 호출이 실패했을 때 UI 가 그대로 보여줄 수 있는 예외.
class HikerException implements Exception {
  HikerException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;

  /// 서버가 돌려준 원문. 로그와 디버깅용이며 사용자에게는 [message] 만 보여준다.
  final String? detail;

  /// API 키를 새로 넣어야 풀리는 오류인지. 설정 화면으로 안내할 때 쓴다.
  bool get isAuthProblem => statusCode == 401 || statusCode == 403;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'HikerException($statusCode): $message';
}

/// api.hikerapi.com 에 대한 얇은 HTTP 래퍼.
///
/// 인증은 `x-access-key` 헤더 하나로 끝나고, 모든 엔드포인트가 GET 이다.
/// 여기서는 전송과 오류 변환만 맡고, 응답 해석은 [IgRepository] 가 한다.
class HikerClient {
  HikerClient({required this.readApiKey, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const String host = 'api.hikerapi.com';

  /// 설정에서 키를 지연 조회한다. 사용자가 설정 화면에서 키를 바꾸면
  /// 클라이언트를 다시 만들지 않아도 다음 호출부터 새 키가 적용된다.
  final String? Function() readApiKey;

  final http.Client _http;

  /// 응답 대기 한도. HikerAPI 는 인스타그램을 대신 조회하므로 느릴 때가 있다.
  static const Duration timeout = Duration(seconds: 45);

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final key = readApiKey();
    if (key == null || key.isEmpty) {
      throw HikerException(
        'HikerAPI 액세스 키가 설정되지 않았습니다. 설정 화면에서 키를 입력해 주세요.',
        statusCode: 401,
      );
    }

    final uri = Uri.https(host, path, _stringifyQuery(query));

    final http.Response response;
    try {
      response = await _http
          .get(uri, headers: {'x-access-key': key, 'accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw HikerException('요청 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.');
    } catch (error) {
      throw HikerException('네트워크에 연결할 수 없습니다.', detail: '$error');
    }

    if (response.statusCode == 200) {
      return _decode(response);
    }
    throw _errorFor(response);
  }

  /// Uri.https 는 값이 String 이어야 하므로 숫자·불리언을 문자열로 바꾸고,
  /// null 과 빈 문자열은 아예 빼서 서버가 기본값을 쓰게 한다.
  static Map<String, String>? _stringifyQuery(Map<String, dynamic>? query) {
    if (query == null) return null;
    final result = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      final text = value is String ? value : value.toString();
      if (text.isEmpty) continue;
      result[entry.key] = text;
    }
    return result.isEmpty ? null : result;
  }

  static dynamic _decode(http.Response response) {
    // 응답에 이모지나 한글이 섞이므로 항상 UTF-8 로 직접 디코딩한다.
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw HikerException('서버 응답을 해석할 수 없습니다.', detail: '$error');
    }
  }

  static HikerException _errorFor(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    final detail = _extractDetail(body);

    final message = switch (response.statusCode) {
      400 => detail ?? '요청 형식이 올바르지 않습니다.',
      401 || 403 => 'HikerAPI 액세스 키가 올바르지 않거나 만료되었습니다.',
      402 => 'HikerAPI 잔액이 부족합니다. 대시보드에서 크레딧을 충전해 주세요.',
      404 => '해당 게시물을 찾을 수 없습니다. 삭제되었거나 비공개 계정일 수 있습니다.',
      429 => '요청이 너무 잦습니다. 잠시 후 다시 시도해 주세요.',
      >= 500 => 'HikerAPI 서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요.',
      _ => detail ?? '요청에 실패했습니다 (HTTP ${response.statusCode}).',
    };

    return HikerException(
      message,
      statusCode: response.statusCode,
      detail: body,
    );
  }

  /// HikerAPI 오류 본문은 `{"detail": "...", "exc_type": "..."}` 형태다.
  static String? _extractDetail(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } on FormatException {
      // 본문이 JSON 이 아니면 기본 메시지를 쓴다.
    }
    return null;
  }

  void close() => _http.close();
}
