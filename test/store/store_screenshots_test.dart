import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:townloader/data/hiker_client.dart';
import 'package:townloader/data/ig_repository.dart';
import 'package:townloader/data/ig_url.dart';
import 'package:townloader/l10n/strings.dart';
import 'package:townloader/models/ig_asset.dart';
import 'package:townloader/models/ig_post.dart';
import 'package:townloader/models/ig_user.dart';
import 'package:townloader/services/download_service.dart';
import 'package:townloader/services/file_saver.dart';
import 'package:townloader/services/settings_store.dart';
import 'package:townloader/state/profile_controller.dart';
import 'package:townloader/state/resolve_controller.dart';
import 'package:townloader/state/settings_controller.dart';
import 'package:townloader/ui/profile_screen.dart';
import 'package:townloader/ui/root_shell.dart';
import 'package:townloader/ui/theme.dart';

/// App Store 업로드용 스크린샷(6.7" iPhone, 1284×2778)을 만든다.
///
/// 실제 앱 화면을 폰 목업에 넣고 위에 문구를 얹는다. 평소 테스트에서는 건너뛴다.
///
///     STORE_SHOTS=1 flutter test test/store/store_screenshots_test.dart
///
/// 결과는 `store/app_store/screenshots/<언어>/` 에 떨어진다. 사진은 picsum.photos(Unsplash 라이선스)에서
/// 받은 것이고, 계정·게시물은 모두 지어낸 예시다.
void main() {
  final enabled = Platform.environment['STORE_SHOTS'] == '1';

  setUpAll(() async {
    if (!enabled) return;
    await _loadFonts();
  });

  for (final copy in _copies) {
    testWidgets('${copy.locale} 01 링크 하나로 저장', (tester) async {
      final env = await _Env.create(tester, copy.appLocale);
      await env.pump(
        _StoreFrame(
          title: copy.link.title,
          subtitle: copy.link.subtitle,
          titleSize: copy.titleSize,
          screen: const RootShell(),
        ),
        locale: copy.appLocale,
      );

      final field = find.descendant(
        of: find.byType(RootShell),
        matching: find.byType(TextField),
      );
      await tester.enterText(field.first, 'instagram.com/p/DchLnq8E21N');
      await tester.tap(find.byTooltip(copy.strings.fetch));
      await _settle(tester);

      await _capture(tester, copy.locale, '01_link.png');
    }, skip: !enabled);

    testWidgets('${copy.locale} 02 공유하면 바로 다운로드', (tester) async {
      final env = await _Env.create(tester, copy.appLocale);

      // 공유로 들어온 링크가 큐에 들어가 한창 받는 중인 모습을 만든다.
      env.downloads.enqueueAll(_sharedPosts, quality: QualityPreference.best);
      final items = env.downloads.items;
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        if (index < 2) {
          item
            ..status = DownloadStatus.running
            ..totalBytes = 10000000
            ..receivedBytes = index == 0 ? 6400000 : 2300000;
        } else {
          item
            ..status = DownloadStatus.completed
            ..savedLocation = SavedLocation(
              description: S.current.savedToAlbum(MediaFileSaver.albumName),
            );
        }
      }

      await env.pump(
        _StoreFrame(
          title: copy.share.title,
          subtitle: copy.share.subtitle,
          titleSize: copy.titleSize,
          screen: const RootShell(),
          badge: _ShareBadge(hint: copy.shareHint),
        ),
        locale: copy.appLocale,
      );
      await tester.tap(find.text(copy.strings.navDownloads));
      await _settle(tester);

      await _capture(tester, copy.locale, '02_share.png');
    }, skip: !enabled);

    testWidgets('${copy.locale} 03 프로필 통째로 둘러보기', (tester) async {
      final env = await _Env.create(tester, copy.appLocale);
      await env.pump(
        _StoreFrame(
          title: copy.profile.title,
          subtitle: copy.profile.subtitle,
          titleSize: copy.titleSize,
          screen: const RootShell(),
        ),
        locale: copy.appLocale,
      );

      await tester.tap(find.text(copy.strings.navProfile));
      await tester.pump();
      final field = find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, _user.username);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      FocusManager.instance.primaryFocus?.unfocus();
      await _settle(tester);

      await _capture(tester, copy.locale, '03_profile.png');
    }, skip: !enabled);
  }
}

// ── 문구 ────────────────────────────────────────────────────────────────────

/// 언어마다 앱 화면도 그 언어로 띄우고, 위에 얹는 문구도 바꾼다.
class _Copy {
  const _Copy({
    required this.locale,
    required this.titleSize,
    required this.link,
    required this.share,
    required this.profile,
    required this.shareHint,
  });

  /// App Store Connect(fastlane) 의 언어 폴더 이름.
  final String locale;

  /// 앱 화면을 이 언어로 띄운다.
  Locale get appLocale => Locale(locale.split('-').first);
  S get strings => S(appLocale.languageCode != 'en');
  final double titleSize;
  final ({String title, String subtitle}) link;
  final ({String title, String subtitle}) share;
  final ({String title, String subtitle}) profile;
  final String shareHint;
}

const _copies = [
  _Copy(
    locale: 'ko',
    titleSize: 38,
    link: (title: '링크 하나로\n원본 화질 그대로', subtitle: '사진·릴스·캐러셀을 가장 높은 화질로 저장해요'),
    share: (
      title: '공유 버튼 한 번이면\n바로 다운로드',
      subtitle: '인스타그램·Threads 공유 목록에서 Townloader를 고르세요',
    ),
    profile: (
      title: '계정을 통째로 보고\n원하는 것만 골라서',
      subtitle: '게시물·릴스·스토리를 한눈에 둘러봐요',
    ),
    shareHint: '공유 목록에서 선택',
  ),
  _Copy(
    locale: 'en-US',
    titleSize: 34,
    link: (
      title: 'One link.\nOriginal quality.',
      subtitle: 'Save photos, videos and carousels in full resolution',
    ),
    share: (
      title: 'Share once.\nDownload instantly.',
      subtitle: 'Pick Townloader in the share sheet',
    ),
    profile: (
      title: 'Browse an account.\nKeep what you like.',
      subtitle: 'See posts, reels and stories at a glance',
    ),
    shareHint: 'Pick it in the share sheet',
  ),
];

// ── 캔버스 ────────────────────────────────────────────────────────────────────

/// App Store Connect 가 받는 6.7" 규격(1284×2778). 논리 크기 428×926 을 3배로 찍는다.
const _canvas = Size(428, 926);
const _pixelRatio = 3.0;

/// 목업 안 화면은 iPhone 16 Pro 논리 크기.
const _screen = Size(402, 874);

final _shotKey = GlobalKey();

const _korean = 'Pretendard';

class _Env {
  _Env._(this.tester, this.downloads, this.repository);

  final WidgetTester tester;
  final DownloadService downloads;
  final _StoreRepository repository;

  static Future<_Env> create(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = _canvas * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // 데이터 계층 문구(S.current)는 기기 언어를 따르므로 함께 맞춘다.
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await _primeImages(tester);
    final store = _MemoryStore();
    return _Env._(
      tester,
      DownloadService(settings: store, httpClient: _HangingClient()),
      _StoreRepository(),
    );
  }

  Future<void> pump(Widget frame, {required Locale locale}) async {
    final settings = _StoreSettings(_MemoryStore());
    await settings.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settings),
          ChangeNotifierProvider.value(value: downloads),
          ChangeNotifierProvider(create: (_) => ResolveController(repository)),
          ChangeNotifierProvider(create: (_) => ProfileController(repository)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(fontFallback: const [_korean]),
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en')],
          // Material 이 없으면 프레임 문구에 디버그용 노란 밑줄이 그어진다.
          home: RepaintBoundary(
            key: _shotKey,
            child: Material(type: MaterialType.transparency, child: frame),
          ),
        ),
      ),
    );
    await tester.pump();
  }
}

/// 탭 잉크와 전환 애니메이션이 끝날 때까지 시간을 흘린다.
/// 진행 중 다운로드의 스피너 때문에 pumpAndSettle 은 끝나지 않아 직접 넘긴다.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _capture(WidgetTester tester, String locale, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_shotKey),
    );
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('store/app_store/screenshots/$locale/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

// ── 프레임 ────────────────────────────────────────────────────────────────────

class _StoreFrame extends StatelessWidget {
  const _StoreFrame({
    required this.title,
    required this.subtitle,
    required this.screen,
    this.titleSize = 38,
    this.badge,
  });

  final String title;
  final double titleSize;
  final String subtitle;
  final Widget screen;

  /// 폰 위에 겹쳐 띄우는 강조 카드.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.white, Color(0xFFE9E9E9)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 76),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _korean,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.24,
              letterSpacing: -1,
              color: Palette.grey900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _korean,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.2,
              color: Palette.grey600,
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: FittedBox(child: _PhoneMockup(screen: screen)),
                ),
                if (badge case final badge?) Positioned(top: 486, child: badge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.screen});

  final Widget screen;

  static const _bezel = 13.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).copyWith(
      size: _screen,
      padding: const EdgeInsets.only(top: 62, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 62, bottom: 34),
      viewInsets: EdgeInsets.zero,
      textScaler: TextScaler.noScaling,
    );

    return Container(
      width: _screen.width + _bezel * 2,
      height: _screen.height + _bezel * 2,
      padding: const EdgeInsets.all(_bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(68),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(55),
        child: SizedBox.fromSize(
          size: _screen,
          child: Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(data: media, child: screen),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 54,
                child: _StatusBar(),
              ),
              Positioned(
                top: 11,
                left: (_screen.width - 124) / 2,
                child: Container(
                  width: 124,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(40, 18, 30, 0),
      child: Row(
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Palette.grey900,
            ),
          ),
          Spacer(),
          Icon(Icons.signal_cellular_alt, size: 18, color: Palette.grey900),
          SizedBox(width: 5),
          Icon(Icons.wifi, size: 18, color: Palette.grey900),
          SizedBox(width: 5),
          Icon(Icons.battery_full, size: 20, color: Palette.grey900),
        ],
      ),
    );
  }
}

/// 공유 시트에서 Townloader 를 고르는 장면을 암시하는 카드.
class _ShareBadge extends StatelessWidget {
  const _ShareBadge({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(22),
        // 테스트 렌더러는 그림자를 흐리게 그리지 못해 테두리로 띄운다.
        border: Border.all(color: Palette.grey300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(_img('icon'), width: 48, height: 48),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Townloader',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                hint,
                style: const TextStyle(
                  fontFamily: _korean,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Palette.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 이미지·폰트 ───────────────────────────────────────────────────────────────

const _imageDir = 'test/store/images';

/// 가짜 URL. 테스트의 HTTP 는 막혀 있으므로 이미지 캐시에 미리 넣어 둔다.
String _img(String name) => 'https://img.townloader.test/$name';

Future<void> _primeImages(WidgetTester tester) async {
  final files = <String, String>{
    for (final entity in Directory(_imageDir).listSync())
      if (entity is File && entity.path.endsWith('.jpg'))
        entity.uri.pathSegments.last.replaceAll('.jpg', ''): entity.path,
    'icon':
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
  };

  await tester.runAsync(() async {
    for (final MapEntry(key: name, value: path) in files.entries) {
      final codec = await ui.instantiateImageCodec(
        await File(path).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      final info = ImageInfo(image: frame.image);
      PaintingBinding.instance.imageCache.putIfAbsent(
        NetworkImage(_img(name)),
        () => OneFrameImageStreamCompleter(SynchronousFuture(info)),
      );
    }
  });
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load(AppTheme.fontFamily, [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/Urbanist-$weight.ttf',
  ]);
  await load(_korean, [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'test/store/fonts/Pretendard-$weight.otf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

// ── 가짜 의존성 ───────────────────────────────────────────────────────────────

/// 응답을 끝내 돌려주지 않아 다운로드가 '진행 중' 에 머문다.
class _HangingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future;
}

class _StoreRepository extends IgRepository {
  _StoreRepository() : super(HikerClient(readApiKey: () => 'store'));

  @override
  Future<ResolveResult> resolve(IgLink link) async => ResolveResult(
    title:
        '@${_user.username} · ${_carousel.kind.localizedLabel(S.current.isKo)}',
    posts: [_carousel],
    user: _user,
  );

  @override
  Future<IgUser> fetchUser(String username) async => _user;

  @override
  Future<MediaPage> fetchUserMedias(String userId, {String? cursor}) async =>
      MediaPage(posts: _gridPosts);

  @override
  Future<MediaPage> fetchUserClips(String userId, {String? cursor}) async =>
      MediaPage(
        posts: _gridPosts.where((post) => post.kind == PostKind.reel).toList(),
      );

  @override
  Future<List<IgPost>> fetchUserStories(String username) async => const [];
}

/// 테스트는 키를 심지 않고 돌기 때문에, 키가 있는 빌드처럼 보이게 한다.
class _StoreSettings extends SettingsController {
  _StoreSettings(super.store);

  @override
  String? get apiKey => 'store';
}

class _MemoryStore extends SettingsStore {
  @override
  Future<SettingsBackend> get backend async => SettingsBackend.keychain;
  @override
  Future<String?> readApiKey() async => null;
  @override
  Future<bool> writeApiKey(String? value) async => true;
  @override
  Future<QualityPreference> readQuality() async => QualityPreference.best;
  @override
  Future<bool> writeQuality(QualityPreference value) async => true;
  @override
  Future<bool> readSaveToGallery() async => true;
  @override
  Future<bool> writeSaveToGallery(bool value) async => true;
}

// ── 예시 데이터 (모두 지어낸 계정) ────────────────────────────────────────────

final _user = IgUser(
  pk: '4821001',
  username: 'marks.photo',
  fullName: "Mark's Photo",
  profilePicUrl: _img('avatar'),
  isVerified: true,
  mediaCount: 1284,
  followerCount: 482000,
  followingCount: 312,
  biography: '매일 한 장, 세상의 풍경',
);

final _friend = IgUser(
  pk: '5930012',
  username: 'kim.films',
  fullName: 'Kim Films',
  profilePicUrl: _img('avatar2'),
  mediaCount: 312,
  followerCount: 28400,
);

IgItem _photo(String name) => IgItem(
  id: name,
  kind: AssetKind.photo,
  thumbnailUrl: _img(name),
  variants: [
    IgAsset(kind: AssetKind.photo, url: _img(name), width: 1080, height: 1350),
  ],
);

IgItem _video(String name, double seconds) => IgItem(
  id: name,
  kind: AssetKind.video,
  thumbnailUrl: _img(name),
  durationSeconds: seconds,
  variants: [
    IgAsset(
      kind: AssetKind.video,
      url: 'https://video.townloader.test/$name.mp4',
      width: 1080,
      height: 1920,
      bandwidth: 2100000,
      durationSeconds: seconds,
    ),
  ],
);

IgPost get _carousel => IgPost(
  pk: '3973939000000000001',
  code: 'DchLnq8E21N',
  kind: PostKind.carousel,
  user: _user,
  caption: S.current.isKo
      ? '돌로미티 트레킹 3일차. 구름이 걷히는 순간을 다섯 장에 담았어요.'
      : 'Day 3 in the Dolomites. Five frames of the clouds breaking.',
  takenAt: DateTime(2026, 9, 14),
  likeCount: 48200,
  commentCount: 612,
  items: [
    _photo('p1018'),
    _photo('p1036'),
    _photo('p1043'),
    _photo('p1044'),
    _photo('p1039'),
  ],
);

List<IgPost> get _sharedPosts => [
  IgPost(
    pk: '3974000000000000002',
    code: 'DcxReel0001',
    kind: PostKind.reel,
    user: _friend,
    caption: '해 질 녘 한강',
    takenAt: DateTime(2026, 9, 20),
    items: [_video('p1047', 38)],
  ),
  IgPost(
    pk: '3974000000000000003',
    code: 'DcxPost0002',
    kind: PostKind.carousel,
    user: _user,
    takenAt: DateTime(2026, 9, 19),
    items: [_photo('p1015'), _photo('p1050'), _photo('p1057')],
  ),
  IgPost(
    pk: '3974000000000000004',
    code: 'DcxPost0003',
    kind: PostKind.photo,
    user: _user,
    takenAt: DateTime(2026, 9, 18),
    items: [_photo('p1080')],
  ),
];

final _gridPosts = <IgPost>[
  for (final (index, name) in [
    'p1015', 'p1040', 'p1069', 'p1074', 'p1084', 'p110', //
    'p1062', 'p1057', 'p1050', 'p1047', 'p1039', 'p1080',
  ].indexed)
    IgPost(
      pk: '39750000000000000$index',
      code: 'DcGrid$index',
      kind: index % 3 == 1 ? PostKind.reel : PostKind.photo,
      user: _user,
      takenAt: DateTime(2026, 9, 20 - index),
      items: [index % 3 == 1 ? _video(name, 24.0 + index) : _photo(name)],
    ),
];
