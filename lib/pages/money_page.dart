import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

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
                  onPressed: () => showAddExpenseDialog(context),
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
                            'Budget: RM${monthlyBudget.toStringAsFixed(2)}',
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
              onPressed: () => showBudgetDialog(context),
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

            if (expenses.isNotEmpty) ...[
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

            if (expenses.isEmpty) _emptyCard('No expenses yet.'),

            ...expenses.map(
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
              'RM${goal.currentAmount.toStringAsFixed(2)} / '
              'RM${goal.targetAmount.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showAddSavingsDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showRemoveSavingsDialog(context),
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

  // ---------------------------------------------------------------------------
  // ADD EXPENSE
  // ---------------------------------------------------------------------------

  Future<void> showAddExpenseDialog(BuildContext context) async {
    final result = await showDialog<Expense>(
      context: context,
      builder: (_) => const _AddExpenseDialog(),
    );

    if (result != null) {
      onAddExpense(result);
    }
  }

  // ---------------------------------------------------------------------------
  // BUDGET
  // ---------------------------------------------------------------------------

  Future<void> showBudgetDialog(BuildContext context) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _BudgetDialog(initialBudget: monthlyBudget),
    );

    if (result != null) {
      onUpdateBudget(result);
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE SAVINGS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // EDIT SAVINGS
  // ---------------------------------------------------------------------------

  Future<void> showEditSavingsDialog(BuildContext context) async {
    final goal = savingsGoal;

    if (goal == null) return;

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
      name: result.name,
      targetAmount: result.targetAmount,
      imagePath: result.imagePath,
    );
  }

  // ---------------------------------------------------------------------------
  // ADD SAVINGS
  // ---------------------------------------------------------------------------

  Future<void> showAddSavingsDialog(BuildContext context) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) =>
          const _SavingsAmountDialog(title: 'Add Savings', buttonText: 'Add'),
    );

    if (result != null) {
      onAddSavings(result);
    }
  }

  // ---------------------------------------------------------------------------
  // REMOVE SAVINGS
  // ---------------------------------------------------------------------------

  Future<void> showRemoveSavingsDialog(BuildContext context) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => const _SavingsAmountDialog(
        title: 'Remove Savings',
        buttonText: 'Remove',
      ),
    );

    if (result != null) {
      onRemoveSavings(result);
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE SAVINGS
  // ---------------------------------------------------------------------------

  Future<void> showDeleteSavingsDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete savings goal?'),
          content: const Text(
            'This will remove the goal and its saved progress.',
          ),
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
      onDeleteSavings();
    }
  }
}

// =============================================================================
// ADD EXPENSE DIALOG
// =============================================================================

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

// =============================================================================
// BUDGET DIALOG
// =============================================================================

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

// =============================================================================
// SAVINGS GOAL RESULT
// =============================================================================

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

// =============================================================================
// CREATE / EDIT SAVINGS DIALOG
// =============================================================================

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

// =============================================================================
// ADD / REMOVE SAVINGS AMOUNT DIALOG
// =============================================================================

class _SavingsAmountDialog extends StatefulWidget {
  const _SavingsAmountDialog({required this.title, required this.buttonText});

  final String title;
  final String buttonText;

  @override
  State<_SavingsAmountDialog> createState() => _SavingsAmountDialogState();
}

class _SavingsAmountDialogState extends State<_SavingsAmountDialog> {
  late final TextEditingController _controller;

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

    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          prefixText: 'RM ',
          labelText: 'Amount',
        ),
        onSubmitted: (_) => _submit(),
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
