import 'package:flutter/material.dart';
import 'models/models.dart';
import 'notification_service.dart';
import 'pages/health_page.dart';
import 'pages/home_page.dart';
import 'pages/money_page.dart';
import 'pages/planner_page.dart';
import 'pages/schedule_page.dart';
import 'services/imaluum/imaluum_timetable.dart';
import 'storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const LifeZenApp());
}

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
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C7BFF),
      brightness: Brightness.light,
    );
    final darkScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7BFF),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF8B7BFF),
          secondary: const Color(0xFF5DE2C3),
          tertiary: const Color(0xFF7DD3FC),
          surface: const Color(0xFF0F172A),
          onSurface: const Color(0xFFE2E8F0),
          onSurfaceVariant: const Color(0xFFCBD5E1),
          outline: const Color(0xFF334155),
          outlineVariant: const Color(0xFF475569),
          surfaceContainerHighest: const Color(0xFF1E293B),
        );
    return MaterialApp(
      title: 'LifeZen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          color: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          surfaceTintColor: Colors.transparent,
          indicatorColor: lightScheme.primary.withValues(alpha: 0.12),
          shadowColor: Colors.black.withValues(alpha: 0.06),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          color: const Color(0xFF121C2E),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF111C2C).withValues(alpha: 0.96),
          surfaceTintColor: Colors.transparent,
          indicatorColor: darkScheme.primary.withValues(alpha: 0.24),
          shadowColor: Colors.black.withValues(alpha: 0.24),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF121C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.9),
            colorScheme.secondary.withValues(alpha: 0.7),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.82, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.32),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    size: 58,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'LifeZen',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plan your day. Live better.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final PageController pageController = PageController();
  List<Task> tasks = [];
  List<SleepRecord> sleepRecords = [];
  List<Expense> expenses = [];
  List<ScheduleItem> schedule = [];
  List<SavingsGoal> savingsGoals = [];
  double monthlyBudget = 800;
  int sleepGoalHours = 8;
  int reminderMinutes = 10;
  int firstDayOfWeek = 1;
  int currentIndex = 0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
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

  Future<void> updateReminderMinutes(int minutes) async {
    reminderMinutes = minutes;
    await AppStorage.saveReminderMinutes(minutes);
    await _refreshNotifications();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadData() async {
    final loadedTasks = await AppStorage.loadTasks();
    final loadedSleep = await AppStorage.loadSleepRecords();
    final loadedExpenses = await AppStorage.loadExpenses();
    final loadedSchedule = await AppStorage.loadSchedule();
    final loadedSavings = await AppStorage.loadSavingsGoals();
    final loadedSleepGoal = await AppStorage.loadSleepGoal();
    final loadedReminderMinutes = await AppStorage.loadReminderMinutes();
    final loadedBudget = await AppStorage.loadBudget();
    final loadedFirstDay = await AppStorage.loadFirstDayOfWeek();
    tasks = loadedTasks.map(Task.fromMap).toList();
    sleepRecords = loadedSleep.map(SleepRecord.fromMap).toList();
    expenses = loadedExpenses.map(Expense.fromMap).toList();
    schedule = loadedSchedule.map(ScheduleItem.fromMap).toList();
    savingsGoals = loadedSavings.map(SavingsGoal.fromMap).toList();
    monthlyBudget = loadedBudget;
    firstDayOfWeek = loadedFirstDay;
    sleepGoalHours = loadedSleepGoal;
    reminderMinutes = loadedReminderMinutes;
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    await _refreshNotifications();
  }

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
            reminderMinutes: reminderMinutes,
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
            reminderMinutes: reminderMinutes,
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

  Future<void> addSchedule(ScheduleItem item) async {
    final newItem = ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: item.title,
      time: item.time,
      endTime: item.endTime,
      repeatDays: List<int>.from(item.repeatDays),
    );
    schedule.add(newItem);
    if (mounted) {
      setState(() {});
    }
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
    );
    for (final day in newItem.repeatDays) {
      try {
        await NotificationService.scheduleWeekly(
          id: _scheduleNotificationId(newItem.id, day),
          title: newItem.title,
          weekday: day,
          hour: newItem.time.hour,
          minute: newItem.time.minute,
          reminderMinutes: reminderMinutes,
        );
      } catch (e) {
        debugPrint('Schedule notification failed: $e');
      }
    }
  }

  Future<int> importImaluumSchedule(List<ImaluumMeeting> meetings) async {
    final existingKeys = schedule
        .map((item) => item.importKey)
        .whereType<String>();
    final added = <ScheduleItem>[];
    for (final meeting in excludeImportedMeetings(meetings, existingKeys)) {
      final details = [
        meeting.courseCode,
        if (meeting.courseName != meeting.courseCode) meeting.courseName,
        if (meeting.section != null) 'Section ${meeting.section}',
        if (meeting.venue != null) meeting.venue!,
      ];
      added.add(
        ScheduleItem(
          id: DateTime.now().microsecondsSinceEpoch + added.length,
          title: details.join(' • '),
          time: meeting.start,
          endTime: meeting.end,
          repeatDays: [meeting.day],
          importKey: meeting.importKey,
          courseCode: meeting.courseCode,
          courseName: meeting.courseName,
          venue: meeting.venue,
          lecturer: meeting.lecturer,
          section: meeting.section,
          semester: meeting.semester,
        ),
      );
    }
    if (added.isEmpty) return 0;
    schedule.addAll(added);
    if (mounted) {
      setState(() {});
    }
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
    );
    for (final item in added) {
      for (final day in item.repeatDays) {
        try {
          await NotificationService.scheduleWeekly(
            id: _scheduleNotificationId(item.id, day),
            title: item.title,
            weekday: day,
            hour: item.time.hour,
            minute: item.time.minute,
            reminderMinutes: reminderMinutes,
          );
        } catch (e) {
          debugPrint('Imported schedule notification failed: $e');
        }
      }
    }
    return added.length;
  }

  Future<void> updateSchedule(ScheduleItem updatedItem) async {
    final index = schedule.indexWhere((item) => item.id == updatedItem.id);
    if (index == -1) return;
    final oldItem = schedule[index];
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
      endTime: updatedItem.endTime,
      repeatDays: List<int>.from(updatedItem.repeatDays),
      importKey: oldItem.importKey,
      courseCode: oldItem.courseCode,
      courseName: oldItem.courseName,
      venue: oldItem.venue,
      lecturer: oldItem.lecturer,
      section: oldItem.section,
      semester: oldItem.semester,
    );
    if (mounted) {
      setState(() {});
    }
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
    );
    for (final day in updatedItem.repeatDays) {
      try {
        await NotificationService.scheduleWeekly(
          id: _scheduleNotificationId(updatedItem.id, day),
          title: updatedItem.title,
          weekday: day,
          hour: updatedItem.time.hour,
          minute: updatedItem.time.minute,
          reminderMinutes: reminderMinutes,
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
    for (final day in item.repeatDays) {
      try {
        await NotificationService.cancel(_scheduleNotificationId(item.id, day));
      } catch (e) {
        debugPrint('Failed to cancel schedule notification: $e');
      }
    }
    schedule.removeAt(index);
    if (mounted) {
      setState(() {});
    }
    await AppStorage.saveSchedule(
      schedule.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clearAllSchedules() async {
    if (schedule.isEmpty) return;
    for (final item in schedule) {
      for (final day in item.repeatDays) {
        try {
          await NotificationService.cancel(
            _scheduleNotificationId(item.id, day),
          );
        } catch (e) {
          debugPrint('Failed to cancel schedule notification: $e');
        }
      }
    }
    schedule.clear();
    await AppStorage.saveSchedule([]);
    if (!mounted) return;
    setState(() {});
  }

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
      reminderMinutes: reminderMinutes,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> toggleTask(int taskId) async {
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final task = tasks[index];
    task.completed = !task.completed;
    if (mounted) {
      setState(() {});
    }
    try {
      if (task.completed) {
        await NotificationService.cancel(task.id);
      } else {
        await NotificationService.scheduleTask(
          id: task.id,
          title: task.title,
          dateTime: task.dueDate,
          reminderMinutes: reminderMinutes,
        );
      }
    } catch (e) {
      debugPrint('Failed to update task notification: $e');
    }
    try {
      await AppStorage.saveTasks(tasks.map((task) => task.toMap()).toList());
    } catch (e) {
      debugPrint('Failed to save task: $e');
    }
  }

  Future<void> deleteTask(int taskId) async {
    tasks.removeWhere((task) => task.id == taskId);
    await NotificationService.cancel(taskId);
    await AppStorage.saveTasks(tasks.map((task) => task.toMap()).toList());
    if (!mounted) return;
    setState(() {});
  }

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

  Future<void> updateBudget(double amount) async {
    monthlyBudget = amount;
    await AppStorage.saveBudget(amount);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> saveSavingsGoal({
    required String name,
    required double targetAmount,
    String? imagePath,
  }) async {
    final newGoal = SavingsGoal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      imagePath: imagePath,
    );
    savingsGoals.add(newGoal);
    await AppStorage.saveSavingsGoals(
      savingsGoals.map((goal) => goal.toMap()).toList(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> editSavingsGoal({
    required String id,
    required String name,
    required double targetAmount,
    String? imagePath,
  }) async {
    final index = savingsGoals.indexWhere((goal) => goal.id == id);
    if (index == -1) return;
    final goal = savingsGoals[index];
    goal
      ..name = name
      ..targetAmount = targetAmount;
    if (imagePath != null) {
      goal.imagePath = imagePath;
    }
    if (goal.currentAmount > targetAmount) {
      goal.currentAmount = targetAmount;
    }
    await AppStorage.saveSavingsGoals(
      savingsGoals.map((goal) => goal.toMap()).toList(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> addSavings(String id, double amount) async {
    final index = savingsGoals.indexWhere((goal) => goal.id == id);
    if (index == -1) return;
    final goal = savingsGoals[index];
    goal.currentAmount += amount;
    if (goal.currentAmount > goal.targetAmount) {
      goal.currentAmount = goal.targetAmount;
    }
    await AppStorage.saveSavingsGoals(
      savingsGoals.map((goal) => goal.toMap()).toList(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> removeSavings(String id, double amount) async {
    final index = savingsGoals.indexWhere((goal) => goal.id == id);
    if (index == -1) return;
    final goal = savingsGoals[index];
    goal.currentAmount -= amount;
    if (goal.currentAmount < 0) {
      goal.currentAmount = 0;
    }
    await AppStorage.saveSavingsGoals(
      savingsGoals.map((goal) => goal.toMap()).toList(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> deleteSavingsGoal(String id) async {
    savingsGoals.removeWhere((goal) => goal.id == id);
    await AppStorage.saveSavingsGoals(
      savingsGoals.map((goal) => goal.toMap()).toList(),
    );
    if (!mounted) return;
    setState(() {});
  }

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
        savingsGoal: savingsGoals.isEmpty ? null : savingsGoals.first,
        onToggleTask: toggleTask,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        reminderMinutes: reminderMinutes,
        onReminderMinutesChanged: updateReminderMinutes,
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
        onImportImaluum: importImaluumSchedule,
        onClearAll: clearAllSchedules,
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
        savingsGoals: savingsGoals,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Planner',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule_rounded),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Health',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Money',
            ),
          ],
        ),
      ),
    );
  }
}
