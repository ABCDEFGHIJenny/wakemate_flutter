import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart';
import 'CaffeineRecommendationPage.dart';
import 'CaffeineHistory.dart'; // 推薦結果歷史頁

// 確保這些導入與您的檔案名稱完全一致
import 'WakeTimeLogPage.dart';
import 'SleepTimeLogPage.dart';
import 'CaffeineLogPage.dart';
import 'UserInputHistoryPage.dart'; // 假設這個檔案存在

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

  // 導航到推薦結果歷史頁
  Future<void> _navigateToRecommendationHistoryPage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('caffeine_recommendations');

    List<dynamic> historyData = [];
    if (jsonData != null) {
      try {
        historyData = json.decode(jsonData);
      } catch (e) {
        historyData = [];
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CaffeineHistoryPage(
                userId: widget.userId,
                selectedDate: _selectedDate,
              ),
        ),
      );
    }
  }

  // 導航到使用者輸入歷史頁
  void _navigateToUserInputHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UserInputHistoryPage(
              userId: widget.userId,
              selectedDate: _selectedDate,
            ),
      ),
    );
  }

  // ============== 顯示新增選項的 Modal Bottom Sheet (保持不變) ==============
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

              // 1. 清醒時段
              _buildOptionTile(
                context,
                title: '清醒時段',
                icon: Icons.wb_sunny_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TargetWakeTimePage(
                            userId: widget.userId,
                            selectedDate: _selectedDate,
                          ),
                    ),
                  );
                },
              ),

              // 2. 睡眠時段
              _buildOptionTile(
                context,
                title: '睡眠時段',
                icon: Icons.bed_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ActualSleepTimePage(
                            userId: widget.userId,
                            selectedDate: _selectedDate,
                          ),
                    ),
                  );
                },
              ),

              // 3. 咖啡因紀錄
              _buildOptionTile(
                context,
                title: '咖啡因紀錄',
                icon: Icons.local_cafe_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CaffeineLogPage(
                            userId: widget.userId,
                            selectedDate: _selectedDate,
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

  // ============== 共用的 ListTile 建立方法 (保持不變) ==============
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

  // ============== 主要頁面建構 ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
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
        padding: const EdgeInsets.fromLTRB(
          20.0,
          0.0,
          20.0,
          40.0, // 增加底部 padding
        ),
        child: Column(
          children: [
            // 日曆元件 (使用 Card 提升質感)
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDate,
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
            Column(
              children: [
                // 1. 新增紀錄 + 輸入歷史 (第一排)
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
                        onPressed: () => _showAddOptions(context),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          '新增紀錄',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      // 導航到使用者輸入歷史頁面的按鈕
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _navigateToUserInputHistoryPage,
                        icon: const Icon(Icons.edit_note),
                        label: const Text(
                          '輸入歷史',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. 計算推薦 + 推薦結果歷史 (第二排)
                Row(
                  children: [
                    // 計算推薦 (主按鈕，使用 accentColor 突出)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 8,
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
                        icon: const Icon(Icons.auto_graph, size: 24),
                        label: const Text(
                          '計算推薦',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // 推薦結果歷史 (次要按鈕，搭配計算推薦)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _accentColor, // 使用 accentColor 邊框，與計算按鈕相關聯
                          side: BorderSide(color: _accentColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _navigateToRecommendationHistoryPage,
                        icon: const Icon(Icons.history, size: 24),
                        label: const Text(
                          '推薦結果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
