/// UI 표시에 쓰는 값 포맷 헬퍼.
class Fmt {
  Fmt._();

  /// `12.4 MB` 형태. 크기를 모르면 빈 문자열.
  static String bytes(int? value) {
    if (value == null || value <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = value.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = (unit == 0 || size >= 100) ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }

  /// `1:05` 형태의 재생 시간.
  static String duration(double? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final total = seconds.round();
    final minutes = total ~/ 60;
    final rest = total % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  /// `1.2만`, `340만` 같은 축약 수치.
  static String count(int? value) {
    if (value == null || value < 0) return '';
    if (value < 10000) return _withCommas(value);
    final man = value / 10000;
    if (man < 10) return '${man.toStringAsFixed(1)}만';
    if (man < 10000) return '${man.round()}만';
    return '${(man / 10000).toStringAsFixed(1)}억';
  }

  static String _withCommas(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  /// `2026. 8. 30.` 형태의 날짜.
  static String date(DateTime? value) {
    if (value == null) return '';
    return '${value.year}. ${value.month}. ${value.day}.';
  }
}
