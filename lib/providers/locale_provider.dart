import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // 預設語言
  Locale _locale = const Locale('zh', 'TW');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLanguage(); // 建立時自動載入
  }

  /// 從 SharedPreferences 載入設定
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String languageCode = prefs.getString('appLanguage') ?? 'zh_TW';

    _locale = _codeToLocale(languageCode);
    notifyListeners(); // 通知監聽者更新
  }

  /// 供外部呼叫，用來設定新語言
  Future<void> setLocale(String languageCode) async {
    // 1. 儲存到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', languageCode);

    // 2. 轉換為 Locale 物件
    _locale = _codeToLocale(languageCode);

    // 3. 關鍵：通知所有正在監聽的 Widget 更新！
    notifyListeners();
  }

  /// 內部輔助函數：將字串 'zh_TW' 轉為 Locale('zh', 'TW')
  Locale _codeToLocale(String code) {
    switch (code) {
      case 'en_US':
        return const Locale('en', 'US');
      case 'zh_CN':
        return const Locale('zh', 'CN');
      case 'id_ID':
        return const Locale('id'); // 印尼文的 locale code 是 'id'
      case 'zh_TW':
      default:
        return const Locale('zh', 'TW');
    }
  }

  /// 輔助函數：將 Locale('zh', 'TW') 轉回 'zh_TW'
  String localeToCode(Locale locale) {
    if (locale.countryCode == 'US') return 'en_US';
    if (locale.countryCode == 'CN') return 'zh_CN';
    if (locale.languageCode == 'id') return 'id_ID';
    return 'zh_TW';
  }
}
