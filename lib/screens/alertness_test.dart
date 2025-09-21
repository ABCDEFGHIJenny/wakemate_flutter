import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertnessTestPage extends StatefulWidget {
  final String userId;

  const AlertnessTestPage({super.key, required this.userId});

  @override
  State<AlertnessTestPage> createState() => _AlertnessTestPageState();
}

class _AlertnessTestPageState extends State<AlertnessTestPage> {
  Timer? _timer;
  bool _isWaiting = true;
  bool _testStarted = false;
  Color _boxColor = const Color(0xFF67B7F9); // 簡潔的藍色
  String _resultMessage = "點擊開始";
  DateTime? _startTime;
  final List<Duration> _reactionTimes = [];
  int _currentTrial = 0;
  final int _totalTrials = 6;
  bool _isError = false;

  int _lapses = 0;
  int _falseStarts = 0;

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';
  int? _selectedKssLevel;

  void _startTest() {
    setState(() {
      _reactionTimes.clear();
      _currentTrial = 0;
      _lapses = 0;
      _falseStarts = 0;
      _resultMessage = "請等待...";
    });
    _runTestSequence();
  }

  void _runTestSequence() {
    if (_currentTrial >= _totalTrials) {
      _testCompleted();
      return;
    }

    setState(() {
      _isWaiting = true;
      _testStarted = true;
      _boxColor = const Color(0xFF67B7F9);
      _isError = false;
    });

    int randomDelay = 1000 + Random().nextInt(4000);
    _timer = Timer(Duration(milliseconds: randomDelay), () {
      if (!mounted) return;
      setState(() {
        _isWaiting = false;
        _boxColor = const Color(0xFF32C669); // 簡潔的綠色
        _startTime = DateTime.now();
        _resultMessage = "請點擊！";
      });

      _timer = Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        if (_boxColor == const Color(0xFF32C669)) {
          _lapses++;
          _runTestSequence();
        }
      });
    });
  }

  void _boxTapped() {
    if (!_testStarted) return;

    if (_isWaiting) {
      _timer?.cancel();
      setState(() {
        _testStarted = false;
        _boxColor = const Color(0xFFE53935); // 簡潔的紅色
        _isError = true;
        _resultMessage = "❌ 點太快了！重來";
        _falseStarts++;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _runTestSequence();
        }
      });
    } else {
      _timer?.cancel();
      final reaction = DateTime.now().difference(_startTime!);
      _reactionTimes.add(reaction);
      _currentTrial++;

      setState(() {
        _testStarted = false;
        _boxColor = const Color(0xFF67B7F9);
        _isError = false;
        _resultMessage = "第$_currentTrial次: ${reaction.inMilliseconds} 毫秒";
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _runTestSequence();
        }
      });
    }
  }

  void _testCompleted() {
    setState(() {
      _testStarted = false;
      _boxColor = const Color(0xFF67B7F9);
    });

    final avgTime = _averageReactionTime();
    _showResultDialog(avgTime);
  }

  String _getKssDescription(int level) {
    switch (level) {
      case 1:
        return "非常清醒";
      case 2:
        return "非常清醒，努力集中注意力";
      case 3:
        return "清醒，不費力";
      case 4:
        return "有點清醒，有一點費力";
      case 5:
        return "清醒，但有些疲勞";
      case 6:
        return "清醒，但感覺有點睏";
      case 7:
        return "清醒，但很睏，需要努力保持清醒";
      case 8:
        return "非常睏，努力保持清醒";
      case 9:
        return "非常睏，已經睡著了";
      default:
        return "";
    }
  }

  void _showResultDialog(double avgTime) {
    setState(() {
      _selectedKssLevel = null;
    });

    final List<int> kssLevels = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "測試結果",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  "每次反應時間：",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                ..._reactionTimes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Duration time = entry.value;
                  return Text(
                    "第${index + 1}次：${time.inMilliseconds} 毫秒",
                    style: const TextStyle(color: Color(0xFF777777)),
                  );
                }).toList(),
                const Divider(
                  height: 30,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Text(
                  "平均反應時間：${avgTime.toStringAsFixed(2)} 毫秒",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF42A5F5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "選擇您覺得的清醒程度:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    return DropdownButton<int>(
                      value: _selectedKssLevel,
                      isExpanded: true,
                      hint: const Text("選擇 KSS 分數"),
                      items:
                          kssLevels.map((int level) {
                            return DropdownMenuItem<int>(
                              value: level,
                              child: Text(
                                "$level - ${_getKssDescription(level)}",
                              ),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        setInnerState(() {
                          _selectedKssLevel = newValue;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sendAverageReactionTime(
                  avgTime,
                  _selectedKssLevel,
                  _lapses,
                  _falseStarts,
                );
                Navigator.of(context).pop();
                _startTest();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF42A5F5),
              ),
              child: const Text("再測一次"),
            ),
            TextButton(
              onPressed: () {
                _sendAverageReactionTime(
                  avgTime,
                  _selectedKssLevel,
                  _lapses,
                  _falseStarts,
                );
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF42A5F5),
              ),
              child: const Text("關閉"),
            ),
          ],
        );
      },
    );
  }

  double _averageReactionTime() {
    if (_reactionTimes.isEmpty) return 0;
    final totalMs = _reactionTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    return totalMs / _reactionTimes.length;
  }

  Future<void> _sendAverageReactionTime(
    double avgTime,
    int? kssLevel,
    int lapses,
    int falseStarts,
  ) async {
    final url = Uri.parse('$baseUrl/users_pvt');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'mean_rt': avgTime,
          'lapses': lapses,
          'false_starts': falseStarts,
          'kss_level': kssLevel,
          'device': 'Mobile',
          'test_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print('平均反應時間和 KSS 等級已成功送出');
        print('伺服器回應: ${res.body}');
      } else {
        print('送出失敗，狀態碼：${res.statusCode}');
        print('錯誤訊息：${res.body}');
      }
    } catch (e) {
      print('送出錯誤：$e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "清醒度測試",
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _resultMessage,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color:
                        _isError
                            ? const Color(0xFFE53935)
                            : const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _boxTapped,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: _boxColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _boxColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        !_testStarted
                            ? const Text(
                              "點擊此處",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: !_testStarted ? _startTest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("開始測試"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
