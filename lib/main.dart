import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/screens/LoginPage.dart';
import '/screens/home_page.dart';

void main() async {
  // 確保 Flutter Widgets 已綁定，才能使用 SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeMate',
      theme: ThemeData(
        // 使用您在其他頁面定義的主顏色
        primaryColor: const Color(0xFF1F3D5B),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: const Color(0xFF5E91B3)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 應用程式的起始點改為 AuthWrapper，它負責檢查登入狀態
      home: const AuthWrapper(),
    );
  }
}

// AuthWrapper 負責在應用程式啟動時檢查並導向正確的頁面
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // 用於儲存自動登入檢查的結果
  Future<Map<String, String?>>? _initialization;

  @override
  void initState() {
    super.initState();
    // 應用程式啟動時，立即檢查登入狀態
    _initialization = _checkLoginStatus();
  }

  // 檢查 SharedPreferences 中的登入狀態和使用者資訊
  Future<Map<String, String?>> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // 檢查是否有 isLoggedIn 旗標，或檢查 userId 是否存在
    final userId = prefs.getString('userId');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && userId != null && userId.isNotEmpty) {
      // 讀取儲存的使用者資訊
      return {
        'userId': userId,
        'userName': prefs.getString('userName'),
        'userEmail': prefs.getString('userEmail'),
      };
    } else {
      // 未登入
      return {'userId': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _initialization,
      builder: (context, snapshot) {
        // 1. 連線中：顯示載入畫面
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 可以在此處放置您的啟動畫面或載入指示器
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. 資料就緒：檢查 userId
        final userId = snapshot.data?['userId'];

        if (userId != null && userId.isNotEmpty) {
          // 已登入：導航到 HomePage
          final userName = snapshot.data?['userName'] ?? "";
          final userEmail = snapshot.data?['userEmail'] ?? "";
          return HomePage(userId: userId, userName: userName, email: userEmail);
        } else {
          // 未登入或檢查失敗：導航到 LoginPage
          return const LoginPage();
        }
      },
    );
  }
}
