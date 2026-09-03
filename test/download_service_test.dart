import 'package:flutter_test/flutter_test.dart';
import 'package:tandi/models/ig_asset.dart';
import 'package:tandi/models/ig_post.dart';
import 'package:tandi/models/ig_user.dart';
import 'package:tandi/services/download_service.dart';

IgPost _post({
  required String pk,
  String? code,
  String username = 'nasa',
  int itemCount = 1,
}) {
  return IgPost(
    pk: pk,
    code: code,
    kind: PostKind.photo,
    user: IgUser(pk: '1', username: username),
    items: [
      for (var i = 0; i < itemCount; i++)
        IgItem(
          id: '$pk-$i',
          kind: AssetKind.photo,
          variants: const [
            IgAsset(kind: AssetKind.photo, url: 'https://cdn.example/a.jpg'),
          ],
        ),
    ],
  );
}

void main() {
  group('파일명 규칙', () {
    const photo = IgAsset(
      kind: AssetKind.photo,
      url: 'https://cdn.example/a.jpg',
    );
    const video = IgAsset(
      kind: AssetKind.video,
      url: 'https://cdn.example/a.mp4',
    );

    test('단일 항목은 번호를 붙이지 않는다', () {
      final name = DownloadService.buildFilename(
        _post(pk: '1', code: 'DcMXl1IPNtB'),
        video,
        index: 0,
        total: 1,
      );
      expect(name, 'nasa_DcMXl1IPNtB.mp4');
    });

    test('캐러셀은 1부터 시작하는 번호를 붙인다', () {
      final post = _post(pk: '1', code: 'DchLnq8E21N', itemCount: 3);
      expect(
        DownloadService.buildFilename(post, photo, index: 0, total: 3),
        'nasa_DchLnq8E21N_1.jpg',
      );
      expect(
        DownloadService.buildFilename(post, photo, index: 2, total: 3),
        'nasa_DchLnq8E21N_3.jpg',
      );
    });

    test('code 가 없으면 pk 를 쓴다', () {
      final name = DownloadService.buildFilename(
        _post(pk: '3975089864169193671'),
        photo,
        index: 0,
        total: 1,
      );
      expect(name, 'nasa_3975089864169193671.jpg');
    });

    test('파일명에 쓸 수 없는 문자를 밑줄로 바꾼다', () {
      final name = DownloadService.buildFilename(
        _post(pk: '1', code: 'a/b:c*d', username: '한글계정'),
        photo,
        index: 0,
        total: 1,
      );
      // 경로 구분자나 와일드카드가 그대로 남으면 저장이 실패한다.
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('*')));
      expect(name, endsWith('.jpg'));
    });
  });

  group('확장자', () {
    test('동영상은 mp4, 사진은 jpg', () {
      expect(
        const IgAsset(kind: AssetKind.video, url: 'x').fileExtension,
        'mp4',
      );
      expect(
        const IgAsset(kind: AssetKind.photo, url: 'x').fileExtension,
        'jpg',
      );
    });
  });

  group('화질 정렬', () {
    test('해상도 정보가 없는 변형은 뒤로 밀린다', () {
      final item = IgItem(
        id: '1',
        kind: AssetKind.video,
        variants: const [
          IgAsset(kind: AssetKind.video, url: 'unknown'),
          IgAsset(
            kind: AssetKind.video,
            url: 'hd',
            width: 1080,
            height: 1920,
          ),
        ],
      );
      expect(item.best!.url, 'hd');
      expect(item.smallest!.url, 'unknown');
    });

    test('해상도가 없으면 비트레이트로 순위를 가린다', () {
      final item = IgItem(
        id: '1',
        kind: AssetKind.video,
        variants: const [
          IgAsset(kind: AssetKind.video, url: 'low', bandwidth: 500000),
          IgAsset(kind: AssetKind.video, url: 'high', bandwidth: 2000000),
        ],
      );
      expect(item.best!.url, 'high');
    });
  });
}
