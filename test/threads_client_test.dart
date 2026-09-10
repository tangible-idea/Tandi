import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandi/data/ig_url.dart';
import 'package:tandi/data/threads_client.dart';
import 'package:tandi/models/ig_asset.dart';
import 'package:tandi/models/ig_post.dart';

void main() {
  test('Threads 주소를 공식 embed 경로로 조회한다', () async {
    final httpClient = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://www.threads.com/@instagram/post/DdE9z6Ejw7R/embed',
      );
      expect(request.headers['accept'], contains('text/html'));
      return http.Response('''
        <div class="OuterContainer">
          <a class="HeaderLink"><span>instagram</span></a>
          <div class="SoloMediaContainer">
            <video><source src="https://cdn.example/video.mp4"></video>
          </div>
        </div>
      ''', 200);
    });
    final client = ThreadsClient(httpClient: httpClient);

    final post = await client.fetchPost(
      IgUrlParser.parse(
        'https://www.threads.com/@instagram/post/DdE9z6Ejw7R?xmt=tracking',
      ),
    );

    expect(post.authorName, 'instagram');
    expect(post.items.single.best?.url, 'https://cdn.example/video.mp4');
    client.close();
  });

  group('Threads embed 파싱', () {
    test('사진 게시물을 읽고 아바타와 링크 미리보기는 제외한다', () {
      const html = '''
        <div class="OuterContainer">
          <div class="AvatarContainer"><img src="https://cdn.example/avatar.jpg"></div>
          <a class="HeaderLink"><span>natgeo</span></a>
          <div class="VerifiedBadge"></div>
          <span class="BodyTextContainer">  산 정상의 풍경  </span>
          <div class="LinkAttachmentImage"><img src="https://cdn.example/link.jpg"></div>
          <div class="SoloMediaContainer">
            <div class="SingleInnerMediaContainer">
              <img src="https://cdn.example/photo.jpg" width="1440" height="1080">
            </div>
          </div>
        </div>
      ''';

      final post = ThreadsClient.parseEmbed(html, code: 'Dc1NNbgDcmL')!;
      expect(post.kind, PostKind.photo);
      expect(post.user?.username, 'natgeo');
      expect(post.user?.isVerified, isTrue);
      expect(post.caption, '산 정상의 풍경');
      expect(
        post.permalink,
        'https://www.threads.com/@natgeo/post/Dc1NNbgDcmL',
      );
      expect(post.items, hasLength(1));
      expect(post.items.single.kind, AssetKind.photo);
      expect(post.items.single.best?.url, 'https://cdn.example/photo.jpg');
      expect(post.items.single.best?.width, 1440);
    });

    test('source 태그가 있는 동영상을 읽는다', () {
      const html = '''
        <div class="OuterContainer">
          <a class="HeaderLink"><span>instagram</span></a>
          <div class="BodyTextContainer">video post</div>
          <div class="SoloMediaContainer">
            <video poster="https://cdn.example/cover.jpg">
              <source src="https://cdn.example/video.mp4">
            </video>
          </div>
        </div>
      ''';

      final post = ThreadsClient.parseEmbed(html, code: 'DdE9z6Ejw7R')!;
      expect(post.kind, PostKind.video);
      expect(post.items.single.kind, AssetKind.video);
      expect(post.items.single.best?.url, 'https://cdn.example/video.mp4');
      expect(post.items.single.thumbnailUrl, 'https://cdn.example/cover.jpg');
    });

    test('사진과 동영상 여러 개는 캐러셀로 만든다', () {
      const html = '''
        <div class="OuterContainer">
          <a class="HeaderLink"><span>creator</span></a>
          <div class="MediaContainer">
            <img src="https://cdn.example/one.jpg">
            <video><source src="https://cdn.example/two.mp4"></video>
          </div>
        </div>
      ''';

      final post = ThreadsClient.parseEmbed(html, code: 'Carousel01')!;
      expect(post.kind, PostKind.carousel);
      expect(post.items.map((item) => item.kind), [
        AssetKind.photo,
        AssetKind.video,
      ]);
    });

    test('인용 게시물의 미디어는 섞지 않는다', () {
      const html = '''
        <div class="OuterContainer">
          <a class="HeaderLink"><span>writer</span></a>
          <div class="SoloMediaContainer"><img src="https://cdn.example/main.jpg"></div>
          <div class="OuterContainer">
            <div class="SoloMediaContainer"><img src="https://cdn.example/quote.jpg"></div>
          </div>
        </div>
      ''';

      final post = ThreadsClient.parseEmbed(html, code: 'Quoted01')!;
      expect(post.items, hasLength(1));
      expect(post.items.single.best?.url, 'https://cdn.example/main.jpg');
    });

    test('텍스트 전용 게시물은 null을 돌려준다', () {
      const html = '''
        <div class="OuterContainer">
          <a class="HeaderLink"><span>threads</span></a>
          <div class="BodyTextContainer">text only</div>
        </div>
      ''';
      expect(ThreadsClient.parseEmbed(html, code: 'TextOnly01'), isNull);
    });
  });
}
