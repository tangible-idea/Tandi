import 'ig_asset.dart';
import 'ig_user.dart';

/// 게시물의 종류. HikerAPI 의 `media_type` 과 `product_type` 을 합쳐서 판정한다.
enum PostKind { photo, video, reel, carousel, story }

extension PostKindLabel on PostKind {
  String get label => switch (this) {
    PostKind.photo => '사진',
    PostKind.video => '동영상',
    PostKind.reel => '릴스',
    PostKind.carousel => '캐러셀',
    PostKind.story => '스토리',
  };
}

/// 게시물 안의 항목 하나. 캐러셀이면 슬라이드 한 장, 그 외에는 항목이 하나뿐이다.
class IgItem {
  IgItem({
    required this.id,
    required this.kind,
    required List<IgAsset> variants,
    this.thumbnailUrl,
    this.durationSeconds,
  }) : variants = List.unmodifiable(
         [...variants]
           ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore)),
       );

  final String id;
  final AssetKind kind;

  /// 화질 내림차순으로 정렬된 다운로드 후보들.
  final List<IgAsset> variants;
  final String? thumbnailUrl;
  final double? durationSeconds;

  bool get isVideo => kind == AssetKind.video;
  bool get hasAssets => variants.isNotEmpty;

  IgAsset? get best => variants.isEmpty ? null : variants.first;
  IgAsset? get smallest => variants.isEmpty ? null : variants.last;
}

/// 다운로드 대상이 되는 게시물 하나.
class IgPost {
  IgPost({
    required this.pk,
    required this.kind,
    required List<IgItem> items,
    this.code,
    this.user,
    this.caption,
    this.takenAt,
    this.likeCount,
    this.viewCount,
    this.playCount,
    this.commentCount,
  }) : items = List.unmodifiable(items);

  final String pk;
  final String? code;
  final PostKind kind;
  final IgUser? user;
  final String? caption;
  final DateTime? takenAt;
  final int? likeCount;
  final int? viewCount;
  final int? playCount;
  final int? commentCount;
  final List<IgItem> items;

  /// 다운로드 가능한 항목이 하나도 없으면 화면에 실패로 표시한다.
  bool get hasDownloadableAssets => items.any((item) => item.hasAssets);

  String get authorName => user?.username ?? 'instagram';

  String? get permalink {
    final c = code;
    if (c == null) return null;
    return switch (kind) {
      PostKind.reel => 'https://www.instagram.com/reel/$c/',
      PostKind.story => 'https://www.instagram.com/stories/$authorName/$pk/',
      _ => 'https://www.instagram.com/p/$c/',
    };
  }

  /// 목록 화면에서 대표로 보여줄 썸네일.
  String? get coverUrl {
    for (final item in items) {
      final thumb = item.thumbnailUrl;
      if (thumb != null) return thumb;
      if (!item.isVideo) {
        final asset = item.best;
        if (asset != null) return asset.url;
      }
    }
    return null;
  }
}
