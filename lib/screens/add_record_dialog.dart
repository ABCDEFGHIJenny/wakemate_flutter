import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AddRecordDialog extends StatefulWidget {
  final String userId; // ✅ 從 HomePage 傳入 UUID

  const AddRecordDialog({super.key, required this.userId});

  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog> {
  final TextEditingController caffeineController = TextEditingController();
  final TextEditingController sleepTimeController = TextEditingController();
  final TextEditingController wakeTimeController = TextEditingController();
  final TextEditingController drinkNameController = TextEditingController(
    text: "咖啡",
  );

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  // 新增一個自訂的 SnackBar 函數，以提供更美觀的提示
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
    DateTime now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
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
    final uuid = widget.userId; // ✅ 使用傳入 UUID
    final sleepTime = sleepTimeController.text.trim();
    final wakeTime = wakeTimeController.text.trim();
    final caffeine = caffeineController.text.trim();
    final drinkName = drinkNameController.text.trim();

    if (sleepTime.isEmpty ||
        wakeTime.isEmpty ||
        caffeine.isEmpty ||
        drinkName.isEmpty) {
      _showSnackBar("請填寫所有欄位");
      return;
    }

    final headers = {'Content-Type': 'application/json'};

    try {
      final sleepRes = await http.post(
        Uri.parse('$baseUrl/users_sleep/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          'start_time': formatToISO8601(sleepTime),
          'end_time': formatToISO8601(wakeTime),
        }),
      );

      final intakeRes = await http.post(
        Uri.parse('$baseUrl/users_intake/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          'caffeine_amount': int.tryParse(caffeine) ?? 0,
          'drink_name': drinkName,
          'taking_timestamp': formatToISO8601(sleepTime),
        }),
      );

      if (sleepRes.statusCode == 200 && intakeRes.statusCode == 200) {
        _showSnackBar(
          "資料儲存成功！",
          color: const Color.fromARGB(255, 59, 140, 101),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        String sleepBody = sleepRes.body.isNotEmpty ? sleepRes.body : "無回應內容";
        String intakeBody =
            intakeRes.body.isNotEmpty ? intakeRes.body : "無回應內容";

        _showSnackBar(
          "儲存失敗：\n/users_sleep/：${sleepRes.statusCode}\n回應：$sleepBody\n\n/users_intake/：${intakeRes.statusCode}\n回應：$intakeBody",
        );
      }
    } catch (e) {
      _showSnackBar("發生錯誤：$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      title: const Text(
        "新增記錄",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caffeineController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "咖啡因含量（毫克）",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "例如：150",
                  prefixIcon: const Icon(Icons.local_cafe),
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
                  hintText: '例如 咖啡',
                  prefixIcon: const Icon(Icons.local_drink),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sleepTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '睡覺時間（點擊選擇）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.bedtime),
                ),
                onTap: () => _pickDateTime(sleepTimeController),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wakeTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '起床時間（點擊選擇）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                onTap: () => _pickDateTime(wakeTimeController),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("取消"),
        ),
        ElevatedButton(
          onPressed: _submitData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 59, 140, 101),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("儲存"),
        ),
      ],
    );
  }
}
