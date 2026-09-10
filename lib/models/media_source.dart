/// 미디어를 가져온 서비스.
///
/// 인스타그램과 Threads 는 미디어 JSON 구조가 사실상 같아서 [IgPost] 계열 모델을
/// 그대로 공유한다. 다만 퍼머링크 형태와 화면에 붙는 출처 표기가 달라서, 어느
/// 서비스에서 온 게시물인지는 끝까지 들고 다녀야 한다.
enum MediaSource { instagram, threads }

extension MediaSourceLabel on MediaSource {
  String get label => switch (this) {
    MediaSource.instagram => '인스타그램',
    MediaSource.threads => 'Threads',
  };
}
