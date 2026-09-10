import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/file_saver.dart';
import '../services/settings_store.dart';
import '../state/settings_controller.dart';

/// API 키와 다운로드 동작을 설정하는 화면.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _keyController;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(
      text: context.read<SettingsController>().apiKey ?? '',
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle(context, 'HikerAPI (인스타그램)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _keyController,
                          obscureText: _obscured,
                          decoration: InputDecoration(
                            labelText: '액세스 키',
                            hintText: 'HikerAPI 대시보드의 access key',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscured
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscured = !_obscured),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                final saved = await settings.setApiKey(
                                  _keyController.text,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        saved
                                            ? '키를 저장했습니다.'
                                            : '키체인에 저장하지 못했습니다. 이번 실행 동안만 적용됩니다.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              },
                              child: const Text('저장'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse('https://hikerapi.com/'),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: const Text('키 발급받기'),
                            ),
                            const Spacer(),
                            if (settings.hasApiKey)
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '설정됨',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          switch (settings.backend) {
                            SettingsBackend.keychain =>
                              '키는 기기 키체인에 보관되며 HikerAPI 외에는 전송되지 않습니다.',
                            SettingsBackend.containerFile =>
                              '이 빌드는 키체인을 쓸 수 없어(개발자 서명 없음) 키를 앱 컨테이너 안의 '
                                  '파일에 저장합니다. 다른 앱은 읽을 수 없지만 키체인만큼 보호되지는 '
                                  '않습니다.',
                          },
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: settings.backend == SettingsBackend.keychain
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'HikerAPI는 인스타그램 미디어 조회에만 사용됩니다. Threads 다운로드는 키 없이 바로 이용하실 수 있습니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'HikerAPI 는 호출 건수만큼 과금되므로 목록을 여러 번 새로 고치면 비용이 늘어납니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle(context, '다운로드'),
                Card(
                  child: Column(
                    children: [
                      RadioGroup<QualityPreference>(
                        groupValue: settings.quality,
                        onChanged: (value) {
                          if (value != null) settings.setQuality(value);
                        },
                        child: Column(
                          children: [
                            for (final option in QualityPreference.values)
                              RadioListTile<QualityPreference>(
                                value: option,
                                title: Text(option.label),
                                subtitle: Text(
                                  option == QualityPreference.best
                                      ? '인스타그램이 제공하는 가장 높은 해상도로 받습니다.'
                                      : '해상도가 가장 낮은 파일로 받습니다. 빠르게 확인할 때 유용합니다.',
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!MediaFileSaver.isDesktop) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          value: settings.saveToGallery,
                          onChanged: settings.setSaveToGallery,
                          title: const Text('사진 앱에 저장'),
                          subtitle: const Text(
                            '끄면 앱 문서 폴더에만 저장됩니다.',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('저장 위치'),
                    subtitle: Text(
                      MediaFileSaver.isDesktop
                          ? '다운로드 폴더 아래 Tandi/<계정명>/'
                          : settings.saveToGallery
                          ? '사진 앱의 Tandi 앨범'
                          : '앱 문서 폴더의 Tandi 폴더',
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle(context, '알아두기'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '공개 계정의 미디어만 가져올 수 있습니다. 내려받은 파일은 원저작자에게 저작권이 있으므로, '
                      '재배포하거나 상업적으로 쓰기 전에 권리를 확인해 주세요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
