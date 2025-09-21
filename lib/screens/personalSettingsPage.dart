import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  final String userId;
  const SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _gender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();

  bool _isLoading = false;
  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';
  String? _existingRecordId;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    // 監聽身高和體重變化以自動計算 BMI
    _heightController.addListener(_calculateBMI);
    _weightController.addListener(_calculateBMI);
  }

  // 自動計算 BMI
  void _calculateBMI() {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final double bmi = weight / ((height / 100) * (height / 100));
      _bmiController.text = bmi.toStringAsFixed(2); // 保留兩位小數
    } else {
      _bmiController.text = '';
    }
  }

  Future<void> _loadUserSettings() async {
    setState(() => _isLoading = true); // 開始加載時顯示 loading 狀態
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users_body_info/?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final userData = data[0];
          _existingRecordId = userData['id']?.toString();
          setState(() {
            _gender = userData['gender'] ?? null;
            _ageController.text = userData['age']?.toString() ?? '';
            _heightController.text = userData['height']?.toString() ?? '';
            _weightController.text = userData['weight']?.toString() ?? '';
            _bmiController.text = userData['bmi']?.toString() ?? '';
          });
        } else {
          print("尚未有資料，第一次使用");
        }
      } else {
        print("讀取資料失敗：${res.body}");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("讀取資料失敗: ${res.statusCode}")));
        }
      }
    } catch (e) {
      print("讀取資料錯誤：$e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("讀取資料錯誤：$e")));
      }
    } finally {
      setState(() => _isLoading = false); // 加載結束時隱藏 loading 狀態
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _gender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("請完整填寫所有必填資料並選擇性別")));
      return;
    }

    setState(() => _isLoading = true);

    final body = {
      "user_id": widget.userId,
      "gender": _gender,
      "age": int.tryParse(_ageController.text) ?? 0,
      "height": double.tryParse(_heightController.text) ?? 0,
      "weight": double.tryParse(_weightController.text) ?? 0,
      "bmi": double.tryParse(_bmiController.text) ?? 0,
    };

    try {
      http.Response res;

      if (_existingRecordId != null) {
        // 更新
        res = await http.put(
          Uri.parse('$baseUrl/users_body_info/${_existingRecordId!}/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        // 新增
        res = await http.post(
          Uri.parse('$baseUrl/users_body_info/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          final savedData = jsonDecode(res.body);
          _existingRecordId = savedData['id']?.toString();
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("設定已保存成功！")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("保存失敗：${res.body}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("錯誤：$e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "個人身體數據",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // 更吸引人的 AppBar 顏色
        elevation: 0,
      ),
      body:
          _isLoading && _existingRecordId == null
              ? const Center(child: CircularProgressIndicator()) // 初次加載時顯示圓形進度條
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20), // 增加整體內邊距
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "性別",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("男"),
                              value: "M",
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                              activeColor: Colors.blueAccent,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("女"),
                              value: "F",
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                              activeColor: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // 增加間距
                      _buildTextFormField(
                        controller: _ageController,
                        labelText: "年齡",
                        hintText: "請輸入您的年齡",
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "年齡為必填項";
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return "請輸入有效的年齡";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _heightController,
                        labelText: "身高 (cm)",
                        hintText: "請輸入您的身高",
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "身高為必填項";
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return "請輸入有效身高";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _weightController,
                        labelText: "體重 (kg)",
                        hintText: "請輸入您的體重",
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "體重為必填項";
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return "請輸入有效體重";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _bmiController,
                        labelText: "BMI",
                        hintText: "將自動計算您的 BMI",
                        keyboardType: TextInputType.number,
                        readOnly: true, // BMI 自動計算，設為只讀
                        fillColor: Colors.grey[100], // 淺灰色背景表示只讀
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(
                            _isLoading ? "保存中..." : "保存設定",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // 輔助函式，用於建立統一風格的 TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: fillColor ?? Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
    );
  }
}
