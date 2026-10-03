import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _themeKey = 'theme_mode';
  static const String _tasksKey = 'tasks';
  static const String _sleepKey = 'sleep_records';
  static const String _expensesKey = 'expenses';

  // Multiple savings goals
  static const String _savingsGoalsKey = 'savings_goals';

  static const String _budgetKey = 'monthly_budget';
  static const String _scheduleKey = 'schedule';
  static const String _firstDayKey = 'first_day_of_week';
  static const String _sleepGoalKey = 'sleep_goal';
  static const String _reminderMinutesKey = 'reminder_minutes';

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  // ============================================================
  // THEME
  // ============================================================

  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await _prefs();
    await prefs.setBool(_themeKey, isDark);
  }

  static Future<bool> loadDarkMode() async {
    final prefs = await _prefs();
    return prefs.getBool(_themeKey) ?? false;
  }

  // ============================================================
  // TASKS
  // ============================================================

  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final prefs = await _prefs();
    await prefs.setString(_tasksKey, jsonEncode(tasks));
  }

  static Future<List<Map<String, dynamic>>> loadTasks() async {
    final prefs = await _prefs();
    final data = prefs.getString(_tasksKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    return List<Map<String, dynamic>>.from(
      (decoded as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // ============================================================
  // SLEEP
  // ============================================================

  static Future<void> saveSleepRecords(
    List<Map<String, dynamic>> records,
  ) async {
    final prefs = await _prefs();
    await prefs.setString(_sleepKey, jsonEncode(records));
  }

  static Future<List<Map<String, dynamic>>> loadSleepRecords() async {
    final prefs = await _prefs();
    final data = prefs.getString(_sleepKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    return List<Map<String, dynamic>>.from(
      (decoded as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // ============================================================
  // SLEEP GOAL
  // ============================================================

  static Future<void> saveSleepGoal(int hours) async {
    final prefs = await _prefs();
    await prefs.setInt(_sleepGoalKey, hours);
  }

  static Future<int> loadSleepGoal() async {
    final prefs = await _prefs();
    return prefs.getInt(_sleepGoalKey) ?? 8;
  }

  // ============================================================
  // REMINDER LEAD TIME
  // ============================================================

  static Future<void> saveReminderMinutes(int minutes) async {
    final prefs = await _prefs();
    await prefs.setInt(_reminderMinutesKey, minutes);
  }

  static Future<int> loadReminderMinutes() async {
    final prefs = await _prefs();
    return prefs.getInt(_reminderMinutesKey) ?? 10;
  }

  // ============================================================
  // EXPENSES
  // ============================================================

  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    final prefs = await _prefs();
    await prefs.setString(_expensesKey, jsonEncode(expenses));
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final prefs = await _prefs();
    final data = prefs.getString(_expensesKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    return List<Map<String, dynamic>>.from(
      (decoded as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // ============================================================
  // SAVINGS GOALS
  // ============================================================

  static Future<void> saveSavingsGoals(List<Map<String, dynamic>> goals) async {
    final prefs = await _prefs();
    await prefs.setString(_savingsGoalsKey, jsonEncode(goals));
  }

  static Future<List<Map<String, dynamic>>> loadSavingsGoals() async {
    final prefs = await _prefs();
    final data = prefs.getString(_savingsGoalsKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    return List<Map<String, dynamic>>.from(
      (decoded as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<void> clearSavingsGoals() async {
    final prefs = await _prefs();
    await prefs.remove(_savingsGoalsKey);
  }

  // ============================================================
  // BUDGET
  // ============================================================

  static Future<void> saveBudget(double budget) async {
    final prefs = await _prefs();
    await prefs.setDouble(_budgetKey, budget);
  }

  static Future<double> loadBudget() async {
    final prefs = await _prefs();
    return prefs.getDouble(_budgetKey) ?? 800.0;
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  static Future<void> saveSchedule(List<Map<String, dynamic>> schedule) async {
    final prefs = await _prefs();
    await prefs.setString(_scheduleKey, jsonEncode(schedule));
  }

  static Future<List<Map<String, dynamic>>> loadSchedule() async {
    final prefs = await _prefs();
    final data = prefs.getString(_scheduleKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    return List<Map<String, dynamic>>.from(
      (decoded as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // ============================================================
  // FIRST DAY OF WEEK
  // ============================================================

  static Future<void> saveFirstDayOfWeek(int day) async {
    final prefs = await _prefs();
    await prefs.setInt(_firstDayKey, day);
  }

  static Future<int> loadFirstDayOfWeek() async {
    final prefs = await _prefs();
    return prefs.getInt(_firstDayKey) ?? DateTime.monday;
  }
}
