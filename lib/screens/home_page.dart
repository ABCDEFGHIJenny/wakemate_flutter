import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart';
import 'CaffeineRecommendationPage.dart';
import 'CaffeineHistory.dart';

// 確保這些導入與您的檔案名稱完全一致
import 'WakeTimeLogPage.dart';
import 'SleepTimeLogPage.dart';
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
                recommendationData: historyData,
                userId: widget.userId,
                selectedDate: _selectedDate,
              ),
        ),
      );
    }
  }

  // ============== 顯示新增選項的 Modal Bottom Sheet ==============
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

              // 1. 清醒時段 (使用 WakeTimeLogPage)
              _buildOptionTile(
                context,
                title: '清醒時段', // 修正為您要求的名稱
                icon: Icons.wb_sunny_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 導航到 WakeTimeLogPage
                      builder:
                          (context) => TargetWakeTimePage(
                            userId: widget.userId,
                            selectedDate: _selectedDate,
                          ),
                    ),
                  );
                },
              ),

              // 2. 睡眠時段 (使用 SleepTimeLogPage)
              _buildOptionTile(
                context,
                title: '睡眠時段', // 修正為您要求的名稱
                icon: Icons.bed_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 導航到 SleepTimeLogPage
                      builder:
                          (context) => ActualSleepTimePage(
                            userId: widget.userId,
                            selectedDate: _selectedDate,
                          ),
                    ),
                  );
                },
              ),

              // 3. 咖啡因紀錄選項 (使用 CaffeineLogPage)
              _buildOptionTile(
                context,
                title: '咖啡因紀錄', // 修正為您要求的名稱
                icon: Icons.local_cafe_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 導航到 CaffeineLogPage
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

  // ============== 主要頁面建構 ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor, // 設定整個背景為淺灰色
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
        backgroundColor: Colors.transparent, // AppBar 透明
        elevation: 0, // 移除陰影
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
          40.0,
        ), // 增加底部 padding
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

            // 按鈕區塊 (三顆按鈕重新排列)
            Column(
              children: [
                // 第一排：新增 + 歷史紀錄
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
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _navigateToHistoryPage,
                        icon: const Icon(Icons.history),
                        label: const Text(
                          '歷史紀錄',
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

                // 第二排：計算推薦 (放大突出)
                SizedBox(
                  width: double.infinity, // 佔滿寬度
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor, // 使用較亮顏色，突出
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8, // 增加陰影，更突出
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
                      '計算咖啡因推薦',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
