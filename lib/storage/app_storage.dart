import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _themeKey = 'theme_mode';
  static const String _tasksKey = 'tasks';
  static const String _sleepKey = 'sleep_records';
  static const String _expensesKey = 'expenses';
  static const String _savingsGoalsKey = 'savings_goals';
  static const String _budgetKey = 'monthly_budget';
  static const String _scheduleKey = 'schedule';
  static const String _firstDayKey = 'first_day_of_week';
  static const String _sleepGoalKey = 'sleep_goal';

  static const String _monthlyBudgetsKey = 'monthly_budgets';
  static const String _monthlyBudgetsBackupKey = 'monthly_budgets_backup';

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  // Reads a saved list and converts it back into a list of maps.
  // Returns an empty list when there is no saved data.
  static Future<List<Map<String, dynamic>>> _loadList(String key) async {
    final prefs = await _prefs();
    final data = prefs.getString(key);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  // Saves a list as JSON in local storage.
  static Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(items));
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
    await _saveList(_tasksKey, tasks);
  }

  static Future<List<Map<String, dynamic>>> loadTasks() async {
    return _loadList(_tasksKey);
  }

  // ============================================================
  // SLEEP RECORDS
  // ============================================================

  static Future<void> saveSleepRecords(
    List<Map<String, dynamic>> records,
  ) async {
    await _saveList(_sleepKey, records);
  }

  static Future<List<Map<String, dynamic>>> loadSleepRecords() async {
    return _loadList(_sleepKey);
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
  // EXPENSES
  // ============================================================

  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    await _saveList(_expensesKey, expenses);
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    return _loadList(_expensesKey);
  }

  // ============================================================
  // SAVINGS GOALS
  // ============================================================

  static Future<void> saveSavingsGoals(List<Map<String, dynamic>> goals) async {
    await _saveList(_savingsGoalsKey, goals);
  }

  static Future<List<Map<String, dynamic>>> loadSavingsGoals() async {
    return _loadList(_savingsGoalsKey);
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
  // MONTHLY BUDGET
  // ============================================================

  // Each month has its own budget.
  // Example: {"2026-10": 1200.0, "2026-11": 1500.0}
  //
  // The old monthly_budget key is kept for existing data.

  static Future<void> saveMonthlyBudget(String monthKey, double budget) async {
    final prefs = await _prefs();
    final current = await loadMonthlyBudgetMap() ?? {};

    current[monthKey] = budget;

    await prefs.setString(_monthlyBudgetsKey, jsonEncode(current));
  }

  static Future<void> deleteMonthlyBudget(String monthKey) async {
    final prefs = await _prefs();
    final current = await loadMonthlyBudgetMap() ?? {};

    current.remove(monthKey);

    if (current.isEmpty) {
      await prefs.remove(_monthlyBudgetsKey);
      return;
    }

    await prefs.setString(_monthlyBudgetsKey, jsonEncode(current));
  }

  static Future<double?> loadMonthlyBudget(String monthKey) async {
    final map = await loadMonthlyBudgetMap();

    if (map == null) return null;

    return map[monthKey];
  }

  static Future<Map<String, double>?> loadMonthlyBudgetMap() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_monthlyBudgetsKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      // Keep a copy of invalid data in case it needs to be recovered.
      if (decoded is! Map<String, dynamic>) {
        await prefs.setString(_monthlyBudgetsBackupKey, raw);
        return null;
      }

      final map = <String, double>{};

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is num) {
          final amount = value.toDouble();

          if (amount.isFinite) {
            map[entry.key] = amount;
          }
        }
      }

      return map.isEmpty ? null : map;
    } catch (_) {
      // Return null if the saved JSON cannot be decoded.
      return null;
    }
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  static Future<void> saveSchedule(List<Map<String, dynamic>> schedule) async {
    await _saveList(_scheduleKey, schedule);
  }

  static Future<List<Map<String, dynamic>>> loadSchedule() async {
    return _loadList(_scheduleKey);
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
