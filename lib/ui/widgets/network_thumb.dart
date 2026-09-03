import 'package:flutter/material.dart';

/// 인스타그램 CDN 썸네일을 안전하게 그린다.
///
/// CDN URL 은 서명이 만료되면 403 을 돌려주므로, 실패했을 때 깨진 아이콘 대신
/// 자리 표시자를 보여주는 것이 중요하다.
class NetworkThumb extends StatelessWidget {
  const NetworkThumb({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
  });

  final String? url;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final source = url;

    if (source == null || source.isEmpty) return _placeholder(scheme);

    return Image.network(
      source,
      fit: fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(scheme),
    );
  }

  Widget _placeholder(ColorScheme scheme) => ColoredBox(
    color: scheme.surfaceContainerHighest,
    child: Center(
      child: Icon(icon, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    ),
  );
}
