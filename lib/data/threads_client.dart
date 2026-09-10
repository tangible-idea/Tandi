import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/ig_asset.dart';
import '../models/ig_post.dart';
import '../models/ig_user.dart';
import '../models/media_source.dart';
import 'hiker_client.dart';
import 'ig_url.dart';

/// Threads 의 공개 embed 페이지에서 게시물 미디어를 가져온다.
///
/// Threads 공식 API는 다른 사용자의 임의 게시물을 읽는 용도가 아니므로, 로그인 없이
/// 공개되는 embed HTML만 사용한다. 페이지 구조가 달라질 수 있어 파싱은 이 클래스에
/// 격리한다.
class ThreadsClient {
  ThreadsClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const Duration timeout = Duration(seconds: 30);

  Future<IgPost> fetchPost(IgLink link) async {
    final sourceUrl = link.normalizedUrl ?? link.raw;
    final sourceUri = Uri.tryParse(sourceUrl);
    if (sourceUri == null || link.code == null) {
      throw HikerException('Threads 게시물 주소를 해석하지 못했습니다.');
    }

    Uri targetUri = sourceUri;
    String targetCode = link.code!;
    String? targetUsername = link.username;

    // `/share/` 형태의 공유 링크는 먼저 리디렉션을 따라가 정식 게시물 주소를 알아낸다.
    if (sourceUri.pathSegments.contains('share')) {
      try {
        final request = http.Request('GET', sourceUri)
          ..followRedirects = true
          ..maxRedirects = 5
          ..headers.addAll(const {
            'accept': 'text/html,application/xhtml+xml',
            'user-agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                'AppleWebKit/537.36 Safari/537.36',
          });
        final streamed = await _http.send(request).timeout(timeout);
        final finalUrl = streamed.request?.url;
        if (finalUrl != null) {
          final redirectedLink = IgUrlParser.parse(finalUrl.toString());
          if (redirectedLink.code != null) {
            targetUri = finalUrl;
            targetCode = redirectedLink.code!;
            targetUsername = redirectedLink.username ?? targetUsername;
          }
        }
      } catch (_) {
        // 리디렉션 확인에 실패하면 원래 URI 로 계속 진행한다.
      }
    }

    final embedUri = targetUri.replace(
      path: '${targetUri.path.replaceFirst(RegExp(r'/+$'), '')}/embed',
      query: null,
      fragment: null,
    );

    final http.Response response;
    try {
      response = await _http
          .get(
            embedUri,
            headers: const {
              'accept': 'text/html,application/xhtml+xml',
              'user-agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                  'AppleWebKit/537.36 Safari/537.36',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw HikerException('Threads 요청 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.');
    } catch (error) {
      throw HikerException('Threads에 연결할 수 없습니다.', detail: '$error');
    }

    if (response.statusCode != 200) {
      final message = switch (response.statusCode) {
        404 => 'Threads 게시물을 찾을 수 없습니다. 삭제되었거나 비공개일 수 있습니다.',
        429 => 'Threads 요청이 너무 잦습니다. 잠시 후 다시 시도해 주세요.',
        >= 500 => 'Threads 서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요.',
        _ => 'Threads 게시물 조회에 실패했습니다 (HTTP ${response.statusCode}).',
      };
      throw HikerException(message, statusCode: response.statusCode);
    }

    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    final post = parseEmbed(
      body,
      code: targetCode,
      fallbackUsername: targetUsername,
    );
    if (post == null || !post.hasDownloadableAssets) {
      throw HikerException(
        '이 Threads 게시물에는 내려받을 사진이나 동영상이 없습니다. '
        '텍스트·링크 전용 게시물일 수 있습니다.',
      );
    }
    return post;
  }

  /// 네트워크 없이 embed HTML을 앱의 공통 게시물 모델로 바꾼다.
  static IgPost? parseEmbed(
    String html, {
    required String code,
    String? fallbackUsername,
  }) {
    final document = html_parser.parse(html);
    final outer = document.querySelector('.OuterContainer');
    if (outer == null) return null;

    final username =
        _nonEmpty(outer.querySelector('.HeaderLink span')?.text) ??
        fallbackUsername ??
        'threads';
    final caption = _nonEmpty(outer.querySelector('.BodyTextContainer')?.text);
    final profilePicUrl = outer
        .querySelector('.AvatarContainer img')
        ?.attributes['src'];
    final isVerified = outer.querySelector('.VerifiedBadge') != null;

    // 링크 미리보기와 인용 게시물의 미디어는 다운로드 대상으로 보지 않고,
    // 현재 게시물의 공식 미디어 컨테이너만 읽는다.
    final mediaRoots = outer
        .querySelectorAll(
          '.SoloMediaContainer, .MediaContainer, .SingleInnerMediaContainer, .SingleInnerMediaContainerVideo',
        )
        .where((element) => _closestOuterContainer(element) == outer);

    final items = <IgItem>[];
    final seen = <String>{};
    for (final root in mediaRoots) {
      for (final element in root.querySelectorAll('img, video')) {
        final isVideo = element.localName == 'video';
        final url = isVideo
            ? element.querySelector('source[src]')?.attributes['src'] ??
                  element.attributes['src']
            : element.attributes['src'];
        if (!_isDownloadUrl(url) || !seen.add(url!)) continue;

        final width = _dimension(element, 'width');
        final height = _dimension(element, 'height');
        final kind = isVideo ? AssetKind.video : AssetKind.photo;
        items.add(
          IgItem(
            id: '$code-${items.length + 1}',
            kind: kind,
            variants: [
              IgAsset(kind: kind, url: url, width: width, height: height),
            ],
            thumbnailUrl: isVideo ? element.attributes['poster'] : url,
          ),
        );
      }
    }

    if (items.isEmpty) return null;
    final kind = items.length > 1
        ? PostKind.carousel
        : (items.single.isVideo ? PostKind.video : PostKind.photo);

    return IgPost(
      pk: code,
      source: MediaSource.threads,
      code: code,
      kind: kind,
      user: IgUser(
        pk: username,
        username: username,
        profilePicUrl: profilePicUrl,
        isVerified: isVerified,
      ),
      caption: caption,
      items: items,
    );
  }

  static String? _nonEmpty(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static bool _isDownloadUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  static Element? _closestOuterContainer(Element element) {
    Element? current = element;
    while (current != null) {
      if (current.classes.contains('OuterContainer')) return current;
      current = current.parent;
    }
    return null;
  }

  static int? _dimension(Element element, String name) {
    final direct = int.tryParse(element.attributes[name] ?? '');
    if (direct != null) return direct;
    final style = element.attributes['style'];
    if (style == null) return null;
    final match = RegExp('$name\\s*:\\s*(\\d+)px').firstMatch(style);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  void close() => _http.close();
}
