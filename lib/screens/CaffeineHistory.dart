import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:intl/intl.dart';

class CaffeineHistoryPage extends StatelessWidget {
  final List<dynamic> recommendationData;
  final String userId;

  const CaffeineHistoryPage({
    super.key,
    this.recommendationData = const [],
    required this.userId,
  });

  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 淺藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _textColor = const Color(0xFF424242); // 深灰色文字

  // --- 新增的過濾方法 ---
  List<dynamic> _filterTodayData() {
    if (recommendationData.isEmpty) {
      return [];
    }

    // 取得今天的日期，並將時間部分設為午夜 00:00:00
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    return recommendationData.where((item) {
      final String recommendedTimingStr =
          item['recommended_caffeine_intake_timing'] ?? '';

      try {
        // 將 UTC 時間字串解析為 DateTime
        final utcDateTime = DateTime.parse(recommendedTimingStr);
        // 轉換為本地時間
        final localDateTime = utcDateTime.toLocal();

        // 檢查該紀錄的時間是否在今天或之後
        // (因為 `recommendationData` 似乎是以日期時間順序排列，
        // 這裡只需檢查它是否在今天的午夜 00:00:00 之後)
        return localDateTime.isAfter(today);
      } catch (e) {
        // 解析失敗的數據一律不顯示
        return false;
      }
    }).toList();
  }
  // --- 新增的過濾方法結束 ---

  @override
  Widget build(BuildContext context) {
    // 過濾出今天的歷史紀錄
    final todayHistory = _filterTodayData();
    bool hasHistory = todayHistory.isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        // 將標題改為「今日咖啡因建議結果」以反映過濾後的內容
        title: Text(
          "今日咖啡因建議結果",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            // 確保返回到 HomePage
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
                // *** 使用過濾後的 todayHistory ***
                itemCount: todayHistory.length,
                itemBuilder: (context, index) {
                  final item = todayHistory[index];

                  final String recommendedTimingStr =
                      item['recommended_caffeine_intake_timing'] ?? 'N/A';
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
                        "今日尚無建議歷史紀錄", // 變更提示文字
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "完成今日咖啡因建議後，結果將顯示在這裡。", // 變更提示文字
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
