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

  // 定義新的顏色
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 較淺的藍色

  @override
  void initState() {
    super.initState();
    final selected = widget.selectedDate;

    // 使用傳入的 selectedDate 初始化所有日期時間
    _targetStart = DateTime(selected.year, selected.month, selected.day, 8, 0);
    _targetEnd = _targetStart.add(const Duration(hours: 8));
    _sleepStart = DateTime(selected.year, selected.month, selected.day, 23, 0);
    _sleepEnd = _sleepStart.add(const Duration(hours: 8));
    _caffeineIntakeTime = DateTime(
      selected.year,
      selected.month,
      selected.day,
      10,
      0,
    );
  }

  @override
  void dispose() {
    caffeineController.dispose();
    drinkNameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dateTime) {
    // 確保時間格式為 API 所需的 UTC 格式
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dateTime.toUtc());
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

  Future<void> _selectDateAndTime(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateTimeSelected,
  }) async {
    // 選擇日期時，將初次日期設定為選取時間的日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
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

  void _showConfirmationDialog() {
    // 驗證咖啡因含量是否為數字
    // if (caffeineController.text.isEmpty ||
    //     drinkNameController.text.isEmpty ||
    //     int.tryParse(caffeineController.text) == null) {
    //   _showSnackBar("請正確填寫咖啡因含量 (數字) 與飲料名稱");
    //   return;
    // }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "確認您的資料",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow("咖啡因含量", "${caffeineController.text} 毫克"),
              _buildDialogRow("飲料名稱", drinkNameController.text),
              _buildDialogRow(
                "攝取時間",
                DateFormat("yyyy/MM/dd HH:mm").format(_caffeineIntakeTime),
              ),
              const Divider(height: 20),
              _buildDialogRow(
                "目標清醒時間",
                "${DateFormat("MM/dd HH:mm").format(_targetStart)} - ${DateFormat("MM/dd HH:mm").format(_targetEnd)}",
              ),
              _buildDialogRow(
                "睡眠時間",
                "${DateFormat("MM/dd HH:mm").format(_sleepStart)} - ${DateFormat("MM/dd HH:mm").format(_sleepEnd)}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("取消"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                sendAllDataAndFetchRecommendation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // 替換為新顏色
                foregroundColor: Colors.white,
              ),
              child: const Text("確認並送出"),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    if (caffeineController.text.isEmpty || drinkNameController.text.isEmpty) {
      // 雖然在確認對話框裡檢查了，但這裡作為保險
      _showSnackBar("請填寫所有咖啡因資料");
      return;
    }

    final userId = widget.userId;

    try {
      final headers = {"Content-Type": "application/json"};

      // 1. 發送睡眠時間
      final sleepData = {
        "user_id": userId,
        "sleep_start_time": _formatDate(_sleepStart),
        "sleep_end_time": _formatDate(_sleepEnd),
      };
      const sleepUrl = "https://wakemate-api-4-0.onrender.com/users_sleep/";
      await http
          .post(
            Uri.parse(sleepUrl),
            headers: headers,
            body: json.encode(sleepData),
          )
          .timeout(const Duration(seconds: 15));

      // 2. 發送清醒時間
      final wakeData = {
        "user_id": userId,
        "target_start_time": _formatDate(_targetStart),
        "target_end_time": _formatDate(_targetEnd),
      };
      const wakeUrl = "https://wakemate-api-4-0.onrender.com/users_wake/";
      await http
          .post(
            Uri.parse(wakeUrl),
            headers: headers,
            body: json.encode(wakeData),
          )
          .timeout(const Duration(seconds: 15));

      // 3. 發送咖啡因攝取資料
      final intakeData = {
        'user_id': userId,
        'caffeine_amount': int.tryParse(caffeineController.text) ?? 0,
        'drink_name': drinkNameController.text.trim(),
        'taking_timestamp': _formatDate(_caffeineIntakeTime),
      };
      const intakeUrl = "https://wakemate-api-4-0.onrender.com/users_intake/";
      await http
          .post(
            Uri.parse(intakeUrl),
            headers: headers,
            body: json.encode(intakeData),
          )
          .timeout(const Duration(seconds: 15));

      // 4. 取得咖啡因建議
      final recommendationUrl =
          "https://wakemate-api-4-0.onrender.com/recommendations/?user_id=$userId";
      final recommendationResponse = await http
          .get(Uri.parse(recommendationUrl))
          .timeout(const Duration(seconds: 15));

      if (recommendationResponse.statusCode == 200) {
        final data = json.decode(recommendationResponse.body);
        _showSnackBar("計算成功！", color: Colors.green);

        // 儲存至本地 (Shared Preferences)
        final prefs = await SharedPreferences.getInstance();
        // 確保儲存的是列表格式 (雖然 API 應該回傳列表，但多一層判斷更安全)
        final List<dynamic> historyToSave = data is List ? data : [data];
        await prefs.setString(
          'caffeine_recommendations',
          json.encode(historyToSave),
        );

        if (!mounted) return;

        // 導航到歷史紀錄頁面，並傳遞選取的日期
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CaffeineHistoryPage(
                  recommendationData: historyToSave,
                  userId: widget.userId,
                  // *** 修正點：傳遞必填的 selectedDate 參數 ***
                  selectedDate: widget.selectedDate,
                ),
          ),
        );
      } else {
        _showSnackBar("觸發計算失敗: ${recommendationResponse.statusCode}");
      }
    } on TimeoutException {
      _showSnackBar("錯誤: 請求逾時，請檢查您的網路連線。");
    } on SocketException {
      _showSnackBar("網路連線錯誤，請檢查您的網路。");
    } catch (e) {
      _showSnackBar("發生未知錯誤: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "咖啡因建議",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(
              "時間排程 (選取日期: ${DateFormat('yyyy/MM/dd').format(widget.selectedDate)})",
            ),
            _buildTimeCard(
              "目標清醒時間",
              _targetStart,
              _targetEnd,
              onStartSelected:
                  (newDate) => setState(() => _targetStart = newDate),
              onEndSelected: (newDate) => setState(() => _targetEnd = newDate),
            ),
            _buildTimeCard(
              "實際睡眠時間",
              _sleepStart,
              _sleepEnd,
              onStartSelected:
                  (newDate) => setState(() => _sleepStart = newDate),
              onEndSelected: (newDate) => setState(() => _sleepEnd = newDate),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("咖啡因攝取資料"),
            _buildTextField(
              "咖啡因含量（毫克）",
              "例如：100",
              caffeineController,
              Icons.local_cafe_outlined,
              TextInputType.number,
            ),
            _buildTextField(
              "飲料名稱",
              "例如：美式咖啡",
              drinkNameController,
              Icons.local_drink_outlined,
            ),
            _buildTimeField(
              "攝取時間",
              _caffeineIntakeTime,
              (newDate) => setState(() => _caffeineIntakeTime = newDate),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _showConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // 替換為新顏色
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                "計算並取得咖啡因建議",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: _accentColor), // 替換為新顏色
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    DateTime time,
    ValueChanged<DateTime> onDateTimeSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap:
            () => _selectDateAndTime(
              context,
              initialDate: time,
              onDateTimeSelected: onDateTimeSelected,
            ),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.access_time, color: _accentColor), // 替換為新顏色
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
          child: Text(
            DateFormat("yyyy/MM/dd HH:mm").format(time),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(
    String title,
    DateTime start,
    DateTime end, {
    required ValueChanged<DateTime> onStartSelected,
    required ValueChanged<DateTime> onEndSelected,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSmallTimeButton("開始", start, onStartSelected),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSmallTimeButton("結束", end, onEndSelected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTimeButton(
    String label,
    DateTime time,
    ValueChanged<DateTime> onDateTimeSelected,
  ) {
    return OutlinedButton(
      onPressed:
          () => _selectDateAndTime(
            context,
            initialDate: time,
            onDateTimeSelected: onDateTimeSelected,
          ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _accentColor, // 替換為新顏色
        side: BorderSide(color: _accentColor), // 替換為新顏色
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            DateFormat("HH:mm").format(time),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label：", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
