import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui'; // 引入 BackdropFilter

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CaffeineHistory.dart';

class CaffeineRecommendationPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const CaffeineRecommendationPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineRecommendationPage> createState() =>
      _CaffeineRecommendationPageState();
}

class _CaffeineRecommendationPageState extends State<CaffeineRecommendationPage>
    with SingleTickerProviderStateMixin {
  // 顏色變數
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF5E91B3);

  // 狀態變數
  bool _isLoading = true;
  String _errorMessage = ""; // 用於儲存詳細錯誤訊息

  // 動畫控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化動畫控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 定義動畫
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );

    // 一進入就直接執行計算邏輯
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendAllDataAndFetchRecommendation();
      _animationController.forward(); // 啟動載入動畫
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // 銷毀動畫控制器
    super.dispose();
  }

  // 簡化日期格式化，直接使用 ISO 8601 UTC
  String _formatDate(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    final userId = widget.userId;

    try {
      final headers = {"Content-Type": "application/json"};
      const timeout = Duration(seconds: 15);

      // --- 1. 假資料：睡眠時間 (使用正確的欄位名稱) ---
      final sleepData = {
        "user_id": userId,
        "sleep_start_time": _formatDate(
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            23,
            0,
          ).subtract(const Duration(days: 1)), // 設為前一天 23:00
        ),
        "sleep_end_time": _formatDate(
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            7,
            0,
          ), // 設為當天 07:00
        ),
      };
      const sleepUrl = "https://wakemate-api-4-0.onrender.com/users_sleep/";
      await http
          .post(
            Uri.parse(sleepUrl),
            headers: headers,
            body: json.encode(sleepData),
          )
          .timeout(timeout);

      // --- 2. 假資料：清醒時間 ---
      final wakeData = {
        "user_id": userId,
        "target_start_time": _formatDate(
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            9,
            0,
          ),
        ),
        "target_end_time": _formatDate(
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            17,
            0,
          ),
        ),
      };
      const wakeUrl = "https://wakemate-api-4-0.onrender.com/users_wake/";
      await http
          .post(
            Uri.parse(wakeUrl),
            headers: headers,
            body: json.encode(wakeData),
          )
          .timeout(timeout);

      // --- 3. 假資料：咖啡因攝取 ---
      final intakeData = {
        'user_id': userId,
        'caffeine_amount': 100,
        'drink_name': '美式咖啡',
        'taking_timestamp': _formatDate(
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            10,
            0,
          ),
        ),
      };
      const intakeUrl = "https://wakemate-api-4-0.onrender.com/users_intake/";
      await http
          .post(
            Uri.parse(intakeUrl),
            headers: headers,
            body: json.encode(intakeData),
          )
          .timeout(timeout);

      // --- 4. 取得推薦 ---
      final recommendationUrl =
          "https://wakemate-api-4-0.onrender.com/recommendations/?user_id=$userId";
      final recommendationResponse = await http
          .get(Uri.parse(recommendationUrl))
          .timeout(timeout);

      if (recommendationResponse.statusCode == 200) {
        final data = json.decode(recommendationResponse.body);
        _showSnackBar("計算成功！", color: Colors.green);

        final prefs = await SharedPreferences.getInstance();
        final List<dynamic> historyToSave = data is List ? data : [data];
        await prefs.setString(
          'caffeine_recommendations',
          json.encode(historyToSave),
        );

        if (!mounted) return;

        // 成功後跳轉到歷史紀錄頁
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => CaffeineHistoryPage(
                  recommendationData: historyToSave,
                  userId: widget.userId,
                  selectedDate: widget.selectedDate,
                ),
          ),
        );
      } else {
        String bodyPreview =
            recommendationResponse.body.length > 50
                ? recommendationResponse.body.substring(0, 50) + '...'
                : recommendationResponse.body;

        _showSnackBar(
          "計算失敗: ${recommendationResponse.statusCode}",
          color: Colors.red,
        );

        if (mounted) {
          setState(() {
            _errorMessage =
                "伺服器錯誤 (Status: ${recommendationResponse.statusCode})。\n回應內容預覽: $bodyPreview";
            _isLoading = false;
          });
          _animationController.reverse(); // 錯誤時反向動畫
        }
      }
    } on TimeoutException {
      _showSnackBar("錯誤：請求逾時，請檢查您的網路連線。", color: Colors.red);
      if (mounted) {
        setState(() {
          _errorMessage = "連線逾時。請檢查網路後重試。";
          _isLoading = false;
        });
        _animationController.reverse();
      }
    } on SocketException {
      _showSnackBar("網路連線錯誤，請檢查您的網路。", color: Colors.red);
      if (mounted) {
        setState(() {
          _errorMessage = "無法連線到伺服器。請檢查網路。";
          _isLoading = false;
        });
        _animationController.reverse();
      }
    } catch (e) {
      _showSnackBar("發生未知錯誤: $e", color: Colors.red);
      if (mounted) {
        setState(() {
          _errorMessage = "發生未知錯誤: $e";
          _isLoading = false;
        });
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 讓 body 延伸到 AppBar 後面
      appBar: AppBar(
        automaticallyImplyLeading: false, // 移除返回箭頭
        title: const Text(
          "咖啡因建議",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // 使用透明背景
        elevation: 0, // 移除陰影
      ),
      body: Stack(
        // 使用 Stack 讓背景模糊和前景動畫疊加
        children: [
          // 底部背景內容 (可以放一些靜態背景，或者只是留白)
          Container(color: Colors.white),

          // 載入/錯誤動畫層
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _animationController.value * 5, // 模糊效果隨動畫值變化
                    sigmaY: _animationController.value * 5,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(
                      0.1 * _animationController.value,
                    ), // 半透明遮罩
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child:
                                _isLoading
                                    ? _buildLoadingWidget()
                                    : _buildErrorWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 載入動畫專屬的 Widget
  Widget _buildLoadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primaryColor, strokeWidth: 5),
        const SizedBox(height: 24),
        Text(
          "正在為您分析咖啡因數據...",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "這可能需要一點時間，請耐心等候",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  // 錯誤訊息專屬的 Widget
  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.redAccent,
          size: 70,
        ), // 更友善的錯誤圖示
        const SizedBox(height: 20),
        Text(
          "哎呀！計算失敗了...",
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () {
            // 重新執行計算流程
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = "";
              });
              _animationController.reset(); // 重設動畫
              _animationController.forward(); // 重新啟動動畫
              sendAllDataAndFetchRecommendation();
            }
          },
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text("重新嘗試", style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "返回主頁",
            style: TextStyle(color: _accentColor, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
