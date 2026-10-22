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
  // MONTHLY BUDGET (single serialized JSON map)
  // Stored under 'monthly_budgets' as {"2026-10": 1200.0, ...}
  // One entry per month; missing month = no budget configured.
  // Legacy 'monthly_budget' key is left untouched.
  // ============================================================

  static Future<void> saveMonthlyBudget(String monthKey, double budget) async {
    final prefs = await _prefs();
    final current = (await loadMonthlyBudgetMap()) ?? {};
    current[monthKey] = budget;
    await prefs.setString('monthly_budgets', jsonEncode(current));
  }

  static Future<void> deleteMonthlyBudget(String monthKey) async {
    final prefs = await _prefs();
    final current = (await loadMonthlyBudgetMap()) ?? {};
    current.remove(monthKey);
    if (current.isEmpty) {
      await prefs.remove('monthly_budgets');
      return;
    }
    await prefs.setString('monthly_budgets', jsonEncode(current));
  }

  static Future<double?> loadMonthlyBudget(String monthKey) async {
    final map = await loadMonthlyBudgetMap();
    if (map == null) return null;
    final value = map[monthKey];
    if (value == null) return null;
    if (!value.isFinite) return null;
    return value;
  }

  static Future<Map<String, double>?> loadMonthlyBudgetMap() async {
    final prefs = await _prefs();
    final raw = prefs.getString('monthly_budgets');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      // If the stored value is not a map at all, leave it alone for a
      // human to recover (backup key) instead of silently dropping it.
      if (decoded is! Map<String, dynamic>) {
        await prefs.setString('monthly_budgets_backup', raw);
        return null;
      }
      final map = <String, double>{};
      for (final entry in decoded.entries) {
        // JSON may encode whole numbers without a decimal point,
        // so accept any numeric value and normalize to double.
        final value = entry.value;
        if (value is num) {
          final v = value.toDouble();
          if (v.isFinite) map[entry.key] = v;
        }
      }
      return map.isEmpty ? null : map;
    } catch (_) {
      return null;
    }
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
