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
  }) onCreateSavings;

  final Future<void> Function({
    required String name,
    required double targetAmount,
    String? imagePath,
  }) onEditSavings;
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
              'RM${goal.currentAmount.toStringAsFixed(2)} / RM${goal.targetAmount.toStringAsFixed(2)}',
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
                        DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                        DropdownMenuItem(value: 'Education', child: Text('Education')),
                        DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                        DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text.trim());
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
              onPressed: () => Navigator.pop(dialogContext),
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
                setDialogState(() => imagePath = picked.path);
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
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              backgroundImage: imagePath == null ? null : FileImage(File(imagePath!)),
                              child: imagePath == null
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
                                child: const Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      imagePath == null ? 'Add a photo (optional)' : 'Tap to change photo',
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final target = double.tryParse(targetController.text.trim());
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
                setDialogState(() => imagePath = picked.path);
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
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              backgroundImage: imagePath == null ? null : FileImage(File(imagePath!)),
                              child: imagePath == null
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
                                child: const Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      imagePath == null ? 'Add a photo (optional)' : 'Tap to change photo',
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final target = double.tryParse(targetController.text.trim());
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
              onPressed: () => Navigator.pop(dialogContext),
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
              onPressed: () => Navigator.pop(dialogContext),
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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
