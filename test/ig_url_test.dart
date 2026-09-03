import 'package:flutter_test/flutter_test.dart';
import 'package:tandi/data/ig_url.dart';

void main() {
  group('게시물 · 릴스 링크', () {
    test('/p/ 주소는 게시물로 읽는다', () {
      final link = IgUrlParser.parse('https://www.instagram.com/p/DchLnq8E21N/');
      expect(link.type, IgLinkType.post);
      expect(link.code, 'DchLnq8E21N');
      expect(link.normalizedUrl, 'https://www.instagram.com/p/DchLnq8E21N/');
    });

    test('/reel/ 과 /reels/ 는 모두 릴스로 읽는다', () {
      for (final path in ['reel', 'reels']) {
        final link = IgUrlParser.parse(
          'https://www.instagram.com/$path/DcMXl1IPNtB/',
        );
        expect(link.type, IgLinkType.reel, reason: path);
        expect(link.code, 'DcMXl1IPNtB');
      }
    });

    test('/tv/ 는 릴스와 같은 경로로 처리한다', () {
      final link = IgUrlParser.parse('https://instagram.com/tv/DcMXl1IPNtB/');
      expect(link.type, IgLinkType.reel);
    });

    test('추적 쿼리스트링이 붙어도 코드를 뽑아낸다', () {
      final link = IgUrlParser.parse(
        'https://www.instagram.com/p/DchLnq8E21N/?igsh=MWZ4b2k&img_index=2',
      );
      expect(link.type, IgLinkType.post);
      expect(link.code, 'DchLnq8E21N');
    });

    test('스킴이 없어도 인스타그램 주소로 인식한다', () {
      final link = IgUrlParser.parse('instagram.com/p/DchLnq8E21N/');
      expect(link.type, IgLinkType.post);
    });
  });

  group('스토리 · 하이라이트', () {
    test('스토리 단건은 계정명과 id 를 함께 담는다', () {
      final link = IgUrlParser.parse(
        'https://www.instagram.com/stories/nasa/3975089864169193671/',
      );
      expect(link.type, IgLinkType.story);
      expect(link.username, 'nasa');
      expect(link.storyId, '3975089864169193671');
    });

    test('id 가 없으면 해당 계정의 스토리 전체로 본다', () {
      final link = IgUrlParser.parse('https://www.instagram.com/stories/nasa/');
      expect(link.type, IgLinkType.userStories);
      expect(link.username, 'nasa');
    });

    test('하이라이트 주소는 id 를 뽑아낸다', () {
      final link = IgUrlParser.parse(
        'https://www.instagram.com/stories/highlights/18146216698022176/',
      );
      expect(link.type, IgLinkType.highlight);
      expect(link.highlightId, '18146216698022176');
    });

    test('/s/ 링크는 서버에 물어봐야 하는 종류로 분류한다', () {
      final link = IgUrlParser.parse(
        'https://www.instagram.com/s/aGlnaGxpZ2h0OjE4MTQ2MjE2Njk4MDIyMTc0',
      );
      expect(link.type, IgLinkType.shareToken);
      expect(link.normalizedUrl, isNotNull);
    });
  });

  group('프로필', () {
    test('계정 경로만 있으면 프로필로 본다', () {
      final link = IgUrlParser.parse('https://www.instagram.com/nasa/');
      expect(link.type, IgLinkType.profile);
      expect(link.username, 'nasa');
    });

    test('프로필 하위 탭도 프로필로 본다', () {
      final link = IgUrlParser.parse('https://www.instagram.com/nasa/reels/');
      expect(link.type, IgLinkType.profile);
      expect(link.username, 'nasa');
    });

    test('@핸들 표기를 받는다', () {
      final link = IgUrlParser.parse('@nasa');
      expect(link.type, IgLinkType.profile);
      expect(link.username, 'nasa');
    });

    test('계정명은 소문자로 정규화한다', () {
      expect(IgUrlParser.parse('@NASA').username, 'nasa');
      expect(
        IgUrlParser.parse('https://www.instagram.com/NASA/').username,
        'nasa',
      );
    });

    test('explore 같은 예약 경로는 프로필로 오인하지 않는다', () {
      expect(
        IgUrlParser.parse('https://www.instagram.com/explore/tags/nasa/').type,
        IgLinkType.unknown,
      );
      expect(
        IgUrlParser.parse('https://www.instagram.com/accounts/login/').type,
        IgLinkType.unknown,
      );
    });
  });

  group('맨몸 토큰', () {
    test('11자리 단축코드는 게시물로 본다', () {
      final link = IgUrlParser.parse('DchLnq8E21N');
      expect(link.type, IgLinkType.post);
      expect(link.code, 'DchLnq8E21N');
    });

    test('짧은 문자열은 계정명으로 본다', () {
      final link = IgUrlParser.parse('nasa');
      expect(link.type, IgLinkType.profile);
      expect(link.username, 'nasa');
    });
  });

  group('거부해야 하는 입력', () {
    test('인스타그램이 아닌 도메인은 받지 않는다', () {
      expect(
        IgUrlParser.parse('https://youtube.com/watch?v=abc').type,
        IgLinkType.unknown,
      );
      // 도메인 끝만 비슷하게 맞춘 피싱성 주소도 걸러져야 한다.
      expect(
        IgUrlParser.parse('https://instagram.com.evil.io/p/DchLnq8E21N/').type,
        IgLinkType.unknown,
      );
    });

    test('빈 문자열과 공백은 unknown', () {
      expect(IgUrlParser.parse('').type, IgLinkType.unknown);
      expect(IgUrlParser.parse('   ').type, IgLinkType.unknown);
    });
  });
}
