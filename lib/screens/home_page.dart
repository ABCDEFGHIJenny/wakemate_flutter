import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart';
import 'CaffeineRecommendationPage.dart';
import 'CaffeineHistory.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String email;

  const HomePage({
    super.key,
    required this.userId,
    this.userName = "",
    this.email = "",
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  // 將顏色變數定義放在這裡，因為它們是狀態的一部分
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 較淺的藍色
  final Color _secondaryColor = const Color(0xFFF0F0F0); // 淺灰色背景

  @override
  void initState() {
    super.initState();
    // 初始化為當前日期
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

  // ============== 修正：傳遞 _selectedDate 參數 ==============
  Future<void> _navigateToHistoryPage() async {
    final prefs = await SharedPreferences.getInstance();
    // 這裡假設您的 SharedPreferences key 是 'caffeine_recommendations'
    final String? jsonData = prefs.getString('caffeine_recommendations');

    List<dynamic> historyData = [];
    if (jsonData != null) {
      try {
        // 解析儲存的 JSON 字串
        historyData = json.decode(jsonData);
      } catch (e) {
        // 解析失敗，設定為空列表
        historyData = [];
        // 您可以添加 log 資訊來追蹤錯誤
        // print('Error decoding caffeine history data: $e');
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CaffeineHistoryPage(
                recommendationData: historyData,
                userId: widget.userId,
                // *** 修正點：傳遞使用者選取的日期給歷史紀錄頁面 ***
                selectedDate: _selectedDate,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 CustomDrawer
      drawer: CustomDrawer(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.email,
      ),
      appBar: AppBar(
        title: Text(
          "WakeMate",
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, size: 30, color: _primaryColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 日曆元件
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDate,
                // 確保只比較日期部分
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDate = selected;
                    _focusedDate = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: _primaryColor),
                  weekendTextStyle: TextStyle(color: _primaryColor),
                  markerDecoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: _primaryColor,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: _primaryColor,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: _accentColor),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 按鈕區塊
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CaffeineRecommendationPage(
                                userId: widget.userId,
                                selectedDate: _selectedDate,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('新增', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _navigateToHistoryPage, // 觸發帶參數的跳轉
                    icon: const Icon(Icons.history),
                    label: const Text('歷史紀錄', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: _secondaryColor,
        child: const SizedBox(height: 60),
      ),
    );
  }
}
