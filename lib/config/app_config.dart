/// 빌드 시점에 심어 두는 설정값.
///
/// 값은 `--dart-define-from-file=.env.json` 으로 넘긴다.
///
///     flutter run  --dart-define-from-file=.env.json -d <기기>
///     flutter build ipa --dart-define-from-file=.env.json
///
/// 주의: 여기 심은 값은 비밀이 아니다. 컴파일된 스냅샷에 문자열로 남으므로
/// 배포본을 뜯으면 복원할 수 있다. HikerAPI 는 호출 건수로 과금하니, 공개
/// 배포본에 키를 심으면 크레딧이 소진될 수 있다. 사내·개인용 빌드에만 쓰고,
/// 공개 배포에는 키를 쥔 프록시 서버를 두는 편이 맞다.
class AppConfig {
  const AppConfig._();

  /// 빌드에 심어 둔 HikerAPI 액세스 키. 안 넘기면 빈 문자열이다.
  static const String hikerApiKey = String.fromEnvironment('HIKER_API_KEY');

  static bool get hasBundledHikerKey => hikerApiKey.isNotEmpty;
}
