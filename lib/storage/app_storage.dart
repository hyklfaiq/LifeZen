import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _themeKey = 'theme_mode';

  static const String _tasksKey = 'tasks';
  static const String _sleepKey = 'sleep_records';
  static const String _expensesKey = 'expenses';
  static const String _savingsKey = 'savings_goal';
  static const String _budgetKey = 'monthly_budget';
  static const String _scheduleKey = 'schedule';
  static const String _firstDayKey = 'first_day_of_week';
  static const String _sleepGoalKey = 'sleep_goal';

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  // THEME

  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await _prefs();
    await prefs.setBool(_themeKey, isDark);
  }

  static Future<bool> loadDarkMode() async {
    final prefs = await _prefs();
    return prefs.getBool(_themeKey) ?? false;
  }

  // TASKS

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

  // SLEEP

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

  // SLEEP GOAL

  static Future<void> saveSleepGoal(int hours) async {
    final prefs = await _prefs();
    await prefs.setInt(_sleepGoalKey, hours);
  }

  static Future<int> loadSleepGoal() async {
    final prefs = await _prefs();
    return prefs.getInt(_sleepGoalKey) ?? 8;
  }

  // EXPENSES

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

  // SAVINGS

  static Future<void> saveSavingsGoal(Map<String, dynamic> goal) async {
    final prefs = await _prefs();
    await prefs.setString(_savingsKey, jsonEncode(goal));
  }

  static Future<Map<String, dynamic>?> loadSavingsGoal() async {
    final prefs = await _prefs();
    final data = prefs.getString(_savingsKey);

    if (data == null || data.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static Future<void> clearSavingsGoal() async {
    final prefs = await _prefs();
    await prefs.remove(_savingsKey);
  }

  // BUDGET

  static Future<void> saveBudget(double budget) async {
    final prefs = await _prefs();
    await prefs.setDouble(_budgetKey, budget);
  }

  static Future<double> loadBudget() async {
    final prefs = await _prefs();
    return prefs.getDouble(_budgetKey) ?? 800.0;
  }

  // SCHEDULE

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

  // FIRST DAY OF WEEK

  static Future<void> saveFirstDayOfWeek(int day) async {
    final prefs = await _prefs();
    await prefs.setInt(_firstDayKey, day);
  }

  static Future<int> loadFirstDayOfWeek() async {
    final prefs = await _prefs();
    return prefs.getInt(_firstDayKey) ?? DateTime.monday;
  }
}
