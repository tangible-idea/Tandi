/// 실제로 내려받을 수 있는 파일 하나. 같은 미디어라도 해상도별로 여러 개가 존재한다.
enum AssetKind { photo, video }

class IgAsset {
  const IgAsset({
    required this.kind,
    required this.url,
    this.width,
    this.height,
    this.durationSeconds,
    this.bandwidth,
  });

  final AssetKind kind;
  final String url;
  final int? width;
  final int? height;
  final double? durationSeconds;

  /// 영상 변형의 비트레이트. 폭/높이가 같은 변형끼리 순위를 가를 때 쓴다.
  final int? bandwidth;

  bool get isVideo => kind == AssetKind.video;

  String get fileExtension => isVideo ? 'mp4' : 'jpg';

  /// 화질이 좋을수록 큰 값. 해상도 정보가 없으면 비트레이트로, 그것도 없으면 0.
  int get qualityScore {
    final w = width;
    final h = height;
    if (w != null && h != null && w > 0 && h > 0) return w * h;
    return bandwidth ?? 0;
  }

  /// UI 에 보여줄 화질 표기. 정보가 없으면 null.
  String? get resolutionLabel {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return '$w×$h';
  }
}
