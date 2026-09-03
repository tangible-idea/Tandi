import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/download_service.dart';
import '../services/file_saver.dart';
import 'format.dart';
import 'widgets/network_thumb.dart';
import 'widgets/state_views.dart';

/// 진행 중이거나 끝난 다운로드 목록.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadService>();
    final items = downloads.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('다운로드 목록'),
        actions: [
          if (items.any((item) => item.status.isFinished))
            TextButton.icon(
              onPressed: downloads.clearFinished,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: const Text('완료 항목 정리'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? const MessageView(
                icon: Icons.download_done_outlined,
                title: '아직 받은 항목이 없습니다',
                description: '다운로드 탭에서 링크를 넣거나\n프로필에서 항목을 눌러 담아 보세요.',
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _DownloadTile(item: items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloads = context.read<DownloadService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: NetworkThumb(
                  url: item.thumbnailUrl,
                  icon: item.asset.isVideo
                      ? Icons.movie_outlined
                      : Icons.image_outlined,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusLine(context),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _trailing(context, downloads),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(BuildContext context) {
    final theme = Theme.of(context);

    switch (item.status) {
      case DownloadStatus.queued:
        return Text(
          '대기 중',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );

      case DownloadStatus.running:
        final received = Fmt.bytes(item.receivedBytes);
        final total = Fmt.bytes(item.totalBytes);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total.isEmpty ? received : '$received / $total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case DownloadStatus.completed:
        final location = item.savedLocation;
        return Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 15,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                location?.description ?? '완료',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );

      case DownloadStatus.failed:
        return Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 15,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                item.errorMessage ?? '실패',
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        );

      case DownloadStatus.canceled:
        return Text(
          '취소됨',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _trailing(BuildContext context, DownloadService downloads) {
    if (item.isActive) {
      return IconButton(
        tooltip: '취소',
        icon: const Icon(Icons.close),
        onPressed: () => downloads.cancel(item.id),
      );
    }

    if (item.status == DownloadStatus.completed) {
      final path = item.savedLocation?.filePath;
      // 모바일에서 앨범에 넣은 경우에는 복사할 경로가 없다.
      if (path == null) return const SizedBox(width: 8);
      return IconButton(
        tooltip: MediaFileSaver.isDesktop ? '경로 복사' : '경로 복사',
        icon: const Icon(Icons.folder_open_outlined),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: path));
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('저장 경로를 복사했습니다.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
      );
    }

    return IconButton(
      tooltip: '다시 시도',
      icon: const Icon(Icons.refresh),
      onPressed: () => downloads.retry(item.id),
    );
  }
}
