import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  final List<Task> tasks;
  final Function(Task) onAddTask;
  final Future<void> Function(int) onToggleTask;
  final Function(int) onDeleteTask;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime selectedDate = DateTime.now();

  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasTaskOnDate(DateTime date) {
    return widget.tasks.any((task) => _isSameDay(task.dueDate, date));
  }

  String _monthName(int month) {
    const months = [
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

    return months[month - 1];
  }

  Future<void> _addTaskDialog() async {
    final result = await showDialog<Task>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _AddTaskDialog(initialDate: selectedDate);
      },
    );

    if (!mounted) return;

    if (result != null) {
      widget.onAddTask(result);
    }
  }

  Widget _buildCalendar(bool isLandscape) {
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    final leadingEmptyDays = firstDayOfMonth.weekday - 1;
    final totalCells = leadingEmptyDays + daysInMonth;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isLandscape ? 12 : 16,
        isLandscape ? 0 : 8,
        isLandscape ? 12 : 16,
        isLandscape ? 4 : 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: isLandscape
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(
                      displayedMonth.year,
                      displayedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthName(displayedMonth.month)} '
                    '${displayedMonth.year}',
                    style: TextStyle(
                      fontSize: isLandscape ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                visualDensity: isLandscape
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(
                      displayedMonth.year,
                      displayedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          SizedBox(height: isLandscape ? 2 : 6),

          Row(
            children: [
              _weekday('Mon', isLandscape),
              _weekday('Tue', isLandscape),
              _weekday('Wed', isLandscape),
              _weekday('Thu', isLandscape),
              _weekday('Fri', isLandscape),
              _weekday('Sat', isLandscape),
              _weekday('Sun', isLandscape),
            ],
          ),

          SizedBox(height: isLandscape ? 2 : 6),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: isLandscape ? 1 : 2,
              crossAxisSpacing: isLandscape ? 1 : 2,
              mainAxisExtent: isLandscape ? 34 : 46,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }

              final day = index - leadingEmptyDays + 1;

              final date = DateTime(
                displayedMonth.year,
                displayedMonth.month,
                day,
              );

              final isSelected = _isSameDay(date, selectedDate);

              final hasTask = _hasTaskOnDate(date);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                },
                child: Center(
                  child: Container(
                    width: isLandscape ? 29 : 34,
                    height: isLandscape ? 29 : 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: isLandscape ? 12 : 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                        if (hasTask)
                          Positioned(
                            bottom: isLandscape ? 1 : 2,
                            child: Container(
                              width: isLandscape ? 3 : 4,
                              height: isLandscape ? 3 : 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _weekday(String text, bool isLandscape) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: isLandscape ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, bool isLandscape) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        widget.onDeleteTask(task.id);
      },
      background: _deleteBackground(),
      child: Card(
        margin: EdgeInsets.only(bottom: isLandscape ? 6 : 10),
        child: ListTile(
          dense: isLandscape,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 12 : 16,
            vertical: isLandscape ? 2 : 4,
          ),

          // FIX:
          // MainScreen owns the task state.
          // It updates the task + calls setState immediately.
          leading: Checkbox(
            value: task.completed,
            onChanged: (_) {
              widget.onToggleTask(task.id);
            },
          ),

          title: Text(
            task.title,
            style: TextStyle(
              fontSize: isLandscape ? 16 : 18,
              decoration: task.completed ? TextDecoration.lineThrough : null,
            ),
          ),

          subtitle: Text(
            'Due ${formatDate(task.dueDate)}',
            style: TextStyle(fontSize: isLandscape ? 11 : 13),
          ),
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildTasks(bool isLandscape) {
    final selectedTasks = widget.tasks
        .where((task) => _isSameDay(task.dueDate, selectedDate))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isLandscape ? 16 : 20,
        isLandscape ? 6 : 12,
        isLandscape ? 16 : 20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks',
            style: TextStyle(
              fontSize: isLandscape ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (selectedTasks.isNotEmpty) ...[
            const SizedBox(height: 6),
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

          SizedBox(height: isLandscape ? 6 : 10),

          if (selectedTasks.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isLandscape ? 12 : 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: isLandscape ? 36 : 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    SizedBox(height: isLandscape ? 4 : 8),
                    Text(
                      'No tasks for this day',
                      style: TextStyle(
                        fontSize: isLandscape ? 13 : 15,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...selectedTasks.map(
              (task) => _buildTaskCard(context, task, isLandscape),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Planner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _addTaskDialog,
                      tooltip: 'Add task',
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),

              _buildCalendar(true),

              const Divider(height: 1),

              _buildTasks(true),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Planner',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _addTaskDialog,
                  tooltip: 'Add task',
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          _buildCalendar(false),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [_buildTasks(false)],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD TASK DIALOG
// ============================================================

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  late final TextEditingController _titleController;

  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _dueDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(Task(id: 0, title: title, dueDate: _dueDate));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _submit();
              },
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Due date'),
              subtitle: Text(formatDate(_dueDate)),
              onTap: _pickDate,
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
