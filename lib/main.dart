import 'package:flutter/material.dart';

import 'models/models.dart';
import 'notification_service.dart';
import 'pages/health_page.dart';
import 'pages/home_page.dart';
import 'pages/money_page.dart';
import 'pages/planner_page.dart';
import 'pages/schedule_page.dart';
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

    tasks = loadedTasks.map(Task.fromMap).toList();

    sleepRecords = loadedSleep.map(SleepRecord.fromMap).toList();

    expenses = loadedExpenses.map(Expense.fromMap).toList();

    schedule = loadedSchedule.map(ScheduleItem.fromMap).toList();

    monthlyBudget = loadedBudget;
    firstDayOfWeek = loadedFirstDay;
    sleepGoalHours = loadedSleepGoal;

    if (loadedSavings != null) {
      savingsGoal = SavingsGoal.fromMap(loadedSavings);
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
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
    );

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
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
    );

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
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
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

    await AppStorage.saveTasks(tasks.map((task) => task.toMap()).toList());

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

    await AppStorage.saveTasks(tasks.map((task) => task.toMap()).toList());

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteTask(int taskId) async {
    tasks.removeWhere((task) => task.id == taskId);

    await NotificationService.cancel(taskId);

    await AppStorage.saveTasks(tasks.map((task) => task.toMap()).toList());

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

    await AppStorage.saveSleepRecords(
      sleepRecords.map((record) => record.toMap()).toList(),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteSleepRecord(int recordId) async {
    sleepRecords.removeWhere((record) => record.id == recordId);

    await AppStorage.saveSleepRecords(
      sleepRecords.map((record) => record.toMap()).toList(),
    );

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

    await AppStorage.saveExpenses(
      expenses.map((expense) => expense.toMap()).toList(),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteExpense(int expenseId) async {
    expenses.removeWhere((expense) => expense.id == expenseId);

    await AppStorage.saveExpenses(
      expenses.map((expense) => expense.toMap()).toList(),
    );

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

    await AppStorage.saveSavingsGoal(savingsGoal!.toMap());

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

    await AppStorage.saveSavingsGoal(savingsGoal!.toMap());

    if (!mounted) return;

    setState(() {});
  }

  Future<void> addSavings(double amount) async {
    if (savingsGoal == null) return;

    savingsGoal!.currentAmount += amount;

    if (savingsGoal!.currentAmount > savingsGoal!.targetAmount) {
      savingsGoal!.currentAmount = savingsGoal!.targetAmount;
    }

    await AppStorage.saveSavingsGoal(savingsGoal!.toMap());

    if (!mounted) return;

    setState(() {});
  }

  Future<void> removeSavings(double amount) async {
    if (savingsGoal == null) return;

    savingsGoal!.currentAmount -= amount;

    if (savingsGoal!.currentAmount < 0) {
      savingsGoal!.currentAmount = 0;
    }

    await AppStorage.saveSavingsGoal(savingsGoal!.toMap());

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

