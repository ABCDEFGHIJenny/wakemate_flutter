import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart';
import 'CaffeineRecommendationPage.dart';
import 'CaffeineHistory.dart';
import 'WakeTimeLogPage.dart';
import 'SleepTimeLogPage.dart';
import 'CaffeineLogPage.dart';
import 'UserInputHistoryPage.dart';

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

  final Color _primaryColor = const Color(0xFF4B6B7A); // 深灰藍
  final Color _accentColor = const Color(0xFF8BB9A1); // 柔綠藍
  final Color _bgLight = const Color(0xFFF9F9F7); // 米白
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

  // --- 您的所有後台邏輯 (保持不變) ---
  Future<void> _navigateToRecommendationHistoryPage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('caffeine_recommendations');
    List<dynamic> historyData = [];
    if (jsonData != null) {
      try {
        historyData = json.decode(jsonData);
      } catch (_) {}
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

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '新增紀錄',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const Divider(thickness: 0.8),
              _buildOptionTile(
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
              _buildOptionTile(
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
              _buildOptionTile(
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

  Widget _buildOptionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _accentColor, size: 26),
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
  // --- 邏輯結束 ---

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('yyyy/MM/dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: _bgLight,
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
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 3,
        shadowColor: Colors.black12,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, size: 30, color: _primaryColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          // ⚠️ 修正 #1：移除了 mainAxisAlignment: MainAxisAlignment.spaceBetween
          // 讓內容從頂部開始自然排列
          children: [
            // Header 區：日期 + 歡迎語 (保持不變)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "今日：$today",
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Hello ${widget.userName.isNotEmpty ? widget.userName : '使用者'} ☀️",
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 📌 新增：固定的間距
            const SizedBox(height: 15),

            // 日曆卡 (保持不變)
            Flexible(
              // 修正 #2：移除 flex: 5。
              // 由於這是 Column 中唯一的 Flexible 元件，它會自動填滿所有剩餘空間
              // flex: 1, (或直接移除 flex 屬性)
              child: Container(
                // 修正 #3：移除了 margin，改用SizedBox控制
                // margin: const EdgeInsets.only(top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  // --- 日曆內容保持不變 ---
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
                    cellMargin: const EdgeInsets.all(2.0),
                    selectedDecoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(color: _primaryColor),
                    weekendTextStyle: TextStyle(color: _primaryColor),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    headerPadding: const EdgeInsets.symmetric(vertical: 15.0),
                    titleTextStyle: TextStyle(
                      color: _primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: _accentColor,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: _accentColor,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: _primaryColor.withOpacity(0.8),
                    ),
                    weekendStyle: TextStyle(color: _accentColor),
                  ),
                ),
              ),
            ),

            // 新增：固定的間距
            const SizedBox(height: 50),

            // 下方按鈕群組
            Column(
              // ⚠️ 修正 #5：移除了 mainAxisAlignment: MainAxisAlignment.spaceEvenly
              children: [
                Row(
                  // --- 按鈕 1 (新增紀錄) ---
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () => _showAddOptions(context),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          '新增紀錄',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // --- 按鈕 2 (輸入歷史) ---
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor, width: 1.8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _navigateToUserInputHistoryPage,
                        icon: const Icon(Icons.edit_note),
                        label: const Text(
                          '輸入歷史',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 📌 新增：固定的間距
                const SizedBox(height: 12),

                Row(
                  children: [
                    // --- 按鈕 3 (計算推薦) ---
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
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
                        icon: const Icon(Icons.auto_graph, size: 22),
                        label: const Text(
                          '計算推薦',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // --- 按鈕 4 (推薦結果) ---
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(color: _accentColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _navigateToRecommendationHistoryPage,
                        icon: const Icon(Icons.history, size: 22),
                        label: const Text(
                          '推薦結果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
