import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/ig_repository.dart';
import '../data/ig_url.dart';
import '../models/media_source.dart';
import '../services/download_service.dart';
import '../state/resolve_controller.dart';
import '../state/settings_controller.dart';
import 'widgets/post_card.dart';
import 'widgets/state_views.dart';

/// 링크를 붙여넣어 게시물을 받는 기본 화면.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenProfile,
    required this.onOpenDownloads,
  });

  final void Function(String username) onOpenProfile;

  /// 큐에 파일을 넣은 뒤 진행 상황을 보여 주기 위해 목록 탭으로 넘어간다.
  final VoidCallback onOpenDownloads;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('다운로드')),
      body: SafeArea(
        child: Column(
          children: [
            _inputBar(context),
            const Divider(height: 1),
            Expanded(child: _resultArea(context)),
          ],
        ),
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    final resolve = context.watch<ResolveController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'instagram.com/... 또는 threads.net/...',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '붙여넣기',
                              icon: const Icon(Icons.content_paste),
                              onPressed: _pasteFromClipboard,
                            ),
                            if (_controller.text.isNotEmpty)
                              IconButton(
                                tooltip: '지우기',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.clear();
                                  context.read<ResolveController>().clear();
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 입력창과 같은 높이의 원형 아이콘 버튼 하나로 제출한다.
                  IconButton.filled(
                    tooltip: '가져오기',
                    // 테마의 IconButton 전경색(onSurface)이 filled 변형에도 덮여
                    // 검은 바탕에 검은 아이콘이 되므로 여기서 되돌린다.
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: resolve.isLoading ? null : _submit,
                    icon: resolve.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '인스타그램 (게시물·릴스·스토리·하이라이트) 및 Threads 링크를 지원합니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultArea(BuildContext context) {
    final resolve = context.watch<ResolveController>();
    final settings = context.watch<SettingsController>();

    if (resolve.isLoading) {
      final isThreads = resolve.link?.source == MediaSource.threads;
      return LoadingView(
        label: isThreads ? 'Threads에서 정보를 가져오는 중…' : '미디어 정보를 가져오는 중…',
      );
    }

    final error = resolve.error;
    if (error != null) {
      // 프로필 링크를 넣은 경우에는 오류로 끝내지 말고 프로필 탭으로 안내한다.
      final username = resolve.link?.type == IgLinkType.profile
          ? resolve.link?.username
          : null;

      return MessageView(
        isError: true,
        icon: username != null
            ? Icons.account_circle_outlined
            : Icons.error_outline,
        title: username != null ? '@$username 프로필 링크입니다' : '가져오지 못했습니다',
        description: username != null
            ? '프로필의 게시물을 한꺼번에 보려면 프로필 화면에서 여세요.'
            : error,
        actionLabel: username != null ? '@$username 열기' : null,
        onAction: username != null
            ? () => widget.onOpenProfile(username)
            : null,
      );
    }

    final result = resolve.result;
    if (result == null) {
      return const MessageView(
        icon: Icons.download_for_offline_outlined,
        title: '링크를 붙여넣어 주세요',
        description:
            '인스타그램 앱이나 Threads에서 복사한 주소를 위에 붙여넣으면\n'
            '사진과 동영상을 원본 화질로 내려받습니다.',
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (result.posts.length > 1)
                  TextButton.icon(
                    onPressed: () => _downloadAll(result),
                    icon: const Icon(Icons.download),
                    label: const Text('전체 받기'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final post in result.posts) ...[
              PostCard(post: post),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;

    _controller.text = text;
    setState(() {});
    if (mounted) _submit();
  }

  /// 다른 앱에서 공유한 링크를 받아 곧바로 해석하고 전부 다운로드에 넣는다.
  void handleSharedLink(String link) {
    _controller.text = link;
    setState(() {});
    _submit(autoDownload: true);
  }

  /// [autoDownload] 면 해석이 끝나는 대로 결과 전체를 다운로드 큐에 넣는다.
  Future<void> _submit({bool autoDownload = false}) async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final link = IgUrlParser.parse(input);
    // 프로필은 해석 대상이 아니라 프로필 화면에서 다룬다.
    if (link.type == IgLinkType.profile && link.username != null) {
      widget.onOpenProfile(link.username!);
      return;
    }

    _focusNode.unfocus();
    final resolve = context.read<ResolveController>();
    await resolve.resolve(input);

    // 실패하면 오류 화면이 그대로 남아 이유를 보여 준다.
    final result = resolve.result;
    if (!autoDownload || !mounted || result == null) return;
    _downloadAll(result);
  }

  void _downloadAll(ResolveResult result) {
    // 입력창에 포커스가 남아 있으면 키보드가 목록을 가리므로 먼저 내린다.
    FocusScope.of(context).unfocus();

    final settings = context.read<SettingsController>();
    final count = context.read<DownloadService>().enqueueAll(
      result.posts,
      quality: settings.quality,
    );
    _toast('$count개 파일을 다운로드에 추가했습니다.');
    // 큐에 실제로 들어간 게 있을 때만 넘어간다.
    if (count > 0) widget.onOpenDownloads();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
