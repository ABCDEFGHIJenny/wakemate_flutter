import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:intl/intl.dart';

class CaffeineHistoryPage extends StatelessWidget {
  final List<dynamic> recommendationData;
  final String userId;
  final DateTime selectedDate;

  const CaffeineHistoryPage({
    super.key,
    this.recommendationData = const [],
    required this.userId,
    required this.selectedDate,
  });

  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 淺藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _textColor = const Color(0xFF424242); // 深灰色文字

  // --- 數據過濾邏輯 (保留) ---

  /// 將 UTC 時間字串解析為本地 DateTime
  DateTime? _parseAndLocalize(String? datetimeStr) {
    if (datetimeStr == null || datetimeStr.isEmpty) return null;
    try {
      return DateTime.parse(datetimeStr).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// 檢查時間是否在選定日期內 (本地時間)
  bool _isDateInRange(DateTime dateTime, DateTime dateStart, DateTime dateEnd) {
    return dateTime.isAfter(
          dateStart.subtract(const Duration(milliseconds: 1)),
        ) &&
        dateTime.isBefore(dateEnd);
  }

  /// 過濾系統推薦數據
  List<dynamic> _filterRecommendedData(List<dynamic> data) {
    if (data.isEmpty) return [];

    final dateStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final dateEnd = dateStart.add(const Duration(days: 1));

    return data.where((item) {
      final String recommendedTimingStr =
          item['recommended_caffeine_intake_timing'] ?? '';
      final localDateTime = _parseAndLocalize(recommendedTimingStr);

      if (localDateTime == null) return false;
      return _isDateInRange(localDateTime, dateStart, dateEnd);
    }).toList();
  }

  /// 顯示單一數據行 (圖示 + 標題 + 內容)
  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 90, // 固定寬度對齊標題
            child: Text(
              "$title:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: TextStyle(fontSize: 14, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateHistory = _filterRecommendedData(recommendationData);
    bool hasHistory = selectedDateHistory.isNotEmpty;

    final String formattedDate = DateFormat('yyyy/MM/dd').format(selectedDate);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "$formattedDate 推薦結果",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
          hasHistory
              ? ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: selectedDateHistory.length,
                itemBuilder: (context, index) {
                  final item = selectedDateHistory[index];

                  final String recommendedTimingStr =
                      item['recommended_caffeine_intake_timing'] ?? 'N/A';
                  final recommendedAmount =
                      item['recommended_caffeine_amount'] ?? 'N/A';

                  String formattedTime;
                  try {
                    final localDateTime = _parseAndLocalize(
                      recommendedTimingStr,
                    );
                    formattedTime =
                        localDateTime != null
                            ? DateFormat('MM/dd HH:mm').format(localDateTime)
                            : '格式錯誤';
                  } catch (e) {
                    formattedTime = '格式錯誤';
                  }

                  return Card(
                    color: _cardColor,
                    elevation: 4.0,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "咖啡因攝取建議",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const Divider(height: 20),
                          _buildDataRow(
                            icon: Icons.access_time_filled,
                            title: "建議時間",
                            content: formattedTime,
                            iconColor: _accentColor,
                          ),
                          _buildDataRow(
                            icon: Icons.local_cafe,
                            title: "建議攝取",
                            content: "$recommendedAmount 毫克",
                            iconColor: _accentColor,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.coffee_outlined,
                        size: 80,
                        color: _accentColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "$formattedDate 尚無建議結果",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "請返回並點擊「計算推薦」按鈕以生成新的建議。",
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
