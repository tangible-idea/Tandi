import 'package:flutter_test/flutter_test.dart';
import 'package:tandi/data/media_parser.dart';
import 'package:tandi/models/ig_asset.dart';
import 'package:tandi/models/ig_post.dart';

/// 아래 픽스처는 HikerAPI 의 실제 응답 형태를 그대로 줄인 것이다.
/// 필드 이름과 중첩 구조가 바뀌면 이 테스트가 먼저 깨져야 한다.
void main() {
  group('릴스(동영상)', () {
    final reel = <String, dynamic>{
      'pk': '3970959123456789012',
      'id': '3970959123456789012_528817151',
      'code': 'DcMXl1IPNtB',
      'taken_at': '2026-08-20T11:00:53Z',
      'media_type': 2,
      'product_type': 'clips',
      'thumbnail_url': 'https://cdn.example/thumb.jpg',
      'caption_text': '  우주에서 본 지구  ',
      'like_count': 120000,
      'play_count': 3400000,
      'video_duration': 50.4,
      'user': {'pk': 528817151, 'username': 'nasa', 'is_verified': true},
      'video_versions': [
        {
          'url': 'https://cdn.example/720.mp4',
          'width': 720,
          'height': 1280,
          'bandwidth': 931127,
        },
        {
          'url': 'https://cdn.example/1080.mp4',
          'width': 1080,
          'height': 1920,
          'bandwidth': 2100000,
        },
      ],
      'video_url': 'https://cdn.example/1080.mp4',
    };

    test('릴스로 분류하고 작성자를 읽는다', () {
      final post = MediaParser.parsePost(reel)!;
      expect(post.kind, PostKind.reel);
      expect(post.pk, '3970959123456789012');
      expect(post.code, 'DcMXl1IPNtB');
      expect(post.user?.username, 'nasa');
      expect(post.user?.isVerified, isTrue);
    });

    test('화질 변형을 해상도 내림차순으로 정렬한다', () {
      final item = MediaParser.parsePost(reel)!.items.single;
      expect(item.kind, AssetKind.video);
      expect(item.variants.map((v) => v.height).toList(), [1920, 1280]);
      expect(item.best!.url, 'https://cdn.example/1080.mp4');
      expect(item.smallest!.url, 'https://cdn.example/720.mp4');
    });

    test('video_url 이 최고 화질과 같으면 중복으로 넣지 않는다', () {
      final item = MediaParser.parsePost(reel)!.items.single;
      expect(item.variants.length, 2);
    });

    test('캡션 앞뒤 공백을 정리한다', () {
      expect(MediaParser.parsePost(reel)!.caption, '우주에서 본 지구');
    });

    test('ISO 8601 문자열 날짜를 읽는다', () {
      final takenAt = MediaParser.parsePost(reel)!.takenAt;
      expect(takenAt?.toUtc().year, 2026);
      expect(takenAt?.toUtc().month, 8);
      expect(takenAt?.toUtc().day, 20);
    });
  });

  group('캐러셀', () {
    final carousel = <String, dynamic>{
      'pk': '3973939000000000000',
      'code': 'DchLnq8E21N',
      // 캐러셀 컨테이너는 유닉스 초로 오는 경우가 있다.
      'taken_at': 1787000000,
      'media_type': 8,
      'product_type': 'carousel_container',
      'user': {'pk': '528817151', 'username': 'nasa'},
      'resources': [
        {
          'pk': '3973939422560272011',
          'media_type': 1,
          'thumbnail_url': 'https://cdn.example/c1-thumb.jpg',
          'image_versions': [
            {'url': 'https://cdn.example/c1-1440.jpg', 'width': 1440, 'height': 1440},
            {'url': 'https://cdn.example/c1-640.jpg', 'width': 640, 'height': 640},
          ],
        },
        {
          'pk': '3973939422560272012',
          'media_type': 2,
          'thumbnail_url': 'https://cdn.example/c2-thumb.jpg',
          'video_url': 'https://cdn.example/c2.mp4',
          'video_duration': 12.5,
        },
      ],
    };

    test('자식 항목마다 하나씩 만든다', () {
      final post = MediaParser.parsePost(carousel)!;
      expect(post.kind, PostKind.carousel);
      expect(post.items.length, 2);
      expect(post.items[0].kind, AssetKind.photo);
      expect(post.items[1].kind, AssetKind.video);
    });

    test('사진 자식은 가장 큰 해상도를 최고 화질로 고른다', () {
      final post = MediaParser.parsePost(carousel)!;
      expect(post.items[0].best!.url, 'https://cdn.example/c1-1440.jpg');
    });

    test('video_versions 없이 video_url 만 있어도 받을 수 있다', () {
      final post = MediaParser.parsePost(carousel)!;
      expect(post.items[1].best!.url, 'https://cdn.example/c2.mp4');
      expect(post.items[1].best!.fileExtension, 'mp4');
    });

    test('유닉스 초 형태의 날짜도 읽는다', () {
      expect(MediaParser.parsePost(carousel)!.takenAt, isNotNull);
    });
  });

  group('스토리', () {
    test('image_versions 가 없는 사진 스토리는 thumbnail_url 을 쓴다', () {
      final post = MediaParser.parsePost({
        'pk': '3975149624330424527',
        'code': 'DcqkYWnPhDP',
        'media_type': 1,
        'product_type': 'story',
        'thumbnail_url': 'https://cdn.example/story.jpg',
        'video_url': null,
        'user': {'pk': '528817151', 'username': 'nasa'},
      })!;

      expect(post.kind, PostKind.story);
      expect(post.items.single.best!.url, 'https://cdn.example/story.jpg');
      expect(post.items.single.best!.fileExtension, 'jpg');
    });

    test('동영상 스토리는 video_url 을 받는다', () {
      final post = MediaParser.parsePost({
        'pk': '3975089864169193671',
        'media_type': 2,
        'product_type': 'story',
        'thumbnail_url': 'https://cdn.example/story-cover.jpg',
        'video_url': 'https://cdn.example/story.mp4',
        'video_duration': 26.8,
        'user': {'pk': '528817151', 'username': 'nasa'},
      })!;

      expect(post.kind, PostKind.story);
      expect(post.items.single.best!.url, 'https://cdn.example/story.mp4');
      expect(post.items.single.durationSeconds, closeTo(26.8, 0.01));
    });
  });

  group('견고성', () {
    test('사진 게시물을 photo 로 분류한다', () {
      final post = MediaParser.parsePost({
        'pk': '1',
        'media_type': 1,
        'product_type': 'feed',
        'image_versions': [
          {'url': 'https://cdn.example/a.jpg', 'width': 1080, 'height': 1350},
        ],
      })!;
      expect(post.kind, PostKind.photo);
    });

    test('v2 형태의 image_versions2.candidates 도 읽는다', () {
      final post = MediaParser.parsePost({
        'pk': '2',
        'media_type': 1,
        'image_versions2': {
          'candidates': [
            {'url': 'https://cdn.example/b.jpg', 'width': 1080, 'height': 1080},
          ],
        },
      })!;
      expect(post.items.single.best!.url, 'https://cdn.example/b.jpg');
    });

    test('pk 가 없으면 null 을 돌려준다', () {
      expect(MediaParser.parsePost({'media_type': 1}), isNull);
      expect(MediaParser.parsePost(null), isNull);
    });

    test('받을 URL 이 하나도 없으면 다운로드 불가로 표시한다', () {
      final post = MediaParser.parsePost({'pk': '3', 'media_type': 1})!;
      expect(post.hasDownloadableAssets, isFalse);
    });

    test('큰 정수 pk 가 문자열로 보존된다', () {
      final post = MediaParser.parsePost({
        'pk': 3975089864169193671,
        'media_type': 1,
        'thumbnail_url': 'https://cdn.example/x.jpg',
      })!;
      expect(post.pk, '3975089864169193671');
    });

    test('목록에서 해석 불가 항목은 건너뛴다', () {
      final posts = MediaParser.parsePosts([
        {'media_type': 1}, // pk 없음
        'not a map',
        {
          'pk': '9',
          'media_type': 1,
          'thumbnail_url': 'https://cdn.example/y.jpg',
        },
      ]);
      expect(posts.length, 1);
      expect(posts.single.pk, '9');
    });
  });
}
