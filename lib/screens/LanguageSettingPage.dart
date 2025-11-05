import 'package:flutter/material.dart';

class LanguageSettingPage extends StatefulWidget {
  const LanguageSettingPage({super.key});

  @override
  State<LanguageSettingPage> createState() => _LanguageSettingPageState();
}

class _LanguageSettingPageState extends State<LanguageSettingPage> {
  // 狀態變數，僅用於在 UI 上顯示哪個按鈕被選中
  // 預設選中 'zh_TW'
  String _selectedLanguage = 'zh_TW';

  // 🎨 統一定義顏色 (與您 App 風格一致)
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF4DB6AC);
  final Color _lightColor = const Color(0xFFF7F9FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "語言設定",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // 透明 AppBar
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor), // 返回按鈕顏色
      ),
      backgroundColor: _lightColor, // 匹配 App 背景色
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "選擇您的偏好語言",
            style: TextStyle(
              color: _primaryColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // 使用 Card 包裹選項，風格更一致
          Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _buildLanguageTile('English (US)', 'en_US'),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile('繁體中文 (台灣)', 'zh_TW'),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile(
                  '简体中文 (中国)', // 範例
                  'zh_CN',
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 提示資訊框
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _primaryColor.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _primaryColor.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "（此為 UI 範本）設定將在重新啟動應用程式後生效。",
                    style: TextStyle(
                      color: _primaryColor.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5, // 增加行高
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 提取的 RadioListTile 建立函數
  Widget _buildLanguageTile(String title, String languageCode) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
      ),
      value: languageCode,
      groupValue: _selectedLanguage,
      // ⚠️ 關鍵：onChanged 僅更新畫面上的狀態 (setState)
      // 並沒有呼叫 SharedPreferences 來儲存
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
      activeColor: _accentColor,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
