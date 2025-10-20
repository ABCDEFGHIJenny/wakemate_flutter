import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 雖然未使用 SharedPreferences 暫存，但保留 import

class ActualSleepTimePage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const ActualSleepTimePage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<ActualSleepTimePage> createState() => _ActualSleepTimePageState();
}

class _ActualSleepTimePageState extends State<ActualSleepTimePage> {
  // 控制器
  final TextEditingController sleepStartController = TextEditingController();
  final TextEditingController sleepEndController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  // 顏色變數
  final Color _primaryColor = const Color(0xFF1F3D5B);

  @override
  void initState() {
    super.initState();
    _loadInitialTimes();
  }

  void _loadInitialTimes() {
    final now = widget.selectedDate;

    // 預設「開始睡覺時間」為前一晚的 23:00
    sleepStartController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime(now.year, now.month, now.day - 1, 23, 0));

    // 預設「結束睡眠時間」為今天的 07:00
    sleepEndController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime(now.year, now.month, now.day, 7, 0));
  }

  @override
  void dispose() {
    sleepStartController.dispose();
    sleepEndController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
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

  /// 彈出日期+時間選擇器
  Future<void> _pickDateTime(TextEditingController controller) async {
    DateTime initialDateTime;
    try {
      initialDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(controller.text);
    } catch (e) {
      initialDateTime = DateTime.now();
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (pickedTime == null) return;

    DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
  }

  /// 將 yyyy-MM-dd HH:mm 轉成 ISO8601
  String formatToISO8601(String time) {
    try {
      // 假設使用者輸入的是當地時間，我們將其轉為 UTC 提交給 API
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(time, true);
      return dt.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _submitData() async {
    final uuid = widget.userId;
    final sleepStartTimeText = sleepStartController.text.trim();
    final sleepEndTimeText = sleepEndController.text.trim();

    if (sleepStartTimeText.isEmpty || sleepEndTimeText.isEmpty) {
      _showSnackBar("請選擇睡眠的開始時間與結束時間。");
      return;
    }

    // 驗證時間順序
    try {
      final dtStart = DateFormat('yyyy-MM-dd HH:mm').parse(sleepStartTimeText);
      final dtEnd = DateFormat('yyyy-MM-dd HH:mm').parse(sleepEndTimeText);
      if (dtEnd.isBefore(dtStart)) {
        _showSnackBar("結束時間不能早於開始時間，請檢查日期和時間。", color: Colors.red);
        return;
      }
    } catch (e) {
      _showSnackBar("時間格式錯誤，請重新選擇。", color: Colors.red);
      return;
    }

    // 轉換為 ISO8601
    final sleepStartTimeISO = formatToISO8601(sleepStartTimeText);
    final sleepEndTimeISO = formatToISO8601(sleepEndTimeText);

    final headers = {'Content-Type': 'application/json'};

    try {
      final sleepRes = await http.post(
        Uri.parse('$baseUrl/users_sleep/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          // 修正點：使用 API 要求的欄位名稱
          'sleep_start_time': sleepStartTimeISO, // 開始睡覺時間
          'sleep_end_time': sleepEndTimeISO, // 結束睡眠時間
        }),
      );

      if (sleepRes.statusCode == 200) {
        _calculateAndShowSleepDuration(sleepStartTimeISO, sleepEndTimeISO);

        if (mounted) {
          // 提交成功後關閉頁面
          Navigator.of(context).pop();
        }
      } else {
        // 伺服器回傳非 200 狀態碼
        String sleepBody = sleepRes.body.isNotEmpty ? sleepRes.body : "無回應內容";
        _showSnackBar("睡眠紀錄儲存失敗：${sleepRes.statusCode}\n回應：$sleepBody");
      }
    } catch (e) {
      // 網路或解析錯誤
      _showSnackBar("發生錯誤：$e");
    }
  }

  // 計算並顯示睡眠時長
  void _calculateAndShowSleepDuration(String startISO, String endISO) {
    try {
      final dtStart = DateTime.parse(startISO).toLocal();
      final dtEnd = DateTime.parse(endISO).toLocal();

      final duration = dtEnd.difference(dtStart);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      // 成功訊息
      _showSnackBar(
        "睡眠紀錄儲存成功！\n😴 總時長：${hours}小時 ${minutes}分鐘",
        color: const Color.fromARGB(255, 59, 140, 101),
      );
    } catch (e) {
      _showSnackBar("資料格式錯誤，無法計算時長。", color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增實際睡眠時間'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '請輸入您實際開始睡覺的時間與結束睡眠的時間，以記錄完整的睡眠週期。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 1. 開始睡覺時間
            TextField(
              controller: sleepStartController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '開始睡覺時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.bedtime, color: _primaryColor),
                hintText: '例如：2025-10-20 23:00',
              ),
              onTap: () => _pickDateTime(sleepStartController),
            ),

            const SizedBox(height: 16),

            // 2. 結束睡眠時間
            TextField(
              controller: sleepEndController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '結束睡眠時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.access_time_filled,
                  color: _primaryColor,
                ),
                hintText: '例如：2025-10-21 07:00',
              ),
              onTap: () => _pickDateTime(sleepEndController),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "儲存睡眠週期",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
