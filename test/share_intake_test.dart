import 'package:flutter_test/flutter_test.dart';
import 'package:townloader/services/share_intake.dart';

void main() {
  group('ShareIntake.extractLink', () {
    test('링크만 온 경우 그대로 쓴다', () {
      expect(
        ShareIntake.extractLink('https://www.instagram.com/reel/ABC123/'),
        'https://www.instagram.com/reel/ABC123/',
      );
    });

    test('캡션과 섞여 오면 첫 URL 만 고른다', () {
      expect(
        ShareIntake.extractLink(
          '이 릴스 봐요 https://www.instagram.com/reel/ABC123/?igsh=x 대박\nhttps://other.com',
        ),
        'https://www.instagram.com/reel/ABC123/?igsh=x',
      );
    });

    test('URL 이 없으면 원문을 다듬어 돌려준다', () {
      expect(ShareIntake.extractLink('  @nasa \n'), '@nasa');
    });
  });
}
