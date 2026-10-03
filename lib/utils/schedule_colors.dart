import 'package:flutter/material.dart';

import '../models/models.dart';

class ScheduleSubjectColor {
  const ScheduleSubjectColor({
    required this.background,
    required this.border,
    required this.accent,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color accent;
  final Color foreground;
}

String subjectKeyForScheduleItem(ScheduleItem item) {
  final code = item.courseCode?.trim();
  if (code != null && code.isNotEmpty) return code.toUpperCase();
  final name = item.courseName?.trim();
  if (name != null && name.isNotEmpty) return name.toUpperCase();
  return item.title.trim().toUpperCase();
}

ScheduleSubjectColor colorForSubject(String subjectKey, Brightness brightness) {
  // Stable djb2 hash so colors don't shuffle between rebuilds/restarts.
  var hash = 5381;
  for (var i = 0; i < subjectKey.length; i++) {
    hash = ((hash << 5) + hash + subjectKey.codeUnitAt(i)) & 0x7fffffff;
  }

  const lightBasePalette = <Color>[
    Color(0xFF4F7CFF), // blue
    Color(0xFF8B5CF6), // violet
    Color(0xFF0EA5A4), // teal
    Color(0xFF22A06B), // green
    Color(0xFFD97706), // amber
    Color(0xFFEA580C), // orange
    Color(0xFFDB2777), // pink
    Color(0xFF0284C7), // sky
    Color(0xFF65A30D), // lime
    Color(0xFF7C3AED), // purple
    Color(0xFF0D9488), // turquoise
    Color(0xFFBE123C), // rose
  ];

  const darkBasePalette = <Color>[
    Color(0xFF8FA8FF),
    Color(0xFFB79CFF),
    Color(0xFF5EEAD4),
    Color(0xFF6EE7B7),
    Color(0xFFFBBF24),
    Color(0xFFFB923C),
    Color(0xFFF9A8D4),
    Color(0xFF7DD3FC),
    Color(0xFFBEF264),
    Color(0xFFC4B5FD),
    Color(0xFF2DD4BF),
    Color(0xFFFB7185),
  ];

  final palette =
      brightness == Brightness.dark ? darkBasePalette : lightBasePalette;
  final base = palette[hash % palette.length];

  if (brightness == Brightness.dark) {
    return ScheduleSubjectColor(
      background: base.withValues(alpha: 0.22),
      border: base.withValues(alpha: 0.65),
      accent: base,
      foreground: const Color(0xFFF1F5F9),
    );
  }

  // Darken the base color slightly for text/icons so pastel cards stay legible.
  final hsl = HSLColor.fromColor(base);
  final foreground =
      hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();

  return ScheduleSubjectColor(
    background: base.withValues(alpha: 0.14),
    border: base.withValues(alpha: 0.45),
    accent: base,
    foreground: foreground,
  );
}
