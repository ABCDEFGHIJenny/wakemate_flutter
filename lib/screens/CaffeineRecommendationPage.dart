import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CaffeineHistory.dart';

class CaffeineRecommendationPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate; // ✅ 從 HomePage 傳入

  const CaffeineRecommendationPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineRecommendationPage> createState() =>
      _CaffeineRecommendationPageState();
}

class _CaffeineRecommendationPageState
    extends State<CaffeineRecommendationPage> {
  // 控制器
  final TextEditingController caffeineController = TextEditingController();
  final TextEditingController drinkNameController = TextEditingController();

  // 時間狀態
  late DateTime _targetStart;
  late DateTime _targetEnd;
  late DateTime _sleepStart;
  late DateTime _sleepEnd;
  late DateTime _caffeineIntakeTime;

  @override
  void initState() {
    super.initState();
    final selected = widget.selectedDate;

    // ✅ 根據選擇的日期來初始化
    _targetStart = DateTime(
      selected.year,
      selected.month,
      selected.day,
      8,
      0,
    ); // 08:00
    _targetEnd = _targetStart.add(const Duration(hours: 8)); // 16:00
    _sleepStart = DateTime(
      selected.year,
      selected.month,
      selected.day,
      23,
      0,
    ); // 23:00
    _sleepEnd = _sleepStart.add(const Duration(hours: 8)); // 翌日 07:00
    _caffeineIntakeTime = DateTime(
      selected.year,
      selected.month,
      selected.day,
      10,
      0,
    ); // 10:00
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dateTime.toUtc());
  }

  // 新增 SnackBar 函數
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

  Future<void> _selectDateAndTime(
    BuildContext context, {
    required ValueChanged<DateTime> onDateTimeSelected,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate, // ✅ 預設跳到 HomePage 選的日期
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.selectedDate), // ✅ 同樣基於選的日期
    );
    if (pickedTime != null) {
      final newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      onDateTimeSelected(newDateTime);
    }
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    if (caffeineController.text.isEmpty || drinkNameController.text.isEmpty) {
      _showSnackBar("請填寫所有咖啡因資料");
      return;
    }

    final userId = widget.userId;

    try {
      final headers = {"Content-Type": "application/json"};

      // 1. 發送睡眠資料
      final sleepData = {
        "user_id": userId,
        "sleep_start_time": _formatDate(_sleepStart),
        "sleep_end_time": _formatDate(_sleepEnd),
      };
      const sleepUrl = "https://wakemate-api-4-0.onrender.com/users_sleep/";
      final sleepResponse = await http.post(
        Uri.parse(sleepUrl),
        headers: headers,
        body: json.encode(sleepData),
      );

      if (sleepResponse.statusCode != 200) {
        _showSnackBar("發送睡眠資料失敗: ${sleepResponse.statusCode}");
        return;
      }

      // 2. 發送清醒資料
      final wakeData = {
        "user_id": userId,
        "target_start_time": _formatDate(_targetStart),
        "target_end_time": _formatDate(_targetEnd),
      };
      const wakeUrl = "https://wakemate-api-4-0.onrender.com/users_wake/";
      final wakeResponse = await http.post(
        Uri.parse(wakeUrl),
        headers: headers,
        body: json.encode(wakeData),
      );

      if (wakeResponse.statusCode != 200) {
        _showSnackBar("發送清醒資料失敗: ${wakeResponse.statusCode}");
        return;
      }

      // 3. 發送咖啡因資料
      final intakeData = {
        'user_id': userId,
        'caffeine_amount': int.tryParse(caffeineController.text) ?? 0,
        'drink_name': drinkNameController.text.trim(),
        'taking_timestamp': _formatDate(_caffeineIntakeTime),
      };
      const intakeUrl = "https://wakemate-api-4-0.onrender.com/users_intake/";
      final intakeResponse = await http.post(
        Uri.parse(intakeUrl),
        headers: headers,
        body: json.encode(intakeData),
      );

      if (intakeResponse.statusCode != 200) {
        _showSnackBar("發送咖啡因資料失敗: ${intakeResponse.statusCode}");
        return;
      }

      // 4. 取得推薦結果
      final recommendationUrl =
          "https://wakemate-api-4-0.onrender.com/recommendations/?user_id=$userId";
      final recommendationResponse = await http.get(
        Uri.parse(recommendationUrl),
      );

      if (recommendationResponse.statusCode == 200) {
        final data = json.decode(recommendationResponse.body);
        _showSnackBar("計算成功！", color: Colors.green);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'caffeine_recommendations',
          json.encode(data is List ? data : [data]),
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CaffeineHistoryPage(
                  recommendationData: data is List ? data : [data],
                  userId: widget.userId,
                ),
          ),
        );
      } else {
        _showSnackBar("觸發計算失敗: ${recommendationResponse.statusCode}");
      }
    } on TimeoutException {
      _showSnackBar("錯誤: 請求逾時");
    } on SocketException catch (e) {
      _showSnackBar("網路錯誤: $e");
    } catch (e) {
      _showSnackBar("未知例外錯誤: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("咖啡因建議")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("睡眠與清醒時間"),
              _buildTimeField("目標清醒開始時間", _targetStart, (newDate) {
                setState(() => _targetStart = newDate);
              }),
              _buildTimeField("目標清醒結束時間", _targetEnd, (newDate) {
                setState(() => _targetEnd = newDate);
              }),
              _buildTimeField("實際睡眠開始時間", _sleepStart, (newDate) {
                setState(() => _sleepStart = newDate);
              }),
              _buildTimeField("實際睡眠結束時間", _sleepEnd, (newDate) {
                setState(() => _sleepEnd = newDate);
              }),
              const SizedBox(height: 20),
              _buildSectionTitle("咖啡因攝取資料"),
              _buildTextField(
                "咖啡因含量（毫克）",
                caffeineController,
                Icons.local_cafe,
                TextInputType.number,
              ),
              _buildTextField("飲料名稱", drinkNameController, Icons.local_drink),
              _buildTimeField("攝取時間", _caffeineIntakeTime, (newDate) {
                setState(() => _caffeineIntakeTime = newDate);
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendAllDataAndFetchRecommendation,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("發送資料並取得建議"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    DateTime time,
    ValueChanged<DateTime> onDateTimeSelected,
  ) {
    final controller = TextEditingController(
      text: DateFormat("yyyy-MM-dd HH:mm").format(time),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap:
            () => _selectDateAndTime(
              context,
              onDateTimeSelected: onDateTimeSelected,
            ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
