# gpt第一次

## 第一步：添加依赖
你的 Flutter 代码使用了 shared_preferences 进行本地存储，在 Kotlin 中，我们可以使用 SharedPreferences。

修改 app/build.gradle (Module: app)，在 dependencies 里添加：

```gradle
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.preference:preference:1.2.1'
    implementation 'com.google.code.gson:gson:2.10.1' // 用于 JSON 解析
}
```
然后点击 Sync Now 让 Gradle 同步依赖。

## 第二步：创建 TaskManager 类
这个类用于管理任务的存储和加载，相当于 Flutter 代码里的 SharedPreferences 逻辑。

在 app/src/main/java/com/你的包名/ 下新建 TaskManager.kt：

```kotlin
package com.caijw.gametask

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class TaskManager(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("task_prefs", Context.MODE_PRIVATE)
    private val gson = Gson()

    // 任务状态存储
    private var taskStatus: MutableMap<String, String> = loadTaskStatus()

    // 任务数据（固定）
    val taskGroups: Map<String, List<String>> = mapOf(
        "QQ" to listOf("签到"),
        "心悦俱乐部" to listOf(
            "游戏礼包", "G分-签到", "G分-赚G分-预约游戏", "G分-赚G分-访问心悦面板",
            "G分-赚G分-交易商城", "G分-赚G分-启动游戏", "G分-赚G分-G分兑换"
        ),
        "闪现一下" to listOf("积分"),
        "大号" to listOf("签到", "摇钱树号码", "福利-任务", "远征奖励", "招募", "征讨", "充值", "工会签到", "扫荡"),
        "小号" to listOf("签到", "福利-任务", "远征奖励", "招募", "征讨", "工会签到", "扫荡")
    )

    fun loadTaskStatus(): MutableMap<String, String> {
        val json = prefs.getString("task_status", "{}")
        val type = object : TypeToken<MutableMap<String, String>>() {}.type
        return gson.fromJson(json, type) ?: mutableMapOf()
    }

    fun saveTaskStatus() {
        prefs.edit().putString("task_status", gson.toJson(taskStatus)).apply()
    }

    fun updateTaskStatus(groupName: String, task: String, status: String) {
        val uniqueTaskId = "$groupName-$task"
        taskStatus[uniqueTaskId] = status
        saveTaskStatus()
    }

    fun getPendingTasks(): List<String> {
        return taskGroups.flatMap { (group, tasks) ->
            tasks.map { task -> "$group-$task" }
        }.filter { taskStatus[it] != "已完成" && taskStatus[it] != "忽略" }
    }

    fun calculateProgress(): Float {
        val completedCount = taskStatus.values.count { it == "已完成" || it == "忽略" }
        val totalTasks = taskGroups.values.flatten().size
        return if (totalTasks == 0) 0f else completedCount.toFloat() / totalTasks
    }
}
```

## 第三步：修改 MainActivity.kt

打开 MainActivity.kt，替换成以下代码：

```kotlin
package com.caijw.gametask

import android.content.Context
import android.os.Bundle
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.setPadding

class MainActivity : AppCompatActivity() {
    private lateinit var taskManager: TaskManager
    private lateinit var progressBar: ProgressBar
    private lateinit var taskListLayout: LinearLayout
    private lateinit var startTaskButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        taskManager = TaskManager(this)
        progressBar = findViewById(R.id.progressBar)
        taskListLayout = findViewById(R.id.taskListLayout)
        startTaskButton = findViewById(R.id.startTaskButton)

        updateUI()

        startTaskButton.setOnClickListener { startTaskProcess() }
    }

    private fun updateUI() {
        progressBar.progress = (taskManager.calculateProgress() * 100).toInt()
        taskListLayout.removeAllViews()

        taskManager.taskGroups.forEach { (groupName, tasks) ->
            val groupTextView = TextView(this).apply {
                text = groupName
                setPadding(16, 20, 16, 10)
                setTextColor(resources.getColor(android.R.color.darker_gray, null))
            }
            taskListLayout.addView(groupTextView)

            tasks.forEach { task ->
                val uniqueTaskId = "$groupName-$task"
                val taskStatus = taskManager.loadTaskStatus()[uniqueTaskId] ?: "未处理"
                val taskView = TextView(this).apply {
                    text = "$task - $taskStatus"
                    setPadding(16)
                    setOnClickListener { showTaskDialog(groupName, task) }
                }
                taskListLayout.addView(taskView)
            }
        }
    }

    private fun showTaskDialog(groupName: String, task: String) {
        val builder = AlertDialog.Builder(this)
            .setTitle("当前任务")
            .setMessage("$groupName - $task")
            .setPositiveButton("已完成") { _, _ ->
                taskManager.updateTaskStatus(groupName, task, "已完成")
                updateUI()
            }
            .setNegativeButton("忽略") { _, _ ->
                taskManager.updateTaskStatus(groupName, task, "忽略")
                updateUI()
            }
            .setNeutralButton("跳过", null)

        builder.create().show()
    }

    private fun startTaskProcess() {
        val pendingTasks = taskManager.getPendingTasks()
        if (pendingTasks.isEmpty()) {
            Toast.makeText(this, "今日任务已完成", Toast.LENGTH_SHORT).show()
            return
        }
        val firstTask = pendingTasks.first().split("-")
        showTaskDialog(firstTask[0], firstTask.drop(1).joinToString("-"))
    }
}
```

## 第四步：修改 activity_main.xml
打开 res/layout/activity_main.xml，替换成以下内容：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <ProgressBar
        android:id="@+id/progressBar"
        style="?android:attr/progressBarStyleHorizontal"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:max="100" />

    <ScrollView
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1">
        <LinearLayout
            android:id="@+id/taskListLayout"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"/>
    </ScrollView>

    <Button
        android:id="@+id/startTaskButton"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="做任务" />
</LinearLayout>
```

然后闪退了，是因为themes.xml的Theme.GameTask的parent错误，改成Theme.AppCompat.Light.DarkActionBar就好了


