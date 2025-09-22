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

  @override
  Widget build(BuildContext context) {
    bool hasHistory = recommendationData.isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "咖啡因建議結果",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
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
                itemCount: recommendationData.length,
                itemBuilder: (context, index) {
                  final item = recommendationData[index];

                  final String recommendedTimingStr =
                      item['recommended_caffeine_intake_timing'] ?? 'N/A';
                  final recommendedAmount =
                      item['recommended_caffeine_amount'] ?? 'N/A';

                  String formattedTime;
                  try {
                    final utcDateTime = DateTime.parse(recommendedTimingStr);
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
                        "目前沒有歷史紀錄",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "完成一次咖啡因建議後，您的結果會顯示在這裡。",
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
