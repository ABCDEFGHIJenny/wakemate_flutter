import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CaffeineLogPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const CaffeineLogPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineLogPage> createState() => _CaffeineLogPageState();
}

class _CaffeineLogPageState extends State<CaffeineLogPage> {
  final TextEditingController caffeineController = TextEditingController();
  final TextEditingController drinkNameController = TextEditingController(
    text: "咖啡",
  );
  final TextEditingController takingTimeController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  @override
  void initState() {
    super.initState();
    // 預設飲用時間為當前選擇日期的當前時間
    takingTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());
  }

  @override
  void dispose() {
    caffeineController.dispose();
    drinkNameController.dispose();
    takingTimeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            color == Colors.green
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(time);
      return dt.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _submitData() async {
    final uuid = widget.userId;
    final caffeine = caffeineController.text.trim();
    final drinkName = drinkNameController.text.trim();
    final takingTime = takingTimeController.text.trim();

    if (caffeine.isEmpty || drinkName.isEmpty || takingTime.isEmpty) {
      _showSnackBar("請填寫所有欄位");
      return;
    }

    final caffeineAmount = int.tryParse(caffeine);
    if (caffeineAmount == null || caffeineAmount <= 0) {
      _showSnackBar("咖啡因含量必須是有效的正整數。");
      return;
    }

    final headers = {'Content-Type': 'application/json'};

    try {
      final intakeRes = await http.post(
        Uri.parse('$baseUrl/users_intake/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          'caffeine_amount': caffeineAmount,
          'drink_name': drinkName,
          'taking_timestamp': formatToISO8601(takingTime), // 使用單獨的攝取時間
        }),
      );

      if (intakeRes.statusCode == 200) {
        _showSnackBar(
          "咖啡因攝取記錄儲存成功！",
          color: const Color.fromARGB(255, 59, 140, 101),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        String intakeBody =
            intakeRes.body.isNotEmpty ? intakeRes.body : "無回應內容";
        _showSnackBar("咖啡因記錄儲存失敗：${intakeRes.statusCode}\n回應：$intakeBody");
      }
    } catch (e) {
      _showSnackBar("發生錯誤：$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增咖啡因紀錄'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '記錄您攝取的咖啡因，以便 WakeMate 為您提供個人化的咖啡因建議。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: caffeineController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "咖啡因含量 (毫克)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "例如：150",
                prefixIcon: const Icon(
                  Icons.local_cafe,
                  color: Color(0xFF1F3D5B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: drinkNameController,
              decoration: InputDecoration(
                labelText: '飲料名稱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '例如 拿鐵',
                prefixIcon: const Icon(
                  Icons.local_drink,
                  color: Color(0xFF1F3D5B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: takingTimeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '飲用時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.access_time,
                  color: Color(0xFF1F3D5B),
                ),
              ),
              onTap: () => _pickDateTime(takingTimeController),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3D5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "儲存咖啡因記錄",
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
