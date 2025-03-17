import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DailyTaskPage(),
    );
  }
}

class DailyTaskPage extends StatefulWidget {
  @override
  _DailyTaskPageState createState() => _DailyTaskPageState();
}

class _DailyTaskPageState extends State<DailyTaskPage> {
  final Map<String, List<String>> taskGroups = {
    "QQ": ["签到"],
    "心悦俱乐部": [
      "游戏礼包",
      "G分-签到",
      "G分-赚G分-预约游戏",
      "G分-赚G分-访问心悦面板",
      "G分-赚G分-交易商城",
      "G分-赚G分-启动游戏",
      "G分-赚G分-G分兑换"
    ],
    "闪现一下": ["积分"],
    "大号": ["签到", "摇钱树号码", "福利-任务", "远征奖励", "招募", "征讨", "充值", "工会签到", "扫荡"],
    "小号": ["签到", "福利-任务", "远征奖励", "招募", "征讨", "工会签到", "扫荡"],
  };

  Map<String, String> taskStatus = {}; // 存储任务状态

  @override
  void initState() {
    super.initState();
    _loadTaskStatus();
  }

  Future<void> _loadTaskStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString("task_status");
    if (savedData != null) {
      setState(() {
        taskStatus = Map<String, String>.from(json.decode(savedData));
      });
    }
  }

  Future<void> _saveTaskStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status", json.encode(taskStatus));
  }

  void _updateTaskStatus(String groupName, String task, String status) {
    String uniqueTaskId = "$groupName-$task"; // 使用分组名+任务名作为唯一标识符
    setState(() {
      taskStatus[uniqueTaskId] = status;
    });
    _saveTaskStatus();
  }

  List<String> _getPendingTasks() {
    List<String> pendingTasks = [];
    taskGroups.forEach((groupName, tasks) {
      for (var task in tasks) {
        String uniqueTaskId = "$groupName-$task"; // 确保唯一标识符
        if (taskStatus[uniqueTaskId] != "已完成" &&
            taskStatus[uniqueTaskId] != "忽略") {
          pendingTasks.add(uniqueTaskId);
        }
      }
    });
    return pendingTasks;
  }

  void _startTaskProcess([int index = 0]) {
    if (_calculateProgress() >= 1.0) {
      Fluttertoast.showToast(msg: "今日任务已完成", gravity: ToastGravity.CENTER);
      return;
    }
    List<String> pendingTasks = _getPendingTasks();
    if (pendingTasks.isNotEmpty) {
      _showTaskDialog(pendingTasks, index);
    }
  }

  void _showTaskDialog(List<String> tasks, int index) {
    index %= tasks.length;
    String uniqueTaskId = tasks[index];
    List<String> parts = uniqueTaskId.split('-');
    String groupName = parts[0];
    String task = parts.sublist(1).join('-'); // 防止任务名带有 - 误拆

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          "当前任务",
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 250, // 设定一个固定宽度
          child: Text(
            '$groupName - $task',
            softWrap: true,
            textAlign: TextAlign.left,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // 按钮居中排列
            children: [
              TextButton(
                onPressed: () {
                  _updateTaskStatus(groupName, task, "已完成");
                  Navigator.pop(context);
                  _startTaskProcess(index);
                },
                child: Text("已完成"),
              ),
              SizedBox(width: 10), // 按钮间距
              TextButton(
                onPressed: () {
                  _updateTaskStatus(groupName, task, "忽略");
                  Navigator.pop(context);
                  _startTaskProcess(index);
                },
                child: Text("忽略"),
              ),
              SizedBox(width: 10), // 按钮间距
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showTaskDialog(tasks, index + 1);
                },
                child: Text("跳过"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    int completedCount =
        taskStatus.values.where((s) => s == "已完成" || s == "忽略").length;
    int totalTasks = taskGroups.values.expand((t) => t).length;
    return totalTasks == 0 ? 0 : completedCount / totalTasks;
  }

  @override
  Widget build(BuildContext context) {
    double progress = _calculateProgress();
    return Scaffold(
      appBar: AppBar(title: Text("每日任务")),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: ListView(
              children: taskGroups.entries.expand((entry) {
                String groupName = entry.key;
                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 15.0), // 调整行高，增加上下内边距
                    child:
                        Text(groupName, style: TextStyle(color: Colors.grey)),
                  ),
                  Divider(
                      height: 0.5, thickness: 0.2, indent: 0), // 每个分组名下方的分割线
                  ...entry.value.map((task) {
                    String uniqueTaskId = "$groupName-$task"; // 确保唯一
                    String taskStatusText = taskStatus[uniqueTaskId] ?? "未处理";
                    Color textColor = Colors.black;
                    if (taskStatusText == "已完成" || taskStatusText == "忽略") {
                      textColor = Colors.grey; // 置灰已完成或忽略的任务
                    }

                    return Column(
                      children: [
                        ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 20.0), // 调整任务的缩进
                          title: Text(
                            task,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: textColor),
                          ),
                          trailing:
                              taskStatusText == "已完成" || taskStatusText == "忽略"
                                  ? Text(taskStatusText,
                                      style: TextStyle(color: Colors.grey))
                                  : null,
                          onTap: taskStatusText == "未处理"
                              ? () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        "当前任务",
                                        textAlign: TextAlign.center,
                                      ),
                                      content: SizedBox(
                                        width: 250, // 设定一个固定宽度
                                        child: Text(
                                          '$groupName - $task',
                                          softWrap: true,
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      actions: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center, // 按钮居中排列
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                _updateTaskStatus(
                                                    groupName, task, "已完成");
                                                Navigator.pop(context);
                                              },
                                              child: Text("已完成"),
                                            ),
                                            SizedBox(width: 50), // 按钮间距
                                            TextButton(
                                              onPressed: () {
                                                _updateTaskStatus(
                                                    groupName, task, "忽略");
                                                Navigator.pop(context);
                                              },
                                              child: Text("忽略"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                              : null, // 禁用已完成和忽略任务的点击事件
                        ),
                        Divider(height: 0.5, thickness: 0.2, indent: 16),
                      ],
                    );
                  }).toList(),
                ];
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _startTaskProcess,
            child: Text("做任务"),
          ),
        ],
      ),
    );
  }
}
