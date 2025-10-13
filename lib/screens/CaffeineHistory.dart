import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:intl/intl.dart';

class CaffeineHistoryPage extends StatelessWidget {
  final List<dynamic> recommendationData;
  final String userId;
  // 🎯 新增：接收從 HomePage 傳入的選取日期
  final DateTime selectedDate;

  const CaffeineHistoryPage({
    super.key,
    this.recommendationData = const [],
    required this.userId,
    // 🎯 標記為必填
    required this.selectedDate,
  });

  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 淺藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _textColor = const Color(0xFF424242); // 深灰色文字

  // 🎯 修改：根據傳入的 selectedDate 過濾數據
  List<dynamic> _filterSelectedDateData() {
    if (recommendationData.isEmpty) {
      return [];
    }

    // 取得選取日期的午夜 00:00:00 作為該日期的起始點 (本地時間)
    final dateStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    // 取得選取日期隔天的午夜 00:00:00 作為該日期的結束點 (本地時間)
    final dateEnd = dateStart.add(const Duration(days: 1));

    return recommendationData.where((item) {
      final String recommendedTimingStr =
          item['recommended_caffeine_intake_timing'] ?? '';

      if (recommendedTimingStr.isEmpty) {
        return false;
      }

      try {
        // 將 UTC 時間字串解析為 DateTime
        final utcDateTime = DateTime.parse(recommendedTimingStr);
        // 轉換為本地時間
        final localDateTime = utcDateTime.toLocal();

        // 過濾條件：紀錄時間必須在 dateStart (含) 和 dateEnd (不含) 之間
        // 為了確保包含 dateStart 當天 00:00:00 的精確匹配，使用 isAfter 減去微小時間
        return localDateTime.isAfter(
              dateStart.subtract(const Duration(milliseconds: 1)),
            ) &&
            localDateTime.isBefore(dateEnd);
      } catch (e) {
        // 解析失敗的數據一律不顯示
        // print('Error parsing date: $e for string: $recommendedTimingStr');
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 使用新的過濾方法
    final selectedDateHistory = _filterSelectedDateData();
    bool hasHistory = selectedDateHistory.isNotEmpty;

    // 格式化選取日期，用於 App Bar 標題
    final String formattedDate = DateFormat('yyyy/MM/dd').format(selectedDate);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        // 🎯 修改標題：顯示正在查看哪天的紀錄
        title: Text(
          "$formattedDate 咖啡因建議結果",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            // 返回到 HomePage，並清除所有路由堆棧，避免重複堆疊
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
              (route) => false,
            );
          },
        ),
      ),
      body:
          hasHistory
              ? ListView.builder(
                padding: const EdgeInsets.all(16.0),
                // 🎯 使用過濾後的 selectedDateHistory
                itemCount: selectedDateHistory.length,
                itemBuilder: (context, index) {
                  final item = selectedDateHistory[index];

                  final String recommendedTimingStr =
                      item['recommended_caffeine_intake_timing'] ?? 'N/A';
                  // 假設攝取量是數字或字串
                  final recommendedAmount =
                      item['recommended_caffeine_amount'] ?? 'N/A';

                  String formattedTime;
                  try {
                    final utcDateTime = DateTime.parse(recommendedTimingStr);
                    // 轉換為本地時間，並顯示月/日 時:分
                    final localDateTime = utcDateTime.toLocal();
                    formattedTime = DateFormat(
                      'MM/dd HH:mm',
                    ).format(localDateTime);
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
                            "咖啡因建議",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: _accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "建議攝取時間：$formattedTime",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.local_cafe,
                                color: _accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "建議攝取量：$recommendedAmount 毫克",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _textColor,
                                ),
                              ),
                            ],
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
                        "$formattedDate 尚無建議歷史紀錄", // 🎯 變更提示文字
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "您可以在日曆上選擇其他日期或新增該日的建議。", // 🎯 變更提示文字
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
