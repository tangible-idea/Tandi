import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/ig_post.dart';
import '../../services/download_service.dart';
import '../../state/settings_controller.dart';
import '../format.dart';
import 'download_options_sheet.dart';
import 'network_thumb.dart';

/// 해석된 게시물 하나를 미리보기와 다운로드 버튼으로 보여준다.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final IgPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          _preview(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.caption != null) ...[
                  Text(
                    post.caption!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                _stats(context),
                const SizedBox(height: 14),
                _actions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final user = post.user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: NetworkThumb(
                  url: user?.profilePicUrl,
                  icon: Icons.person_outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${post.authorName}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (user?.isVerified ?? false) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                Text(
                  [
                    post.kind.label,
                    if (post.items.length > 1) '${post.items.length}개 항목',
                    Fmt.date(post.takenAt),
                  ].where((text) => text.isNotEmpty).join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (post.permalink != null)
            IconButton(
              tooltip: '링크 복사',
              icon: const Icon(Icons.link, size: 20),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: post.permalink!),
                );
                if (context.mounted) {
                  _toast(context, '링크를 복사했습니다.');
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    // 캐러셀은 가로로 넘겨 보고, 단일 항목은 크게 한 장만 보여준다.
    if (post.items.length > 1) {
      return SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: post.items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = post.items[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkThumb(url: item.thumbnailUrl),
                    if (item.isVideo)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    final item = post.items.first;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkThumb(url: item.thumbnailUrl),
          if (item.isVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          if (item.durationSeconds != null && item.durationSeconds! > 0)
            Positioned(
              right: 8,
              bottom: 8,
              child: _pill(Fmt.duration(item.durationSeconds)),
            ),
        ],
      ),
    );
  }

  Widget _stats(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <(IconData, String)>[
      if ((post.likeCount ?? 0) > 0)
        (Icons.favorite_border, Fmt.count(post.likeCount)),
      if ((post.commentCount ?? 0) > 0)
        (Icons.mode_comment_outlined, Fmt.count(post.commentCount)),
      if ((post.playCount ?? post.viewCount ?? 0) > 0)
        (Icons.play_arrow_outlined, Fmt.count(post.playCount ?? post.viewCount)),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      children: [
        for (final (icon, value) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final hasVariantChoice = post.items.any(
      (item) => item.variants.length > 1,
    );

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              final settings = context.read<SettingsController>();
              final count = context.read<DownloadService>().enqueuePost(
                post,
                quality: settings.quality,
              );
              _toast(context, '$count개 파일을 다운로드에 추가했습니다.');
            },
            icon: const Icon(Icons.download),
            label: Text(
              post.items.length > 1 ? '전체 ${post.items.length}개 받기' : '다운로드',
            ),
          ),
        ),
        if (hasVariantChoice) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: '화질 선택',
            icon: const Icon(Icons.tune),
            onPressed: () => DownloadOptionsSheet.show(context, post),
          ),
        ],
      ],
    );
  }

  static Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
  );

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
