import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/ig_url.dart';
import '../services/download_service.dart';
import '../state/resolve_controller.dart';
import '../state/settings_controller.dart';
import 'widgets/post_card.dart';
import 'widgets/state_views.dart';

/// 링크를 붙여넣어 게시물을 받는 기본 화면.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSettings,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenSettings;
  final void Function(String username) onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('다운로드')),
      body: SafeArea(
        child: Column(
          children: [
            _inputBar(context),
            const Divider(height: 1),
            Expanded(
              child: settings.isLoaded && !settings.hasApiKey
                  ? _noApiKeyView()
                  : _resultArea(context),
            ),
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
                        hintText: 'instagram.com/reel/... 또는 @계정명',
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
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: resolve.isLoading ? null : _submit,
                    child: resolve.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('가져오기'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '게시물 · 릴스 · 캐러셀 · 스토리 · 하이라이트 링크를 지원합니다.',
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

    if (resolve.isLoading) {
      return const LoadingView(label: '인스타그램에서 정보를 가져오는 중…');
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
        actionLabel: username != null
            ? '@$username 열기'
            : (resolve.needsApiKey ? '설정 열기' : null),
        onAction: username != null
            ? () => widget.onOpenProfile(username)
            : (resolve.needsApiKey ? widget.onOpenSettings : null),
      );
    }

    final result = resolve.result;
    if (result == null) {
      return const MessageView(
        icon: Icons.download_for_offline_outlined,
        title: '링크를 붙여넣어 주세요',
        description: '인스타그램 앱이나 브라우저에서 복사한 주소를 위에 붙여넣으면\n'
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
                    onPressed: () {
                      final settings = context.read<SettingsController>();
                      final count = context
                          .read<DownloadService>()
                          .enqueueAll(
                            result.posts,
                            quality: settings.quality,
                          );
                      _toast('$count개 파일을 다운로드에 추가했습니다.');
                    },
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

  Widget _noApiKeyView() => MessageView(
    icon: Icons.key_outlined,
    title: 'HikerAPI 키가 필요합니다',
    description: '이 앱은 HikerAPI 를 통해 인스타그램 미디어 정보를 가져옵니다.\n'
        '설정에서 액세스 키를 입력해 주세요.',
    actionLabel: '설정 열기',
    onAction: widget.onOpenSettings,
  );

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;

    _controller.text = text;
    setState(() {});
    if (mounted) _submit();
  }

  void _submit() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final link = IgUrlParser.parse(input);
    // 프로필은 해석 대상이 아니라 프로필 화면에서 다룬다.
    if (link.type == IgLinkType.profile && link.username != null) {
      widget.onOpenProfile(link.username!);
      return;
    }

    _focusNode.unfocus();
    context.read<ResolveController>().resolve(input);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
