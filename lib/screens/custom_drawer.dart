import 'package:flutter/material.dart';
import 'package:my_app/screens/LoginPage.dart';
import 'package:my_app/screens/alertness_test.dart';
import 'package:my_app/screens/personalSettingsPage.dart';

class CustomDrawer extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const CustomDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  // 輔助函式，用於建立統一風格的列表項目
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    const Color primaryColor = Color(0xFF1F3D5B);

    // ListTile 預設有垂直 padding，我們利用它來控制間距，不額外加 SizedBox
    return ListTile(
      leading: Icon(icon, color: primaryColor, size: 26),
      title: Text(
        title,
        style: const TextStyle(color: primaryColor, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  // 建立分隔線，並使用 Padding 調整它與周圍項目的距離
  Widget _buildSeparator() {
    // 增加垂直 padding 來實現視覺上的分隔空間
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Divider(
        height: 1, // 讓線條本身非常細
        thickness: 1, // 線條厚度
        color: const Color(0xFF1F3D5B).withOpacity(0.2), // 使用淺色分隔線
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 統一的顏色定義
    const Color primaryColor = Color(0xFF1F3D5B); // 深藍色
    const Color accentColor = Color(0xFF5E91B3); // 較淺的藍色

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 重新設計的 DrawerHeader
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: accentColor,
                  radius: 30,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // 選項列表
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: "個人身體數據",
            onTap: () {
              Navigator.pop(context); // 關閉 Drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(userId: userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bolt_outlined,
            title: "清醒度測試",
            onTap: () {
              Navigator.pop(context); // 關閉 Drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertnessTestPage(userId: userId),
                ),
              );
            },
          ),

          // 修正點：使用自定義的 _buildSeparator 函式控制登出區塊間距
          _buildSeparator(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: "登出",
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
