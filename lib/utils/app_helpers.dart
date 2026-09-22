import 'package:flutter/material.dart';

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${formatDate(date)} $hour:$minute';
}

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';

  return '$hour:$minute $period';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0) {
    return '${minutes}m';
  }

  return '${hours}h ${minutes}m';
}

String sleepQuality(Duration duration) {
  final hours = duration.inMinutes / 60;

  if (hours >= 7 && hours <= 9) {
    return 'Good';
  }

  if (hours >= 6) {
    return 'Okay';
  }

  return 'Low';
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant_outlined;
    case 'Transport':
      return Icons.directions_bus_outlined;
    case 'Education':
      return Icons.school_outlined;
    case 'Entertainment':
      return Icons.movie_outlined;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Bills':
      return Icons.receipt_long_outlined;
    default:
      return Icons.more_horiz;
  }
}

Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );

  if (date == null) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );

  if (time == null) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
