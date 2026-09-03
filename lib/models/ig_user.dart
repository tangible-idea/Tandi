/// Instagram 계정 정보. HikerAPI 의 user 객체를 앱에서 쓰는 형태로 좁힌 모델.
class IgUser {
  const IgUser({
    required this.pk,
    required this.username,
    this.fullName = '',
    this.profilePicUrl,
    this.isPrivate = false,
    this.isVerified = false,
    this.mediaCount,
    this.followerCount,
    this.followingCount,
    this.biography,
  });

  final String pk;
  final String username;
  final String fullName;
  final String? profilePicUrl;
  final bool isPrivate;
  final bool isVerified;
  final int? mediaCount;
  final int? followerCount;
  final int? followingCount;
  final String? biography;

  /// HikerAPI 는 엔드포인트에 따라 `pk` 를 정수로도 문자열로도 돌려준다.
  /// 큰 정수가 JS 안전 범위를 넘는 경우가 있어 항상 문자열로 다룬다.
  static String? _asId(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static IgUser? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final pk = _asId(json['pk']) ?? _asId(json['id']);
    final username = json['username'] as String?;
    if (pk == null || username == null) return null;

    return IgUser(
      pk: pk,
      username: username,
      fullName: (json['full_name'] as String?) ?? '',
      profilePicUrl:
          (json['profile_pic_url_hd'] as String?) ??
          (json['profile_pic_url'] as String?),
      isPrivate: json['is_private'] == true,
      isVerified: json['is_verified'] == true,
      mediaCount: (json['media_count'] as num?)?.toInt(),
      followerCount: (json['follower_count'] as num?)?.toInt(),
      followingCount: (json['following_count'] as num?)?.toInt(),
      biography: json['biography'] as String?,
    );
  }
}
