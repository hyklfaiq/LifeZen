import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'notification_service.dart';
import 'storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  runApp(const LifeZenApp());
}
// ============================================================
// APP
// ============================================================

class LifeZenApp extends StatefulWidget {
  const LifeZenApp({super.key});

  @override
  State<LifeZenApp> createState() => _LifeZenAppState();
}

class _LifeZenAppState extends State<LifeZenApp> {
  ThemeMode themeMode = ThemeMode.light;
  bool isStarting = true;

  @override
  void initState() {
    super.initState();

    _startApp();
  }

  Future<void> _startApp() async {
    final isDark = await AppStorage.loadDarkMode();

    if (!mounted) return;

    setState(() {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isStarting = false;
    });
  }

  Future<void> toggleTheme() async {
    final newIsDark = themeMode != ThemeMode.dark;

    setState(() {
      themeMode = newIsDark ? ThemeMode.dark : ThemeMode.light;
    });

    await AppStorage.saveDarkMode(newIsDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeZen',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      themeMode: themeMode,

      home: isStarting
          ? const StartupScreen()
          : MainScreen(
              onToggleTheme: toggleTheme,
              isDarkMode: themeMode == ThemeMode.dark,
            ),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: 60,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'LifeZen',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Plan your day. Live better.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 40),

              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Task {
  final int id;
  String title;
  DateTime dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.completed = false,
  });
}

class SleepRecord {
  final int id;
  DateTime sleepTime;
  DateTime wakeTime;
  String? note;

  SleepRecord({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    this.note,
  });

  Duration get duration => wakeTime.difference(sleepTime);
}

class Expense {
  final int id;
  String title;
  double amount;
  String category;
  DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}

class SavingsGoal {
  String name;
  double targetAmount;
  double currentAmount;
  String? imagePath;

  SavingsGoal({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.imagePath,
  });

  double get progress {
    if (targetAmount <= 0) return 0;

    return (currentAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }
}

class ScheduleItem {
  final int id;
  String title;
  TimeOfDay time;
  List<int> repeatDays;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.repeatDays,
  });
}

// ============================================================
// MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Task> tasks = [];
  List<SleepRecord> sleepRecords = [];
  List<Expense> expenses = [];
  List<ScheduleItem> schedule = [];

  SavingsGoal? savingsGoal;

  double monthlyBudget = 800;
  int sleepGoalHours = 8;

  int firstDayOfWeek = 1;
  int currentIndex = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> setFirstDayOfWeek(int day) async {
    firstDayOfWeek = day;

    if (mounted) {
      setState(() {});
    }

    await AppStorage.saveFirstDayOfWeek(day);
  }

  Future<void> updateSleepGoal(int hours) async {
    sleepGoalHours = hours;

    await AppStorage.saveSleepGoal(hours);

    if (!mounted) return;

    setState(() {});
  }
  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> _loadData() async {
    final loadedTasks = await AppStorage.loadTasks();
    final loadedSleep = await AppStorage.loadSleepRecords();
    final loadedExpenses = await AppStorage.loadExpenses();
    final loadedSchedule = await AppStorage.loadSchedule();
    final loadedSavings = await AppStorage.loadSavingsGoal();
    final loadedSleepGoal = await AppStorage.loadSleepGoal();

    final loadedBudget = await AppStorage.loadBudget();
    final loadedFirstDay = await AppStorage.loadFirstDayOfWeek();

    tasks = loadedTasks.map(_taskFromMap).toList();

    sleepRecords = loadedSleep.map(_sleepFromMap).toList();

    expenses = loadedExpenses.map(_expenseFromMap).toList();

    schedule = loadedSchedule.map(scheduleFromMap).toList();

    monthlyBudget = loadedBudget;
    firstDayOfWeek = loadedFirstDay;
    sleepGoalHours = loadedSleepGoal;

    if (loadedSavings != null) {
      savingsGoal = _savingsFromMap(loadedSavings);
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    await _refreshNotifications();
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  Future<void> _refreshNotifications() async {
    try {
      await NotificationService.cancelAll();
    } catch (e) {
      debugPrint('Failed to clear notifications: $e');
    }

    for (final task in tasks) {
      if (!task.completed) {
        try {
          await NotificationService.scheduleTask(
            id: task.id,
            title: task.title,
            dateTime: task.dueDate,
          );
        } catch (e) {
          debugPrint('Failed to restore task notification: $e');
        }
      }
    }

    for (final item in schedule) {
      for (final day in item.repeatDays) {
        try {
          await NotificationService.scheduleWeekly(
            id: _scheduleNotificationId(item.id, day),
            title: item.title,
            weekday: day,
            hour: item.time.hour,
            minute: item.time.minute,
          );
        } catch (e) {
          debugPrint('Failed to restore schedule notification: $e');
        }
      }
    }
  }

  int _scheduleNotificationId(int scheduleId, int weekday) {
    return (scheduleId % 1000000) * 10 + weekday;
  }

  // ==========================================================
  // SCHEDULE
  // ==========================================================

  Future<void> addSchedule(ScheduleItem item) async {
    final newItem = ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: item.title,
      time: item.time,
      repeatDays: List<int>.from(item.repeatDays),
    );

    schedule.add(newItem);

    // Show it immediately
    if (mounted) {
      setState(() {});
    }

    // Save it
    await AppStorage.saveSchedule(schedule.map(scheduleToMap).toList());

    // Notifications are optional
    for (final day in newItem.repeatDays) {
      try {
        await NotificationService.scheduleWeekly(
          id: _scheduleNotificationId(newItem.id, day),
          title: newItem.title,
          weekday: day,
          hour: newItem.time.hour,
          minute: newItem.time.minute,
        );
      } catch (e) {
        debugPrint('Schedule notification failed: $e');
      }
    }
  }

  Future<void> updateSchedule(ScheduleItem updatedItem) async {
    final index = schedule.indexWhere((item) => item.id == updatedItem.id);

    if (index == -1) return;

    final oldItem = schedule[index];

    // Cancel old notifications
    for (final day in oldItem.repeatDays) {
      try {
        await NotificationService.cancel(
          _scheduleNotificationId(oldItem.id, day),
        );
      } catch (e) {
        debugPrint('Failed to cancel old notification: $e');
      }
    }

    schedule[index] = ScheduleItem(
      id: updatedItem.id,
      title: updatedItem.title,
      time: updatedItem.time,
      repeatDays: List<int>.from(updatedItem.repeatDays),
    );

    // Update UI immediately
    if (mounted) {
      setState(() {});
    }

    // Save
    await AppStorage.saveSchedule(schedule.map(scheduleToMap).toList());

    // Create new notifications
    for (final day in updatedItem.repeatDays) {
      try {
        await NotificationService.scheduleWeekly(
          id: _scheduleNotificationId(updatedItem.id, day),
          title: updatedItem.title,
          weekday: day,
          hour: updatedItem.time.hour,
          minute: updatedItem.time.minute,
        );
      } catch (e) {
        debugPrint('Updated schedule notification failed: $e');
      }
    }
  }

  Future<void> deleteSchedule(int id) async {
    final index = schedule.indexWhere((item) => item.id == id);

    if (index == -1) return;

    final item = schedule[index];

    // Cancel notifications
    for (final day in item.repeatDays) {
      try {
        await NotificationService.cancel(_scheduleNotificationId(item.id, day));
      } catch (e) {
        debugPrint('Failed to cancel schedule notification: $e');
      }
    }

    schedule.removeAt(index);

    // Update UI immediately
    if (mounted) {
      setState(() {});
    }

    // Save
    await AppStorage.saveSchedule(schedule.map(scheduleToMap).toList());
  }
  // ==========================================================
  // SCHEDULE STORAGE
  // ==========================================================

  Map<String, dynamic> scheduleToMap(ScheduleItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'hour': item.time.hour,
      'minute': item.time.minute,
      'repeatDays': item.repeatDays,
    };
  }

  ScheduleItem scheduleFromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] as int,
      title: map['title'] as String,
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
    );
  }

  // ==========================================================
  // TASK STORAGE
  // ==========================================================

  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'dueDate': task.dueDate.toIso8601String(),
      'completed': task.completed,
    };
  }

  Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      completed: map['completed'] ?? false,
    );
  }

  // ==========================================================
  // SLEEP STORAGE
  // ==========================================================

  Map<String, dynamic> _sleepToMap(SleepRecord record) {
    return {
      'id': record.id,
      'sleepTime': record.sleepTime.toIso8601String(),
      'wakeTime': record.wakeTime.toIso8601String(),
      'note': record.note,
    };
  }

  SleepRecord _sleepFromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'] as int,
      sleepTime: DateTime.parse(map['sleepTime'] as String),
      wakeTime: DateTime.parse(map['wakeTime'] as String),
      note: map['note'] as String?,
    );
  }

  // ==========================================================
  // EXPENSE STORAGE
  // ==========================================================

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': expense.date.toIso8601String(),
    };
  }

  Expense _expenseFromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  // ==========================================================
  // SAVINGS STORAGE
  // ==========================================================
  Map<String, dynamic> _savingsToMap(SavingsGoal goal) {
    return {
      'name': goal.name,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'imagePath': goal.imagePath,
    };
  }

  SavingsGoal _savingsFromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
    );
  }

  // ==========================================================
  // TASKS
  // ==========================================================

  Future<void> addTask(Task task) async {
    final newTask = Task(
      id: DateTime.now().microsecondsSinceEpoch,
      title: task.title,
      dueDate: task.dueDate,
      completed: false,
    );

    tasks.add(newTask);

    await AppStorage.saveTasks(tasks.map(_taskToMap).toList());

    await NotificationService.scheduleTask(
      id: newTask.id,
      title: newTask.title,
      dateTime: newTask.dueDate,
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> toggleTask(int taskId) async {
    final index = tasks.indexWhere((task) => task.id == taskId);

    if (index == -1) return;

    final task = tasks[index];

    task.completed = !task.completed;

    if (task.completed) {
      await NotificationService.cancel(task.id);
    } else {
      await NotificationService.scheduleTask(
        id: task.id,
        title: task.title,
        dateTime: task.dueDate,
      );
    }

    await AppStorage.saveTasks(tasks.map(_taskToMap).toList());

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteTask(int taskId) async {
    tasks.removeWhere((task) => task.id == taskId);

    await NotificationService.cancel(taskId);

    await AppStorage.saveTasks(tasks.map(_taskToMap).toList());

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // SLEEP
  // ==========================================================

  Future<void> addSleepRecord(SleepRecord record) async {
    final newRecord = SleepRecord(
      id: DateTime.now().microsecondsSinceEpoch,
      sleepTime: record.sleepTime,
      wakeTime: record.wakeTime,
      note: record.note,
    );

    sleepRecords.insert(0, newRecord);

    await AppStorage.saveSleepRecords(sleepRecords.map(_sleepToMap).toList());

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteSleepRecord(int recordId) async {
    sleepRecords.removeWhere((record) => record.id == recordId);

    await AppStorage.saveSleepRecords(sleepRecords.map(_sleepToMap).toList());

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // EXPENSES
  // ==========================================================

  Future<void> addExpense(Expense expense) async {
    final newExpense = Expense(
      id: DateTime.now().microsecondsSinceEpoch,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
    );

    expenses.insert(0, newExpense);

    await AppStorage.saveExpenses(expenses.map(_expenseToMap).toList());

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteExpense(int expenseId) async {
    expenses.removeWhere((expense) => expense.id == expenseId);

    await AppStorage.saveExpenses(expenses.map(_expenseToMap).toList());

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // BUDGET
  // ==========================================================

  Future<void> updateBudget(double amount) async {
    monthlyBudget = amount;

    await AppStorage.saveBudget(amount);

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // SAVINGS
  // ==========================================================

  Future<void> saveSavingsGoal({
    required String name,
    required double targetAmount,
    String? imagePath,
  }) async {
    savingsGoal = SavingsGoal(
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      imagePath: imagePath,
    );

    await AppStorage.saveSavingsGoal(_savingsToMap(savingsGoal!));

    if (!mounted) return;

    setState(() {});
  }

  Future<void> editSavingsGoal({
    required String name,
    required double targetAmount,
    String? imagePath,
  }) async {
    if (savingsGoal == null) return;

    savingsGoal!
      ..name = name
      ..targetAmount = targetAmount;

    if (imagePath != null) {
      savingsGoal!.imagePath = imagePath;
    }

    if (savingsGoal!.currentAmount > targetAmount) {
      savingsGoal!.currentAmount = targetAmount;
    }

    await AppStorage.saveSavingsGoal(_savingsToMap(savingsGoal!));

    if (!mounted) return;

    setState(() {});
  }

  Future<void> addSavings(double amount) async {
    if (savingsGoal == null) return;

    savingsGoal!.currentAmount += amount;

    if (savingsGoal!.currentAmount > savingsGoal!.targetAmount) {
      savingsGoal!.currentAmount = savingsGoal!.targetAmount;
    }

    await AppStorage.saveSavingsGoal(_savingsToMap(savingsGoal!));

    if (!mounted) return;

    setState(() {});
  }

  Future<void> removeSavings(double amount) async {
    if (savingsGoal == null) return;

    savingsGoal!.currentAmount -= amount;

    if (savingsGoal!.currentAmount < 0) {
      savingsGoal!.currentAmount = 0;
    }

    await AppStorage.saveSavingsGoal(_savingsToMap(savingsGoal!));

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteSavingsGoal() async {
    savingsGoal = null;

    await AppStorage.clearSavingsGoal();

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      HomePage(
        schedule: schedule,
        tasks: tasks,
        sleepRecords: sleepRecords,
        expenses: expenses,
        savingsGoal: savingsGoal,
        onToggleTask: toggleTask,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
      PlannerPage(
        tasks: tasks,
        onAddTask: addTask,
        onToggleTask: toggleTask,
        onDeleteTask: deleteTask,
      ),
      SchedulePage(
        schedule: schedule,
        firstDayOfWeek: firstDayOfWeek,
        onFirstDayChanged: setFirstDayOfWeek,
        onAddSchedule: addSchedule,
        onUpdateSchedule: updateSchedule,
        onDeleteSchedule: deleteSchedule,
      ),
      HealthPage(
        sleepRecords: sleepRecords,
        sleepGoalHours: sleepGoalHours,
        onAddSleep: addSleepRecord,
        onDeleteSleep: deleteSleepRecord,
        onUpdateSleepGoal: updateSleepGoal,
      ),
      MoneyPage(
        expenses: expenses,
        monthlyBudget: monthlyBudget,
        savingsGoal: savingsGoal,
        onAddExpense: addExpense,
        onDeleteExpense: deleteExpense,
        onUpdateBudget: updateBudget,
        onCreateSavings: saveSavingsGoal,
        onEditSavings: editSavingsGoal,
        onAddSavings: addSavings,
        onRemoveSavings: removeSavings,
        onDeleteSavings: deleteSavingsGoal,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Money',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  final List<ScheduleItem> schedule;
  final List<Task> tasks;
  final List<SleepRecord> sleepRecords;
  final List<Expense> expenses;
  final SavingsGoal? savingsGoal;
  final Function(int) onToggleTask;

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  const HomePage({
    super.key,
    required this.schedule,
    required this.tasks,
    required this.sleepRecords,
    required this.expenses,
    required this.savingsGoal,
    required this.onToggleTask,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Settings'),
          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: isDarkMode,
            onChanged: (_) {
              onToggleTheme();
              Navigator.pop(dialogContext);
            },
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning 👋';
    }

    if (hour < 18) {
      return 'Good afternoon 👋';
    }

    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.completed).length;

    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final latestSleep = sleepRecords.isNotEmpty ? sleepRecords.first : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _greeting(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showSettingsDialog(context);
                  },
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your day at a glance',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Today'),
            const SizedBox(height: 12),

            ..._todayScheduleCards(),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$completedTasks/${tasks.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (tasks.isEmpty) _emptyCard('No tasks yet.'),

            ...tasks
                .take(4)
                .map(
                  (task) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: task.completed,
                      onChanged: (_) {
                        onToggleTask(task.id);
                      },
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(formatDate(task.dueDate)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.bedtime_outlined,
                    'Sleep',
                    latestSleep == null
                        ? 'No data'
                        : formatDuration(latestSleep.duration),
                    'Last night',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.wallet_outlined,
                    'Spent',
                    'RM${totalExpenses.toStringAsFixed(2)}',
                    'This month',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _sectionTitle('Savings'),
            const SizedBox(height: 12),

            if (savingsGoal == null)
              _emptyCard(
                'No savings goal yet.\n'
                'Create one from Money.',
              )
            else
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: savingsGoal!.imagePath == null
                                ? null
                                : FileImage(File(savingsGoal!.imagePath!)),
                            child: savingsGoal!.imagePath == null
                                ? const Icon(Icons.savings_outlined, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              savingsGoal!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '${(savingsGoal!.progress * 100).round()}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: savingsGoal!.progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'RM${savingsGoal!.currentAmount.toStringAsFixed(2)} '
                        '/ RM${savingsGoal!.targetAmount.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _todayScheduleCards() {
    final today = DateTime.now().weekday;

    final todaySchedules = schedule.where((item) {
      return item.repeatDays.contains(today);
    }).toList();

    todaySchedules.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;

      final bMinutes = b.time.hour * 60 + b.time.minute;

      return aMinutes.compareTo(bMinutes);
    });

    if (todaySchedules.isEmpty) {
      return [_emptyCard('No schedule for today.')];
    }

    return todaySchedules.map((item) {
      return _scheduleCard(
        formatTimeOfDay(item.time),
        item.title,
        repeatText(item.repeatDays),
        Icons.schedule_outlined,
      );
    }).toList();
  }

  String repeatText(List<int> days) {
    if (days.length == 7) {
      return 'Every day';
    }

    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }

    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return days.map((day) => names[day - 1]).join(', ');
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _scheduleCard(
    String time,
    String title,
    String repeat,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(repeat),
        trailing: Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value, String subtitle) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text, textAlign: TextAlign.center)),
      ),
    );
  }
}

// ============================================================
// PLANNER PAGE
// ============================================================

class PlannerPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onAddTask;
  final Function(int) onToggleTask;
  final Function(int) onDeleteTask;

  const PlannerPage({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime selectedDate = DateTime.now();

  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // ==========================================================
  // ADD TASK
  // ==========================================================

  Future<void> addTaskDialog() async {
    final titleController = TextEditingController();

    DateTime dueDate = selectedDate;

    final result = await showDialog<Task>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task name',
                      hintText: 'e.g. Finish assignment',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(formatDate(dueDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          dueDate = picked;

                          displayedMonth = DateTime(picked.year, picked.month);
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      Task(
                        id: 0,
                        title: titleController.text.trim(),
                        dueDate: dueDate,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();

    if (result != null) {
      widget.onAddTask(result);
    }
  }

  // ==========================================================
  // DATE HELPERS
  // ==========================================================

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasTaskOnDate(DateTime date) {
    return widget.tasks.any((task) => _isSameDay(task.dueDate, date));
  }

  // ==========================================================
  // CALENDAR
  // ==========================================================

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    final startingWeekday = firstDayOfMonth.weekday;

    final totalCells = ((startingWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    final monthName =
        '${_monthName(displayedMonth.month)} '
        '${displayedMonth.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(
                      displayedMonth.year,
                      displayedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(
                      displayedMonth.year,
                      displayedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: Center(
                  child: Text(
                    'Mon',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Tue',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Wed',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Thu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Fri',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sat',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sun',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 52,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - (startingWeekday - 1) + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(
                displayedMonth.year,
                displayedMonth.month,
                dayNumber,
              );

              final isSelected = _isSameDay(date, selectedDate);

              final isToday = _isSameDay(date, DateTime.now());

              final hasTask = _hasTaskOnDate(date);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasTask
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final selectedTasks = widget.tasks.where((task) {
      return _isSameDay(task.dueDate, selectedDate);
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Text(
                  'Planner',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: addTaskDialog,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          _buildCalendar(),

          const Divider(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Tasks for '
                  '${formatDate(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (selectedTasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('No tasks for this date.'),
                    ),
                  ),

                ...selectedTasks.map(
                  (task) => Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.endToStart,
                    background: _deleteBackground(),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('Delete task?'),
                            content: Text('Remove "${task.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, true);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (_) {
                      widget.onDeleteTask(task.id);
                    },
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(formatDate(task.dueDate)),
                        trailing: Checkbox(
                          value: task.completed,
                          onChanged: (_) {
                            widget.onToggleTask(task.id);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}

// ============================================================
// SCHEDULE PAGE
// ============================================================

class SchedulePage extends StatefulWidget {
  final List<ScheduleItem> schedule;
  final int firstDayOfWeek;
  final Future<void> Function(int day) onFirstDayChanged;
  final Future<void> Function(ScheduleItem item) onAddSchedule;
  final Future<void> Function(ScheduleItem item) onUpdateSchedule;
  final Future<void> Function(int id) onDeleteSchedule;

  const SchedulePage({
    super.key,
    required this.schedule,
    required this.firstDayOfWeek,
    required this.onFirstDayChanged,
    required this.onAddSchedule,
    required this.onUpdateSchedule,
    required this.onDeleteSchedule,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ==========================================================
  // SCHEDULE DIALOG
  // ==========================================================

  Future<void> showScheduleDialog({ScheduleItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');

    TimeOfDay selectedTime = existing?.time ?? TimeOfDay.now();

    List<int> selectedDays = List<int>.from(
      existing?.repeatDays ?? [1, 2, 3, 4, 5],
    );

    final result = await showDialog<ScheduleItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Schedule' : 'Edit Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Schedule name',
                        hintText: 'e.g. Study',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(formatTimeOfDay(selectedTime)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Repeat',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final day = index + 1;

                        final selected = selectedDays.contains(day);

                        const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                        return FilterChip(
                          label: Text(names[index]),
                          selected: selected,
                          onSelected: (value) {
                            setDialogState(() {
                              if (value) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }

                              selectedDays.sort();
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    if (selectedDays.isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      ScheduleItem(
                        id: existing?.id ?? 0,
                        title: titleController.text.trim(),
                        time: selectedTime,
                        repeatDays: selectedDays,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();

    if (result == null) return;

    if (existing == null) {
      widget.onAddSchedule(result);
    } else {
      widget.onUpdateSchedule(result);
    }
  }

  // ==========================================================
  // FIRST DAY DIALOG
  // ==========================================================

  Future<void> showFirstDayDialog() async {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    int selected = widget.firstDayOfWeek;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('First day of week'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  final day = index + 1;

                  return RadioListTile<int>(
                    value: day,
                    groupValue: selected,
                    title: Text(days[index]),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selected = value;
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      widget.onFirstDayChanged(result);
    }
  }

  // ==========================================================
  // WEEK CALCULATION
  // ==========================================================

  DateTime _weekStart() {
    final today = DateTime.now();

    final difference = (today.weekday - widget.firstDayOfWeek + 7) % 7;

    return DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: difference));
  }

  List<int> _orderedDays() {
    return List.generate(
      7,
      (index) => ((widget.firstDayOfWeek - 1 + index) % 7) + 1,
    );
  }

  String _dayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return names[weekday - 1];
  }

  String _fullDayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[weekday - 1];
  }

  // ==========================================================
  // BUILD WEEKLY SCHEDULE
  // ==========================================================

  Widget _buildWeekSchedule() {
    final weekStart = _weekStart();
    final orderedDays = _orderedDays();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(7, (index) {
          final weekday = orderedDays[index];
          final date = weekStart.add(Duration(days: index));

          final items = widget.schedule
              .where((item) => item.repeatDays.contains(weekday))
              .toList();

          items.sort((a, b) {
            final aMinutes = a.time.hour * 60 + a.time.minute;
            final bMinutes = b.time.hour * 60 + b.time.minute;

            return aMinutes.compareTo(bMinutes);
          });

          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return Container(
            width: 190,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullDayName(weekday),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),

                const SizedBox(height: 8),

                Divider(
                  color: isToday ? Theme.of(context).colorScheme.primary : null,
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: items.isEmpty
                      ? Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No schedule',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: items
                              .map((item) => _scheduleCard(item))
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _scheduleCard(ScheduleItem item) {
    return Dismissible(
      key: ValueKey('${item.id}_${item.time.hour}_${item.time.minute}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        widget.onDeleteSchedule(item.id);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showScheduleDialog(existing: item);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTimeOfDay(item.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final firstDayName = _fullDayName(widget.firstDayOfWeek);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
            child: Row(
              children: [
                const Text(
                  'Schedule',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: showFirstDayDialog,
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Schedule settings',
                ),
                IconButton(
                  onPressed: () {
                    showScheduleDialog();
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'Add schedule',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Week starts $firstDayName',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: widget.schedule.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_view_week_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text('No schedules yet.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            showScheduleDialog();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add schedule'),
                        ),
                      ],
                    ),
                  )
                : _buildWeekSchedule(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEALTH PAGE
// ============================================================

class HealthPage extends StatelessWidget {
  final List<SleepRecord> sleepRecords;
  final int sleepGoalHours;

  final Function(SleepRecord) onAddSleep;
  final Function(int) onDeleteSleep;
  final Function(int) onUpdateSleepGoal;

  const HealthPage({
    super.key,
    required this.sleepRecords,
    required this.sleepGoalHours,
    required this.onAddSleep,
    required this.onDeleteSleep,
    required this.onUpdateSleepGoal,
  });

  @override
  Widget build(BuildContext context) {
    final latestSleep = sleepRecords.isNotEmpty ? sleepRecords.first : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Health',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    showAddSleepDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'Add sleep',
                ),
              ],
            ),

            const SizedBox(height: 24),

            _sleepSummary(context, latestSleep),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Sleep history',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${sleepRecords.length} records',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (sleepRecords.isEmpty) _emptyCard('No sleep records yet.'),

            ...sleepRecords.map(
              (record) => Dismissible(
                key: ValueKey('sleep_${record.id}'),
                direction: DismissDirection.endToStart,
                background: _deleteBackground(),
                onDismissed: (_) {
                  onDeleteSleep(record.id);
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.bedtime_outlined),
                    ),
                    title: Text(
                      formatDuration(record.duration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${formatDateTime(record.sleepTime)}'
                      ' → '
                      '${formatDateTime(record.wakeTime)}',
                    ),
                    trailing: Text(sleepQuality(record.duration)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleepSummary(BuildContext context, SleepRecord? latestSleep) {
    final duration = latestSleep?.duration;

    final progress = duration == null
        ? 0.0
        : (duration.inMinutes / (sleepGoalHours * 60))
              .clamp(0.0, 1.0)
              .toDouble();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.bedtime, size: 48),
            const SizedBox(height: 12),
            Text(
              duration == null ? '--' : formatDuration(duration),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text(
              duration == null ? 'No sleep record' : sleepQuality(duration),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sleep goal: $sleepGoalHours hours'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    showSleepGoalDialog(context);
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text)),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Future<void> showSleepGoalDialog(BuildContext context) async {
    int selectedGoal = sleepGoalHours;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sleep goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (index) {
                  final hours = index + 5;

                  return RadioListTile<int>(
                    value: hours,
                    groupValue: selectedGoal,
                    title: Text('$hours hours'),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedGoal = value;
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedGoal);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onUpdateSleepGoal(result);
    }
  }

  Future<void> showAddSleepDialog(BuildContext context) async {
    DateTime sleepTime = DateTime.now().subtract(const Duration(hours: 8));

    DateTime wakeTime = DateTime.now();

    final result = await showDialog<SleepRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Sleep Record'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.nightlight_outlined),
                    title: const Text('Sleep time'),
                    subtitle: Text(formatDateTime(sleepTime)),
                    onTap: () async {
                      final value = await pickDateTime(context, sleepTime);

                      if (value != null) {
                        setDialogState(() {
                          sleepTime = value;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Wake time'),
                    subtitle: Text(formatDateTime(wakeTime)),
                    onTap: () async {
                      final value = await pickDateTime(context, wakeTime);

                      if (value != null) {
                        setDialogState(() {
                          wakeTime = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!wakeTime.isAfter(sleepTime)) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      SleepRecord(
                        id: 0,
                        sleepTime: sleepTime,
                        wakeTime: wakeTime,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onAddSleep(result);
    }
  }
}

// ============================================================
// MONEY PAGE
// ============================================================

class MoneyPage extends StatelessWidget {
  final List<Expense> expenses;
  final double monthlyBudget;
  final SavingsGoal? savingsGoal;

  final Function(Expense) onAddExpense;
  final Function(int) onDeleteExpense;
  final Function(double) onUpdateBudget;

  final Future<void> Function({
    required String name,
    required double targetAmount,
    String? imagePath,
  })
  onCreateSavings;

  final Future<void> Function({
    required String name,
    required double targetAmount,
    String? imagePath,
  })
  onEditSavings;
  final Function(double) onAddSavings;
  final Function(double) onRemoveSavings;
  final Function() onDeleteSavings;

  const MoneyPage({
    super.key,
    required this.expenses,
    required this.monthlyBudget,
    required this.savingsGoal,
    required this.onAddExpense,
    required this.onDeleteExpense,
    required this.onUpdateBudget,
    required this.onCreateSavings,
    required this.onEditSavings,
    required this.onAddSavings,
    required this.onRemoveSavings,
    required this.onDeleteSavings,
  });
  @override
  Widget build(BuildContext context) {
    final totalSpent = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final remaining = monthlyBudget - totalSpent;
    final weeklyBudget = monthlyBudget / 4;

    final budgetProgress = monthlyBudget <= 0
        ? 0.0
        : (totalSpent / monthlyBudget).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Money',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    showAddExpenseDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'Add expense',
                ),
              ],
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly spending',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM${totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: budgetProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Budget: '
                            'RM${monthlyBudget.toStringAsFixed(2)}',
                          ),
                        ),
                        Text(
                          remaining >= 0
                              ? 'RM${remaining.toStringAsFixed(2)} left'
                              : 'RM${remaining.abs().toStringAsFixed(2)} over',
                          style: TextStyle(
                            color: remaining >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                showBudgetDialog(context);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit monthly budget'),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('Weekly budget'),
                subtitle: const Text('Based on your monthly budget'),
                trailing: Text(
                  'RM${weeklyBudget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Recent expenses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${expenses.length} items',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (expenses.isEmpty) _emptyCard('No expenses yet.'),

            ...expenses.map(
              (expense) => Dismissible(
                key: ValueKey('expense_${expense.id}'),
                direction: DismissDirection.endToStart,
                background: _deleteBackground(),
                onDismissed: (_) {
                  onDeleteExpense(expense.id);
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(categoryIcon(expense.category)),
                    ),
                    title: Text(expense.title),
                    subtitle: Text(
                      '${expense.category} • '
                      '${formatDate(expense.date)}',
                    ),
                    trailing: Text(
                      'RM${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Savings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (savingsGoal == null)
              _buildEmptySavings(context)
            else
              _buildSavingsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySavings(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.savings_outlined, size: 36),
            const SizedBox(height: 12),
            const Text(
              'No savings goal yet.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a goal to start '
              'tracking your savings.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                showCreateSavingsDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create savings goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(BuildContext context) {
    final goal = savingsGoal!;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: goal.imagePath == null
                      ? null
                      : FileImage(File(goal.imagePath!)),
                  child: goal.imagePath == null
                      ? const Icon(Icons.savings_outlined, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showEditSavingsDialog(context);
                    }

                    if (value == 'delete') {
                      showDeleteSavingsDialog(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit goal')),
                    PopupMenuItem(value: 'delete', child: Text('Delete goal')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'RM${goal.currentAmount.toStringAsFixed(2)} '
              '/ RM${goal.targetAmount.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showAddSavingsDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showRemoveSavingsDialog(context);
                    },
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text)),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  // ==========================================================
  // EXPENSE DIALOG
  // ==========================================================

  Future<void> showAddExpenseDialog(BuildContext context) async {
    final titleController = TextEditingController();

    final amountController = TextEditingController();

    String category = 'Food';

    final result = await showDialog<Expense>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense',
                        hintText: 'e.g. Lunch',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'RM ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'Food', child: Text('Food')),
                        DropdownMenuItem(
                          value: 'Transport',
                          child: Text('Transport'),
                        ),
                        DropdownMenuItem(
                          value: 'Education',
                          child: Text('Education'),
                        ),
                        DropdownMenuItem(
                          value: 'Entertainment',
                          child: Text('Entertainment'),
                        ),
                        DropdownMenuItem(
                          value: 'Shopping',
                          child: Text('Shopping'),
                        ),
                        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (titleController.text.trim().isEmpty ||
                        amount == null ||
                        amount <= 0) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      Expense(
                        id: 0,
                        title: titleController.text.trim(),
                        amount: amount,
                        category: category,
                        date: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();

    if (result != null) {
      onAddExpense(result);
    }
  }

  // ==========================================================
  // BUDGET DIALOG
  // ==========================================================

  Future<void> showBudgetDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: monthlyBudget.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: 'RM ',
              labelText: 'Budget',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());

                if (amount != null && amount >= 0) {
                  Navigator.pop(dialogContext, amount);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null) {
      onUpdateBudget(result);
    }
  }

  // ==========================================================
  // CREATE SAVINGS
  // ==========================================================

  Future<void> showCreateSavingsDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final targetController = TextEditingController();

    String? imagePath;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );

              if (picked != null) {
                setDialogState(() {
                  imagePath = picked.path;
                });
              }
            }

            return AlertDialog(
              title: const Text('Create Savings Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              backgroundImage: imagePath == null
                                  ? null
                                  : FileImage(File(imagePath!)),
                              child: imagePath == null
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 28,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      imagePath == null
                          ? 'Add a photo (optional)'
                          : 'Tap to change photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Goal name',
                        hintText: 'e.g. New laptop',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Target amount',
                        prefixText: 'RM ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final target = double.tryParse(
                      targetController.text.trim(),
                    );

                    if (nameController.text.trim().isEmpty ||
                        target == null ||
                        target <= 0) {
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'name': nameController.text.trim(),
                      'target': target,
                      'imagePath': imagePath,
                    });
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    targetController.dispose();

    if (result == null) return;

    final name = result['name'] as String;
    final targetAmount = (result['target'] as num).toDouble();
    final resultImagePath = result['imagePath'] as String?;

    await onCreateSavings(
      name: name,
      targetAmount: targetAmount,
      imagePath: resultImagePath,
    );
  }

  // ==========================================================
  // EDIT SAVINGS
  // ==========================================================

  Future<void> showEditSavingsDialog(BuildContext context) async {
    if (savingsGoal == null) return;

    final nameController = TextEditingController(text: savingsGoal!.name);

    final targetController = TextEditingController(
      text: savingsGoal!.targetAmount.toStringAsFixed(2),
    );

    String? imagePath = savingsGoal!.imagePath;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );

              if (picked != null) {
                setDialogState(() {
                  imagePath = picked.path;
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Savings Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              backgroundImage: imagePath == null
                                  ? null
                                  : FileImage(File(imagePath!)),
                              child: imagePath == null
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 28,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      imagePath == null
                          ? 'Add a photo (optional)'
                          : 'Tap to change photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Goal name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Target amount',
                        prefixText: 'RM ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final target = double.tryParse(
                      targetController.text.trim(),
                    );

                    if (nameController.text.trim().isEmpty ||
                        target == null ||
                        target <= 0) {
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'name': nameController.text.trim(),
                      'target': target,
                      'imagePath': imagePath,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    targetController.dispose();

    if (result == null) return;

    final name = result['name'] as String;
    final targetAmount = (result['target'] as num).toDouble();
    final resultImagePath = result['imagePath'] as String?;

    await onEditSavings(
      name: name,
      targetAmount: targetAmount,
      imagePath: resultImagePath,
    );
  }

  // ==========================================================
  // ADD SAVINGS
  // ==========================================================

  Future<void> showAddSavingsDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Savings'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: 'RM ',
              labelText: 'Amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());

                if (amount != null && amount > 0) {
                  Navigator.pop(dialogContext, amount);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null) {
      onAddSavings(result);
    }
  }

  // ==========================================================
  // REMOVE SAVINGS
  // ==========================================================

  Future<void> showRemoveSavingsDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Savings'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: 'RM ',
              labelText: 'Amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());

                if (amount != null && amount > 0) {
                  Navigator.pop(dialogContext, amount);
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null) {
      onRemoveSavings(result);
    }
  }

  // ==========================================================
  // DELETE SAVINGS GOAL
  // ==========================================================

  Future<void> showDeleteSavingsDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete savings goal?'),
          content: const Text(
            'This will remove the goal '
            'and its saved progress.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onDeleteSavings();
    }
  }
}

// ============================================================
// DATE / TIME HELPERS
// ============================================================

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '${formatDate(date)} '
      '$hour:$minute';
}

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

  final minute = time.minute.toString().padLeft(2, '0');

  final period = time.period == DayPeriod.am ? 'AM' : 'PM';

  return '$hour:$minute $period';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;

  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0) {
    return '${minutes}m';
  }

  return '${hours}h ${minutes}m';
}

String sleepQuality(Duration duration) {
  final hours = duration.inMinutes / 60;

  if (hours >= 7 && hours <= 9) {
    return 'Good';
  }

  if (hours >= 6) {
    return 'Okay';
  }

  return 'Low';
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant_outlined;

    case 'Transport':
      return Icons.directions_bus_outlined;

    case 'Education':
      return Icons.school_outlined;

    case 'Entertainment':
      return Icons.movie_outlined;

    case 'Shopping':
      return Icons.shopping_bag_outlined;

    case 'Bills':
      return Icons.receipt_long_outlined;

    default:
      return Icons.more_horiz;
  }
}

// ============================================================
// DATE TIME PICKER
// ============================================================

Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );

  if (date == null) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );

  if (time == null) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
