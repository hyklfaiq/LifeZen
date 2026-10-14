import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  final List<Task> tasks;
  final Function(Task) onAddTask;
  final Function(Task) onUpdateTask;
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
    return widget.tasks.any((task) {
      final d = task.displayDate;
      return d != null && _isSameDay(d, date);
    });
  }

  String _taskSubtitle(Task task) {
    final parts = <String>[];
    if (task.doAt != null) parts.add('Do ${formatDateTime(task.doAt!)}');
    if (task.dueDate != null) parts.add('Due ${formatDate(task.dueDate!)}');
    if (parts.isEmpty) return 'Floating • no notification';
    final effective = task.effectiveReminderMinutes;
    if (effective < 0) {
      parts.add('No notification');
    } else if (task.doAt != null) {
      parts.add(formatReminderLabel(effective));
    } else {
      // Due-only: anchor is 9 AM on the due date.
      parts.add(
        effective == 0 ? '9:00 AM' : '9:00 AM (${formatReminderLabel(effective)})',
      );
    }
    return parts.join('  •  ');
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
        return _TaskEditorDialog(initialDate: selectedDate);
      },
    );

    if (!mounted) return;

    if (result != null) {
      widget.onAddTask(result);
    }
  }

  Future<void> _editTaskDialog(Task task) async {
    final result = await showDialog<Task>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _TaskEditorDialog(
          initialDate: selectedDate,
          existing: task,
        );
      },
    );

    if (!mounted) return;

    if (result != null) {
      widget.onUpdateTask(result);
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
            _taskSubtitle(task),
            style: TextStyle(fontSize: isLandscape ? 11 : 13),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit task',
            onPressed: () => _editTaskDialog(task),
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
        .where((task) {
          final d = task.displayDate;
          return d != null && _isSameDay(d, selectedDate);
        })
        .toList();
    final floatingTasks =
        widget.tasks.where((task) => task.isFloating).toList();

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

          if (floatingTasks.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Floating (${floatingTasks.length})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...floatingTasks.map(
              (task) => _buildTaskCard(context, task, isLandscape),
            ),
            const SizedBox(height: 10),
          ],

          Text(
            'On ${formatDate(selectedDate)}',
            style: TextStyle(
              fontSize: isLandscape ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),

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
// TASK EDITOR DIALOG (Google-Tasks-like: optional Due + When-to-do)
// ============================================================

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({
    required this.initialDate,
    this.existing,
  });

  final DateTime initialDate;
  final Task? existing;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late final TextEditingController _titleController;

  DateTime? _dueDate;
  DateTime? _doAt;
  int? _reminderMinutes;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _dueDate = existing?.dueDate;
    _doAt = existing?.doAt;
    _reminderMinutes = existing?.reminderMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? widget.initialDate,
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

  Future<void> _pickDoAt() async {
    final picked = await pickDateTime(
      context,
      _doAt ?? widget.initialDate,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _doAt = picked;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      Task(
        id: widget.existing?.id ?? 0,
        title: title,
        dueDate: _dueDate,
        doAt: _doAt,
        reminderMinutes: _reminderMinutes,
        completed: widget.existing?.completed ?? false,
      ),
    );
  }

  /// Live hint describing what the current selection will do.
  String _reminderHint() {
    final effective = _reminderMinutes ??
        Task.smartDefaultReminder(dueDate: _dueDate, doAt: _doAt);
    if (effective < 0) return 'No notification will be scheduled.';
    if (_doAt != null) {
      final at = _doAt!.subtract(Duration(minutes: effective));
      var hint =
          'Notifies ${formatDateTime(at)} '
          '(${formatReminderLabel(effective)}).';
      if (_dueDate != null) {
        // The planned time drives the main reminder; the deadline gets
        // its own notification at 9:00 AM on the due date.
        final dueLead = _reminderMinutes ?? 0;
        final dueAt = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          9,
          0,
        ).subtract(Duration(minutes: dueLead));
        hint += ' Due date also reminds ${formatDateTime(dueAt)}.';
      }
      return hint;
    }
    if (_dueDate != null) {
      if (effective == 0) {
        return 'Notifies 9:00 AM on ${formatDate(_dueDate!)}.';
      }
      final at = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        9,
        0,
      ).subtract(Duration(minutes: effective));
      return 'Notifies ${formatDateTime(at)} '
          '(${formatReminderLabel(effective)}).';
    }
    return 'Add a due date or scheduled time to enable notifications.';
  }

  @override
  Widget build(BuildContext context) {
    final isFloating = _dueDate == null && _doAt == null;
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Task' : 'Add Task'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _submit();
              },
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Due date'),
              subtitle: Text(
                _dueDate == null ? 'No due date' : formatDate(_dueDate!),
              ),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() => _dueDate = null),
                    ),
              onTap: _pickDueDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Planned time'),
              subtitle: Text(
                _doAt == null ? 'No time set' : formatDateTime(_doAt!),
              ),
              trailing: _doAt == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear time',
                      onPressed: () => setState(() => _doAt = null),
                    ),
              onTap: _pickDoAt,
            ),

            if (isFloating)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Floating task — leave both empty to keep it at the top '
                  'until you give it a date.',
                  style: TextStyle(fontSize: 12),
                ),
              ),

            const SizedBox(height: 12),

            // The reminder only makes sense once the task has an anchor
            // (due date or planned time) — floating tasks never notify.
            if (_dueDate != null || _doAt != null) ...[
              const Text(
                'Reminder',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _reminderHint(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ReminderPicker(
                value: _reminderMinutes,
                smartDueDate: _dueDate,
                smartDoAt: _doAt,
                onChanged: (v) => setState(() => _reminderMinutes = v),
              ),
            ],
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

        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
