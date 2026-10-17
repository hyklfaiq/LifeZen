import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';
import '../utils/budget_calculator.dart';

class MoneyPage extends StatelessWidget {
  final List<Expense> expenses;

  /// Month currently displayed, owned by MainScreen (defaults to now).
  final DateTime selectedMonth;

  /// Per-month budgets keyed 'yyyy-MM'. Missing entry = no budget.
  final Map<String, double> monthlyBudgets;

  // Multiple savings goals
  final List<SavingsGoal> savingsGoals;

  final Function(Expense) onAddExpense;
  final Function(int) onDeleteExpense;

  /// Month navigation + per-month budget writes (owned by MainScreen).
  final ValueChanged<DateTime> onMonthChanged;
  final Future<void> Function(String monthKey, double amount)
  onUpdateMonthlyBudget;

  // Create a new savings goal
  final Future<void> Function({
    required String name,
    required double targetAmount,
    String? imagePath,
  })
  onCreateSavings;

  // Edit an existing savings goal
  final Future<void> Function({
    required String id,
    required String name,
    required double targetAmount,
    String? imagePath,
  })
  onEditSavings;

  // Add/remove money from a specific goal.
  // `countAsSpending` controls whether an Add transfer also reduces the
  // remaining budget (recorded as a Transfer expense).
  final Future<void> Function(String id, double amount, {bool countAsSpending})
  onAddSavings;
  final Future<void> Function(String id, double amount) onRemoveSavings;

  // Delete a specific goal
  final Future<void> Function(String id) onDeleteSavings;

  const MoneyPage({
    super.key,
    required this.expenses,
    required this.selectedMonth,
    required this.monthlyBudgets,
    required this.savingsGoals,
    required this.onAddExpense,
    required this.onDeleteExpense,
    required this.onMonthChanged,
    required this.onUpdateMonthlyBudget,
    required this.onCreateSavings,
    required this.onEditSavings,
    required this.onAddSavings,
    required this.onRemoveSavings,
    required this.onDeleteSavings,
  });

  @override
  Widget build(BuildContext context) {
    final key = formatMonthKey(selectedMonth);
    final monthlyBudget = monthlyBudgets[key];

    final monthExpenses = expenses
        .where((expense) => formatMonthKey(expense.date) == key)
        .toList();

    // True when the viewed month has already ended, so the user can
    // jump back to the current month instead of seeing a stale month.
    final today = DateTime.now();
    final isPastMonth =
        selectedMonth.year < today.year ||
        (selectedMonth.year == today.year && selectedMonth.month < today.month);

    final totalSpent = monthlySpent(expenses, key);

    final transferredThisMonth = monthExpenses
        .where((expense) => expense.category == 'Transfer')
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final remaining = monthlyBudget == null
        ? null
        : remainingBudget(monthlyBudget, totalSpent);
    final weeklyBudget = monthlyBudget == null ? null : monthlyBudget / 4;

    final utilization = monthlyBudget == null
        ? null
        : budgetUtilization(totalSpent, monthlyBudget);
    final budgetProgress = (utilization ?? 0.0).clamp(0.0, 100.0) / 100.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // HEADER
            // ============================================================
            const Text(
              'Money',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // MONTH SELECTOR
            // ============================================================
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onMonthChanged(
                        DateTime(selectedMonth.year, selectedMonth.month - 1),
                      ),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous month',
                    ),
                    Expanded(
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => _pickMonth(context),
                          icon: const Icon(Icons.expand_more),
                          label: Text(
                            _monthLabel(selectedMonth),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onMonthChanged(
                        DateTime(selectedMonth.year, selectedMonth.month + 1),
                      ),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next month',
                    ),
                  ],
                ),
                if (isPastMonth)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TextButton.icon(
                      onPressed: () =>
                          onMonthChanged(DateTime(today.year, today.month)),
                      icon: const Icon(Icons.today, size: 16),
                      label: Text('Jump to ${_monthLabel(today)}'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ============================================================
            // MONTHLY SPENDING
            // ============================================================
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
                    if (utilization != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${utilization.toStringAsFixed(1)}% used',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  showBudgetDialog(context, key, monthlyBudget),
                              icon: Icon(
                                monthlyBudget == null
                                    ? Icons.add
                                    : Icons.edit_outlined,
                                size: 16,
                              ),
                              label: Text(
                                monthlyBudget == null
                                    ? 'Set budget'
                                    : 'RM${monthlyBudget.toStringAsFixed(2)}',
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                        Builder(
                          builder: (_) {
                            if (remaining == null) {
                              return const Text('');
                            }
                            return Text(
                              remaining >= 0
                                  ? 'RM${remaining.toStringAsFixed(2)} left'
                                  : 'RM${remaining.abs().toStringAsFixed(2)} over',
                              style: TextStyle(
                                color: remaining >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (transferredThisMonth > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Includes RM${transferredThisMonth.toStringAsFixed(2)} transferred to savings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showBudgetDialog(context, key, monthlyBudget),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      monthlyBudget == null ? 'Set budget' : 'Edit budget',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showAddExpenseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add expense',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ============================================================
            // WEEKLY BUDGET
            // ============================================================
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('Weekly budget'),
                subtitle: const Text('Based on your monthly budget'),
                trailing: Text(
                  weeklyBudget == null
                      ? '—'
                      : 'RM${weeklyBudget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // DAILY BUDGET CALCULATOR
            // ============================================================
            _DailyBudgetCard(
              selectedMonth: selectedMonth,
              monthlyBudget: monthlyBudget,
              totalSpent: totalSpent,
              remaining: remaining,
              monthKey: key,
              onApplyBudget: (amount) =>
                  showBudgetDialog(context, key, monthlyBudget, amount: amount),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // EXPENSE HISTORY (selected month only)
            // ============================================================
            Row(
              children: [
                const Text(
                  'Expenses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${monthExpenses.length} items',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),

            if (monthExpenses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.swipe_left_alt_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe left to delete',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            if (monthExpenses.isEmpty)
              _emptyCard('No expenses in ${_monthLabel(selectedMonth)}.'),

            ...monthExpenses.map(
              (expense) => Dismissible(
                key: ValueKey('expense_${expense.id}'),
                direction: DismissDirection.endToStart,
                background: _deleteBackground(),
                onDismissed: (_) => onDeleteExpense(expense.id),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(categoryIcon(expense.category)),
                    ),
                    title: Text(expense.title),
                    subtitle: Text(
                      '${expense.category} • ${formatDate(expense.date)}',
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

            // ============================================================
            // SAVINGS HEADER
            // ============================================================
            Row(
              children: [
                const Text(
                  'Savings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => showCreateSavingsDialog(context),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add savings goal',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ============================================================
            // SAVINGS GOALS (top-3 + view all)
            // ============================================================
            if (savingsGoals.isEmpty)
              _buildEmptySavings(context)
            else ...[
              ...savingsGoals
                  .take(3)
                  .map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSavingsCard(context, goal),
                    ),
                  ),
              if (savingsGoals.length > 3)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAllSavings(context),
                    icon: const Icon(Icons.savings_outlined, size: 18),
                    label: Text('View all (${savingsGoals.length})'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Month picker so the month label is a real control, not a dead one.
  Future<void> _pickMonth(BuildContext context) async {
    var year = selectedMonth.year;
    var month = selectedMonth.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Select month'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setDialogState(() => year--),
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Previous year',
                        ),
                        Text(
                          year.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setDialogState(() => year++),
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Next year',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var m = 1; m <= 12; m++)
                          ChoiceChip(
                            label: Text(_monthNames[m - 1].substring(0, 3)),
                            selected: m == month,
                            onSelected: (_) => setDialogState(() => month = m),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(DateTime(year, month)),
                  child: const Text('Go'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted || result == null) return;
    onMonthChanged(result);
  }

  // ================================================================
  // MONTH LABEL
  // ================================================================

  static const List<String> _monthNames = [
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

  String _monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  // ================================================================
  // EMPTY SAVINGS
  // ================================================================

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
              'No savings goals yet.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a goal to start tracking your savings.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showCreateSavingsDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create savings goal'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SAVINGS CARD
  // ================================================================

  Widget _buildSavingsCard(BuildContext context, SavingsGoal goal) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------
            // Goal header
            // ------------------------------------------------------------
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
                      showEditSavingsDialog(context, goal);
                    }

                    if (value == 'delete') {
                      showDeleteSavingsDialog(context, goal);
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

            // ------------------------------------------------------------
            // Progress
            // ------------------------------------------------------------
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
              'RM${goal.currentAmount.toStringAsFixed(2)} / '
              'RM${goal.targetAmount.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------------
            // Add / Remove
            // ------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showAddSavingsDialog(context, goal),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showRemoveSavingsDialog(context, goal),
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

  // ================================================================
  // EMPTY CARD
  // ================================================================

  Widget _emptyCard(String text) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text)),
      ),
    );
  }

  // ================================================================
  // DELETE BACKGROUND
  // ================================================================

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

  // ================================================================
  // ADD EXPENSE
  // ================================================================

  Future<void> showAddExpenseDialog(BuildContext context) async {
    final result = await showDialog<Expense>(
      context: context,
      builder: (_) => const _AddExpenseDialog(),
    );

    if (result != null) {
      onAddExpense(result);
    }
  }

  // ================================================================
  // BUDGET
  // ================================================================

  Future<void> showBudgetDialog(
    BuildContext context,
    String monthKey,
    double? existingBudget, {
    double? amount,
  }) async {
    double? result = amount;
    result ??= await showDialog<double>(
      context: context,
      builder: (_) => _BudgetDialog(initialBudget: existingBudget ?? 0),
    );
    // Confirm before replacing an existing budget for this month.
    if (!context.mounted) return;
    if (result != null &&
        existingBudget != null &&
        (result - existingBudget).abs() > 0.005) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Replace budget?'),
          content: Text(
            'This month already has a budget of '
            'RM${existingBudget.toStringAsFixed(2)}. '
            'Replace it with RM${result!.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep existing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (result != null) {
      await onUpdateMonthlyBudget(monthKey, result);
    }
  }

  // ================================================================
  // CREATE SAVINGS
  // ================================================================

  Future<void> showCreateSavingsDialog(BuildContext context) async {
    final result = await showDialog<_SavingsDialogResult>(
      context: context,
      builder: (_) => const _SavingsDialog(
        title: 'Create Savings Goal',
        buttonText: 'Create',
      ),
    );

    if (result == null) return;

    await onCreateSavings(
      name: result.name,
      targetAmount: result.targetAmount,
      imagePath: result.imagePath,
    );
  }

  // ================================================================
  // EDIT SAVINGS
  // ================================================================

  Future<void> showEditSavingsDialog(
    BuildContext context,
    SavingsGoal goal,
  ) async {
    final result = await showDialog<_SavingsDialogResult>(
      context: context,
      builder: (_) => _SavingsDialog(
        title: 'Edit Savings Goal',
        buttonText: 'Save',
        initialName: goal.name,
        initialTarget: goal.targetAmount,
        initialImagePath: goal.imagePath,
      ),
    );

    if (result == null) return;

    await onEditSavings(
      id: goal.id,
      name: result.name,
      targetAmount: result.targetAmount,
      imagePath: result.imagePath,
    );
  }

  // ================================================================
  // ADD SAVINGS
  // ================================================================

  Future<void> showAddSavingsDialog(
    BuildContext context,
    SavingsGoal goal,
  ) async {
    final result = await showDialog<_TransferDialogResult>(
      context: context,
      builder: (_) => const _SavingsAmountDialog(
        title: 'Add Savings',
        buttonText: 'Add',
        showBudgetToggle: true,
      ),
    );

    if (result != null) {
      await onAddSavings(
        goal.id,
        result.amount,
        countAsSpending: result.countAsSpending,
      );
    }
  }

  void _showAllSavings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const ListTile(
                title: Text(
                  'All savings goals',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final goal in savingsGoals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSavingsCard(sheetContext, goal),
                ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // REMOVE SAVINGS
  // ================================================================

  Future<void> showRemoveSavingsDialog(
    BuildContext context,
    SavingsGoal goal,
  ) async {
    final result = await showDialog<_TransferDialogResult>(
      context: context,
      builder: (_) => const _SavingsAmountDialog(
        title: 'Remove Savings',
        buttonText: 'Remove',
      ),
    );

    if (result != null) {
      await onRemoveSavings(goal.id, result.amount);
    }
  }

  // ================================================================
  // DELETE SAVINGS
  // ================================================================

  Future<void> showDeleteSavingsDialog(
    BuildContext context,
    SavingsGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete savings goal?'),
          content: Text('Delete "${goal.name}" and its saved progress?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await onDeleteSavings(goal.id);
    }
  }
}

// ============================================================================
// ADD EXPENSE DIALOG
// ============================================================================

class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  String _category = 'Food';

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();

    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      return;
    }

    Navigator.of(context).pop(
      Expense(
        id: 0,
        title: title,
        amount: amount,
        category: _category,
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Expense',
                hintText: 'e.g. Lunch',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'RM ',
              ),
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                DropdownMenuItem(value: 'Education', child: Text('Education')),
                DropdownMenuItem(
                  value: 'Entertainment',
                  child: Text('Entertainment'),
                ),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _category = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

// ============================================================================
// BUDGET DIALOG
// ============================================================================

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.initialBudget});

  final double initialBudget;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialBudget.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text.trim());

    if (amount == null || amount < 0) {
      return;
    }

    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly Budget'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          prefixText: 'RM ',
          labelText: 'Budget',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

// ============================================================================
// DAILY BUDGET CALCULATOR
// ============================================================================

/// Daily target <-> monthly budget converter + remaining daily allowance.
///
/// Pure display widget: never writes storage itself. Applying the
/// calculated budget goes through the page's budget flow (with the
/// replace-confirmation when the month already has a budget).
class _DailyBudgetCard extends StatefulWidget {
  const _DailyBudgetCard({
    required this.selectedMonth,
    required this.monthlyBudget,
    required this.totalSpent,
    required this.remaining,
    required this.monthKey,
    required this.onApplyBudget,
  });

  final DateTime selectedMonth;
  final double? monthlyBudget;
  final double totalSpent;
  final double? remaining;
  final String monthKey;
  final ValueChanged<double> onApplyBudget;

  @override
  State<_DailyBudgetCard> createState() => _DailyBudgetCardState();
}

class _DailyBudgetCardState extends State<_DailyBudgetCard> {
  final TextEditingController _dailyController = TextEditingController();
  double? _previewMonthly;

  @override
  void dispose() {
    _dailyController.dispose();
    super.dispose();
  }

  void _computeFromDaily() {
    final daily = double.tryParse(_dailyController.text.trim());
    if (daily == null || daily <= 0) {
      setState(() => _previewMonthly = null);
      return;
    }
    setState(
      () => _previewMonthly = dailyToMonthly(
        daily,
        daysInMonth(widget.selectedMonth),
      ),
    );
  }

  String _label(DateTime month) {
    return '${_DailyBudgetCardMonth.names[month.month - 1]} '
        '${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final days = daysInMonth(widget.selectedMonth);
    final dailyTarget = widget.monthlyBudget == null
        ? null
        : monthlyToDaily(widget.monthlyBudget!, days);

    final now = DateTime.now();
    final isCurrentMonth =
        now.year == widget.selectedMonth.year &&
        now.month == widget.selectedMonth.month;
    final remainingDays = isCurrentMonth ? days - now.day + 1 : 0;
    final allowance = widget.remaining == null || widget.remaining! < 0
        ? null
        : remainingDailyAllowance(widget.remaining!, remainingDays);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Daily budget calculator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$days days in ${_label(widget.selectedMonth)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: 'RM ',
                labelText: 'Daily target',
                hintText: 'e.g. 30.00',
                helperText: 'Enter an amount per day to see the monthly budget',
              ),
              onChanged: (_) => _computeFromDaily(),
            ),
            const SizedBox(height: 8),
            if (_previewMonthly != null) ...[
              Text(
                'Monthly budget: RM${_previewMonthly!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onApplyBudget(_previewMonthly!),
                  child: Text(
                    widget.monthlyBudget == null
                        ? 'Set as ${_label(widget.selectedMonth)} budget'
                        : 'Replace budget with this amount',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Based on your numbers',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _calcRow(
                    'Daily target',
                    dailyTarget == null
                        ? 'Set a budget first'
                        : 'RM${dailyTarget.toStringAsFixed(2)} / day',
                  ),
                  const SizedBox(height: 6),
                  if (widget.monthlyBudget != null)
                    _calcRow(
                      'Spent so far',
                      'RM${widget.totalSpent.toStringAsFixed(2)}',
                    ),
                  const SizedBox(height: 6),
                  _allowanceRow(allowance, widget.remaining, remainingDays),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _allowanceRow(double? allowance, double? remaining, int daysLeft) {
    if (remaining == null) {
      return _calcRow('Daily allowance', 'Set a budget first');
    }
    if (remaining < 0) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Daily allowance',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(
            'RM${remaining.abs().toStringAsFixed(2)} over',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      );
    }
    if (allowance == null) {
      return _calcRow(
        'Daily allowance',
        daysLeft <= 0 ? 'Month has ended' : '—',
      );
    }
    return _calcRow(
      'Daily allowance',
      'RM${allowance.toStringAsFixed(2)} / day ($daysLeft left)',
    );
  }
}

/// Month names shared by the card above.
class _DailyBudgetCardMonth {
  static const List<String> names = [
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
}

// ============================================================================
// SAVINGS GOAL RESULT
// ============================================================================

class _SavingsDialogResult {
  final String name;
  final double targetAmount;
  final String? imagePath;

  const _SavingsDialogResult({
    required this.name,
    required this.targetAmount,
    required this.imagePath,
  });
}

// ============================================================================
// CREATE / EDIT SAVINGS DIALOG
// ============================================================================

class _SavingsDialog extends StatefulWidget {
  const _SavingsDialog({
    required this.title,
    required this.buttonText,
    this.initialName = '',
    this.initialTarget,
    this.initialImagePath,
  });

  final String title;
  final String buttonText;
  final String initialName;
  final double? initialTarget;
  final String? initialImagePath;

  @override
  State<_SavingsDialog> createState() => _SavingsDialogState();
}

class _SavingsDialogState extends State<_SavingsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;

  String? _imagePath;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _targetController = TextEditingController(
      text: widget.initialTarget?.toStringAsFixed(2) ?? '',
    );

    _imagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();

    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

  void _submit() {
    final name = _nameController.text.trim();

    final target = double.tryParse(_targetController.text.trim());

    if (name.isEmpty || target == null || target <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _SavingsDialogResult(
        name: name,
        targetAmount: target,
        imagePath: _imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      backgroundImage: _imagePath == null
                          ? null
                          : FileImage(File(_imagePath!)),
                      child: _imagePath == null
                          ? const Icon(Icons.add_a_photo_outlined, size: 28)
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
              _imagePath == null
                  ? 'Add a photo (optional)'
                  : 'Tap to change photo',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Goal name',
                hintText: widget.initialName.isEmpty ? 'e.g. New laptop' : null,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: 'RM ',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.buttonText)),
      ],
    );
  }
}

// ============================================================================
// ADD / REMOVE SAVINGS AMOUNT DIALOG
// ============================================================================

class _TransferDialogResult {
  const _TransferDialogResult({
    required this.amount,
    required this.countAsSpending,
  });

  final double amount;
  final bool countAsSpending;
}

class _SavingsAmountDialog extends StatefulWidget {
  const _SavingsAmountDialog({
    required this.title,
    required this.buttonText,
    this.showBudgetToggle = false,
  });

  final String title;
  final String buttonText;
  final bool showBudgetToggle;

  @override
  State<_SavingsAmountDialog> createState() => _SavingsAmountDialogState();
}

class _SavingsAmountDialogState extends State<_SavingsAmountDialog> {
  late final TextEditingController _controller;
  bool _countAsSpending = true;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text.trim());

    if (amount == null || amount <= 0) {
      return;
    }

    if (widget.showBudgetToggle) {
      Navigator.of(context).pop(
        _TransferDialogResult(
          amount: amount,
          countAsSpending: _countAsSpending,
        ),
      );
    } else {
      // Remove-flow still expects a plain double.
      Navigator.of(
        context,
      ).pop(_TransferDialogResult(amount: amount, countAsSpending: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                prefixText: 'RM ',
                labelText: 'Amount',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.showBudgetToggle) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Count as spending',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Reduce remaining budget with a Transfer expense.',
                ),
                value: _countAsSpending,
                onChanged: (v) => setState(() => _countAsSpending = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.buttonText)),
      ],
    );
  }
}
