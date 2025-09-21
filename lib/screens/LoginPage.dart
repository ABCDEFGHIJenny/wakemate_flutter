import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'RegisterPage.dart'; // 導入 RegisterPage
import 'package:intl/intl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 保留所有文字輸入框控制器
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // 預設測試帳號
    nameController.text = "1414";
    emailController.text = "1414@gmail.com";
    passwordController.text = "1414"; // 改成實際密碼
  }

  // 處理使用者登入的非同步函數
  Future<void> _loginUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 檢查所有欄位是否都已輸入
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("請輸入名稱、Email 與密碼")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final headers = {'Content-Type': 'application/json'};
      // 將名稱、Email 和密碼都包含在請求主體中
      final body = jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      });

      // 修正：這裡應該是登入的 API 路徑，而不是註冊路徑
      final res = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: headers,
        body: body,
      );

      // --- 偵錯訊息 ---
      print('Response Status Code: ${res.statusCode}');
      print('Response Body: ${res.body}');
      // ----------------

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final String? uuidFromServer =
            data['user_id']?.toString() ?? data['id']?.toString();

        if (uuidFromServer != null && uuidFromServer.isNotEmpty) {
          final now = DateFormat('HH:mm').format(DateTime.now());
          final snackBar = SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "登入成功！$now",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HomePage(
                    userId: uuidFromServer,
                    userName: nameController.text.trim(), // 傳入名稱
                    email: emailController.text.trim(),
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("登入成功，但無法取得使用者 ID")));
          print('Response Body: ${res.body}');
        }
      } else if (res.statusCode == 401) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("登入失敗：名稱、Email 或密碼不正確")));
      } else {
        try {
          final errorMsg = jsonDecode(res.body)['error'] ?? "伺服器發生未知錯誤";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("❌ 登入失敗：$errorMsg")));
        } on FormatException {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("❌ 登入失敗：伺服器回傳了無效的回應")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("錯誤：無法連線到伺服器")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("登入")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "登入您的帳號",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "名稱",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: "密碼",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _loginUser,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        isLoading ? "登入中..." : "登入",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text("還沒有帳號？點此註冊"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
