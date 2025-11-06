import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSettingPage extends StatelessWidget {
  const LanguageSettingPage({super.key});

  // 顏色
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF4DB6AC);
  final Color _lightColor = const Color(0xFFF7F9FC);

  // (移除了 initState, _loadLanguage, _saveLanguage, _showRestartDialog, _isLoading)
  // (Provider 會處理這一切)

  @override
  Widget build(BuildContext context) {
    //取得 Provider 和 翻譯字典
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    //從 Provider 取得當前語言 (例如 'zh_TW')
    final String selectedLanguage = localeProvider.localeToCode(
      localeProvider.locale,
    );

    return Scaffold(
      appBar: AppBar(
        // 使用翻譯字典
        title: Text(
          l10n.languageSettingsTitle, // "語言設定"
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      backgroundColor: _lightColor,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            l10n.selectYourLanguage,
            style: TextStyle(
              color: _primaryColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // 將 context 和 當前語言 傳遞給 _buildLanguageTile
                _buildLanguageTile(
                  context,
                  'English (US)',
                  'en_US',
                  selectedLanguage,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile(
                  context,
                  '繁體中文 (台灣)',
                  'zh_TW',
                  selectedLanguage,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile(
                  context,
                  'Bahasa Indonesia',
                  'id_ID',
                  selectedLanguage,
                ), // (我把"印尼文"改成"Bahasa Indonesia")
              ],
            ),
          ),
          // ... (提示框保持不變) ...
        ],
      ),
    );
  }

  /// 提取的 RadioListTile 建立函數
  Widget _buildLanguageTile(
    BuildContext context,
    String title,
    String languageCode,
    String selectedLanguage,
  ) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
      ),
      value: languageCode,
      groupValue: selectedLanguage, //groupValue 來自 Provider
      //關鍵：onChanged 現在是命令 Provider 去設定語言
      onChanged: (String? value) {
        if (value != null && value != selectedLanguage) {
          context.read<LocaleProvider>().setLocale(value);
        }
      },
      activeColor: _accentColor,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
