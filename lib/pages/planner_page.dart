import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

class PlannerPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onAddTask;
  final Function(int) onToggleTask;
  final Function(int) onDeleteTask;

  const PlannerPage({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime selectedDate = DateTime.now();
  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> addTaskDialog() async {
    final titleController = TextEditingController();
    DateTime dueDate = selectedDate;

    final result = await showDialog<Task>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task name',
                      hintText: 'e.g. Finish assignment',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(formatDate(dueDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          dueDate = picked;
                          displayedMonth = DateTime(picked.year, picked.month);
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      Task(
                        id: 0,
                        title: titleController.text.trim(),
                        dueDate: dueDate,
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

    if (result != null) {
      widget.onAddTask(result);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasTaskOnDate(DateTime date) {
    return widget.tasks.any((task) => _isSameDay(task.dueDate, date));
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;
    final totalCells = ((startingWeekday - 1 + daysInMonth) / 7).ceil() * 7;
    final monthName = '${_monthName(displayedMonth.month)} ${displayedMonth.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: Center(child: Text('Mon', style: TextStyle(fontWeight: FontWeight.w600)))),
              Expanded(child: Center(child: Text('Tue', style: TextStyle(fontWeight: FontWeight.w600)))),
              Expanded(child: Center(child: Text('Wed', style: TextStyle(fontWeight: FontWeight.w600)))),
              Expanded(child: Center(child: Text('Thu', style: TextStyle(fontWeight: FontWeight.w600)))),
              Expanded(child: Center(child: Text('Fri', style: TextStyle(fontWeight: FontWeight.w600)))),
              Expanded(child: Center(child: Text('Sat', style: TextStyle(fontWeight: FontWeight.w600)))),
              Expanded(child: Center(child: Text('Sun', style: TextStyle(fontWeight: FontWeight.w600)))),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 52,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - (startingWeekday - 1) + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final hasTask = _hasTaskOnDate(date);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasTask ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final selectedTasks = widget.tasks.where((task) => _isSameDay(task.dueDate, selectedDate)).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Text(
                  'Planner',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: addTaskDialog,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          _buildCalendar(),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Tasks for ${formatDate(selectedDate)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (selectedTasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('No tasks for this date.'),
                    ),
                  ),
                ...selectedTasks.map(
                  (task) => Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.endToStart,
                    background: _deleteBackground(),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('Delete task?'),
                            content: Text('Remove "${task.title}"?'),
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
                    },
                    onDismissed: (_) {
                      widget.onDeleteTask(task.id);
                    },
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(formatDate(task.dueDate)),
                        trailing: Checkbox(
                          value: task.completed,
                          onChanged: (_) {
                            widget.onToggleTask(task.id);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}
