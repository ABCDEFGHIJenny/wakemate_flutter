import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart';
import 'CaffeineRecommendationPage.dart';
import 'CaffeineHistory.dart';

import 'SleepTimeLogPage.dart';
import 'WakeTimeLogPage.dart';
import 'CaffeineLogPage.dart';

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

  // 顏色變數
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
                // 傳遞使用者選取的日期給歷史紀錄頁面
                selectedDate: _selectedDate,
              ),
        ),
      );
    }
  }

  // ============== 修正：顯示新增選項的 Modal Bottom Sheet ==============
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 拖曳指示器
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              // 標題
              Text(
                '新增紀錄',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const Divider(),

              // 1. 目標清醒時間 (Target Wake Time)
              _buildOptionTile(
                context,
                title: '目標清醒時間',
                icon: Icons.wb_sunny_outlined,
                onTap: () {
                  Navigator.pop(context); // 關閉 Bottom Sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TargetWakeTimePage(
                            // 導向目標清醒頁面
                            userId: widget.userId,
                            selectedDate: _selectedDate,
                          ),
                    ),
                  );
                },
              ),

              // 2. 實際睡眠時間 (Actual Sleep Time)
              _buildOptionTile(
                context,
                title: '實際睡眠時間',
                icon: Icons.bed_outlined,
                onTap: () {
                  Navigator.pop(context); // 關閉 Bottom Sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ActualSleepTimePage(
                            // 導向實際睡眠頁面
                            userId: widget.userId,
                            selectedDate: _selectedDate,
                          ),
                    ),
                  );
                },
              ),

              // 3. 咖啡因紀錄選項
              _buildOptionTile(
                context,
                title: '咖啡因紀錄',
                icon: Icons.local_cafe_outlined,
                onTap: () {
                  Navigator.pop(context); // 關閉 Bottom Sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CaffeineLogPage(
                            userId: widget.userId,
                            selectedDate: _selectedDate, // 傳遞選取的日期
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============== 共用的 ListTile 建立方法 ==============
  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _primaryColor, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: _primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: _accentColor, size: 18),
      onTap: onTap,
    );
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
                      // 點擊新增按鈕時，顯示選項 Bottom Sheet
                      _showAddOptions(context);
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
