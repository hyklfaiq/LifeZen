import '../models/expense.dart';

/// yyyy-MM for date, e.g. 2026-11.
String formatMonthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

/// Number of calendar days in the given month (leap-year safe).
int daysInMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0).day;
}

/// Total spend for the given month, using the recorded expense date.
double monthlySpent(List<Expense> expenses, String monthKey) {
  double sum = 0.0;
  for (final expense in expenses) {
    if (formatMonthKey(expense.date) == monthKey) {
      sum += expense.amount;
    }
  }
  return sum;
}

/// Remaining budget for the selected month.
double remainingBudget(double budget, double spent) {
  return budget - spent;
}

/// Budget utilization as a percentage (0.0-100.0), null if budget is 0/unknown.
double? budgetUtilization(double spent, double budget) {
  if (budget <= 0) return null;
  return (spent / budget) * 100.0;
}

/// Monthly budget derived from a daily target.
double dailyToMonthly(double daily, int days) {
  return daily * days;
}

/// Daily target derived from a monthly budget.
double monthlyToDaily(double monthly, int days) {
  return monthly / days;
}

/// Remaining allowance per day among the remaining days of the month.
/// Returns null when there are no remaining days.
/// (month is over).
double? remainingDailyAllowance(double remaining, int remainingDays) {
  if (remainingDays <= 0) return null;
  return remaining / remainingDays;
}
