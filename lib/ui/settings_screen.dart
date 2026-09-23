import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/file_saver.dart';
import '../services/settings_store.dart';
import '../state/settings_controller.dart';

/// 다운로드 동작을 설정하는 화면.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                          subtitle: const Text('끄면 앱 문서 폴더에만 저장됩니다.'),
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
                          ? '다운로드 폴더 아래 Townloader/<계정명>/'
                          : settings.saveToGallery
                          ? '사진 앱의 Townloader 앨범'
                          : '앱 문서 폴더의 Townloader 폴더',
                    ),
                  ),
                ),

                const SizedBox(height: 16),
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
