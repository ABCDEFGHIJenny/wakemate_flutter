import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'RegisterPage.dart';
import 'package:intl/intl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';
  bool isLoading = false;

  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _errorColor = const Color(0xFFE53935); // 紅色

  @override
  void initState() {
    super.initState();

    nameController.text = "1414";
    emailController.text = "1414@gmail.com";
    passwordController.text = "1414";
  }

  Future<void> _loginUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("請輸入名稱、Email 與密碼")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: headers,
        body: body,
      );

      print('Response Status Code: ${res.statusCode}');
      print('Response Body: ${res.body}');

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
                    userName: nameController.text.trim(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ 登入失敗：$errorMsg"),
              backgroundColor: _errorColor,
            ),
          );
        } on FormatException {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("❌ 登入失敗：伺服器回傳了無效的回應"),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("錯誤：無法連線到伺服器"),
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "使用者登入",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: _cardColor,
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
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 名稱輸入框
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "名稱",
                      labelStyle: TextStyle(color: _primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: 2.0,
                        ),
                      ),
                      prefixIcon: Icon(Icons.person, color: _primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Email 輸入框
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: _primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: 2.0,
                        ),
                      ),
                      prefixIcon: Icon(Icons.email, color: _primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // 密碼輸入框
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: "密碼",
                      labelStyle: TextStyle(color: _primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: 2.0,
                        ),
                      ),
                      prefixIcon: Icon(Icons.lock, color: _primaryColor),
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
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(isLoading ? "登入中..." : "登入"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
