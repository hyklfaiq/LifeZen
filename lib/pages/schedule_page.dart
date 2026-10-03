import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/imaluum/imaluum_timetable.dart';
import '../services/schedule_export/schedule_export.dart';
import '../utils/app_helpers.dart';
import '../utils/schedule_colors.dart';
import 'imaluum_import_page.dart';

enum ScheduleViewMode { fixed, zoom }

class SchedulePage extends StatefulWidget {
  final List<ScheduleItem> schedule;
  final int firstDayOfWeek;
  final Future<void> Function(int day) onFirstDayChanged;
  final Future<void> Function(ScheduleItem item) onAddSchedule;
  final Future<void> Function(ScheduleItem item) onUpdateSchedule;
  final Future<void> Function(int id) onDeleteSchedule;
  final Future<int> Function(List<ImaluumMeeting> meetings) onImportImaluum;
  final Future<void> Function() onClearAll;

  const SchedulePage({
    super.key,
    required this.schedule,
    required this.firstDayOfWeek,
    required this.onFirstDayChanged,
    required this.onAddSchedule,
    required this.onUpdateSchedule,
    required this.onDeleteSchedule,
    required this.onImportImaluum,
    required this.onClearAll,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ===========================================================================
  // VIEW MODE
  // ===========================================================================

  ScheduleViewMode _viewMode = ScheduleViewMode.fixed;

  // ===========================================================================
  // ZOOM CONTROLLER
  // ===========================================================================

  final TransformationController _scheduleTransformController =
      TransformationController();

  bool _scheduleInitialised = false;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  final GlobalKey _gridCaptureKey = GlobalKey();
  final GlobalKey _zoomCaptureKey = GlobalKey();

  String? _exportingKind;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _scheduleTransformController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // EXPORT: BOTTOM SHEET
  // ===========================================================================

  Future<void> _showExportSheet() async {
    if (widget.schedule.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Export schedule'),
                subtitle: Text('Share your timetable as a file.'),
              ),
              _exportTile(
                kind: 'ics',
                icon: Icons.calendar_month_outlined,
                title: 'Calendar (.ics)',
                subtitle: 'Opens in Google, Apple or Outlook Calendar.',
              ),
              _exportTile(
                kind: 'csv',
                icon: Icons.table_chart_outlined,
                title: 'Spreadsheet (.csv)',
                subtitle: 'Opens in Excel or Google Sheets.',
              ),
              _exportTile(
                kind: 'png',
                icon: Icons.image_outlined,
                title: 'Image (.png)',
                subtitle:
                    'Saves the weekly grid as a picture. '
                    'Works from the current view.',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _exportTile({
    required String kind,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final busy = _exportingKind == kind;

    return ListTile(
      leading: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.save_alt_outlined),
        tooltip: 'Save to device',
        onPressed: _exportingKind == null ? () => _saveToDevice(kind) : null,
      ),
      onTap: _exportingKind == null ? () => _exportSchedule(kind) : null,
    );
  }

  // ===========================================================================
  // EXPORT: SHARE LOGIC + PNG CAPTURE
  // ===========================================================================

  String _exportStamp() {
    final now = DateTime.now();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}';
  }

  Future<void> _exportSchedule(String kind) async {
    if (widget.schedule.isEmpty || _exportingKind != null) {
      return;
    }

    Navigator.of(context).maybePop();

    setState(() {
      _exportingKind = kind;
    });

    try {
      final stamp = _exportStamp();
      final tempDir = await getTemporaryDirectory();

      late final String fileName;
      late final String mimeType;
      late final File file;

      if (kind == 'ics') {
        final content = ScheduleExport.buildIcs(widget.schedule);

        fileName = 'LifeZen_Schedule_$stamp.ics';

        mimeType = 'text/calendar';

        file = File('${tempDir.path}/$fileName');

        await file.writeAsString(content);
      } else if (kind == 'csv') {
        final content = ScheduleExport.buildCsv(widget.schedule);

        fileName = 'LifeZen_Schedule_$stamp.csv';

        mimeType = 'text/csv';

        file = File('${tempDir.path}/$fileName');

        await file.writeAsString(content);
      } else {
        final bytes = await _captureGridPng();

        if (bytes == null) {
          throw StateError(
            'Could not capture the schedule image. '
            'Please try again.',
          );
        }

        fileName = 'LifeZen_Schedule_$stamp.png';

        mimeType = 'image/png';

        file = File('${tempDir.path}/$fileName');

        await file.writeAsBytes(bytes);
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mimeType, name: fileName)],
          text: 'My LifeZen schedule',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported $fileName.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _exportingKind = null;
        });
      } else {
        _exportingKind = null;
      }
    }
  }

  Future<void> _saveToDevice(String kind) async {
    if (widget.schedule.isEmpty || _exportingKind != null) {
      return;
    }

    setState(() {
      _exportingKind = kind;
    });

    try {
      final stamp = _exportStamp();

      if (kind == 'png') {
        final bytes = await _captureGridPng();

        if (bytes == null) {
          throw StateError(
            'Could not capture the schedule image. '
            'Please try again.',
          );
        }

        await Gal.putImageBytes(
          bytes,
          album: 'LifeZen',
          name: 'LifeZen_Schedule_$stamp',
        );

        if (!mounted) return;

        Navigator.of(context).maybePop();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery (LifeZen album).')),
        );

        return;
      }

      final fileName = kind == 'ics'
          ? 'LifeZen_Schedule_$stamp.ics'
          : 'LifeZen_Schedule_$stamp.csv';

      final content = kind == 'ics'
          ? ScheduleExport.buildIcs(widget.schedule)
          : ScheduleExport.buildCsv(widget.schedule);

      final Directory targetDir = await _deviceSaveDir();

      final file = File('${targetDir.path}/$fileName');

      await file.writeAsString(content);

      if (!mounted) return;

      Navigator.of(context).maybePop();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}.')));
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).maybePop();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _exportingKind = null;
        });
      } else {
        _exportingKind = null;
      }
    }
  }

  Future<Directory> _deviceSaveDir() async {
    final downloads = await getDownloadsDirectory();

    if (downloads != null) {
      return downloads;
    }

    return getApplicationDocumentsDirectory();
  }

  // ===========================================================================
  // PNG CAPTURE
  // ===========================================================================

  Future<Uint8List?> _captureGridPng() async {
    // Render a dedicated offscreen export widget.
    // PNG export intentionally hides the date and keeps only
    // the weekday name in the header.

    final isZoom = _viewMode == ScheduleViewMode.zoom;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    const double timeColumnWidth = 58.0;

    final double dayWidth = isZoom ? 130.0 : _compactDayWidth();

    final bool compactCards = !isZoom;

    final dimensions = _getTimetableDimensions(
      isLandscape: isLandscape,
      dayWidth: dayWidth,
      timeColumnWidth: timeColumnWidth,
    );

    final firstHour = dimensions['firstHour'] as int;

    final lastHour = dimensions['lastHour'] as int;

    final hourHeight = dimensions['hourHeight'] as double;

    final headerHeight = dimensions['headerHeight'] as double;

    final gridHeight = dimensions['gridHeight'] as double;

    final totalWidth = timeColumnWidth + (dayWidth * 7);

    final totalHeight = headerHeight + gridHeight;

    final weekStart = _weekStart();
    final orderedDays = _orderedDays();

    final surface = Theme.of(context).colorScheme.surface;

    final captureKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -totalWidth - 100,
        top: 0,
        child: IgnorePointer(
          child: Material(
            color: surface,
            child: RepaintBoundary(
              key: captureKey,
              child: Container(
                color: surface,
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Column(
                    children: [
                      _buildDayHeader(
                        weekStart: weekStart,
                        orderedDays: orderedDays,
                        dayWidth: dayWidth,
                        timeColumnWidth: timeColumnWidth,
                        headerHeight: headerHeight,
                        isLandscape: isLandscape,
                        compact: compactCards,
                        showDate: false,
                      ),
                      _buildGrid(
                        orderedDays: orderedDays,
                        dayWidth: dayWidth,
                        timeColumnWidth: timeColumnWidth,
                        firstHour: firstHour,
                        lastHour: lastHour,
                        hourHeight: hourHeight,
                        gridHeight: gridHeight,
                        compactCards: compactCards,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);

    overlay.insert(entry);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return null;

      final renderObject = captureKey.currentContext?.findRenderObject();

      if (renderObject is RenderRepaintBoundary) {
        final image = await renderObject.toImage(pixelRatio: 3.0);

        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          return null;
        }

        return byteData.buffer.asUint8List();
      }

      return null;
    } finally {
      entry.remove();
    }
  }

  double _compactDayWidth() {
    final width = MediaQuery.of(context).size.width;

    return (width - 58.0 - 32.0) / 7;
  }

  // ===========================================================================
  // i-MA'LUUM IMPORT
  // ===========================================================================

  Future<void> _openImaluumImport() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImaluumImportPage(onImport: widget.onImportImaluum),
      ),
    );
  }

  // ===========================================================================
  // CLEAR ALL
  // ===========================================================================

  Future<void> _clearAll() async {
    if (widget.schedule.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all schedules?'),
          content: Text(
            'This will remove all '
            '${widget.schedule.length} schedules. '
            'This action cannot be undone.',
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
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await widget.onClearAll();
  }

  // ===========================================================================
  // ADD / EDIT SCHEDULE
  // ===========================================================================

  Future<void> showScheduleDialog({ScheduleItem? existing}) async {
    final result = await showDialog<ScheduleItem>(
      context: context,
      builder: (_) {
        return _ScheduleEditorDialog(existing: existing);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (existing == null) {
      await widget.onAddSchedule(result);
    } else {
      await widget.onUpdateSchedule(result);
    }
  }

  // ===========================================================================
  // FIRST DAY OF WEEK
  // ===========================================================================

  Future<void> showFirstDayDialog() async {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    int selected = widget.firstDayOfWeek;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('First day of week'),
              content: RadioGroup<int>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setDialogState(() {
                    selected = value;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (index) {
                    final day = index + 1;

                    return RadioListTile<int>(
                      value: day,
                      title: Text(days[index]),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await widget.onFirstDayChanged(result);
  }

  // ===========================================================================
  // VIEW MODE DIALOG
  // ===========================================================================

  Future<void> _showViewModeDialog() async {
    final result = await showDialog<ScheduleViewMode>(
      context: context,
      builder: (dialogContext) {
        ScheduleViewMode selected = _viewMode;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule view'),
              content: RadioGroup<ScheduleViewMode>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setDialogState(() {
                    selected = value;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    RadioListTile<ScheduleViewMode>(
                      value: ScheduleViewMode.fixed,
                      title: Text('Fixed'),
                      subtitle: Text('Compact timetable that fits the screen.'),
                    ),
                    RadioListTile<ScheduleViewMode>(
                      value: ScheduleViewMode.zoom,
                      title: Text('Zoom & drag'),
                      subtitle: Text('Detailed timetable with pinch zoom.'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _viewMode = result;

      if (result == ScheduleViewMode.zoom) {
        _scheduleInitialised = false;

        _scheduleTransformController.value = Matrix4.identity();
      }
    });
  }

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Schedule settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.view_week_outlined),
                title: const Text('View mode'),
                subtitle: Text(
                  _viewMode == ScheduleViewMode.fixed ? 'Fixed' : 'Zoom & drag',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.of(sheetContext).pop();

                  await _showViewModeDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week_outlined),
                title: const Text('First day of week'),
                subtitle: Text(_fullDayName(widget.firstDayOfWeek)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.of(sheetContext).pop();

                  await showFirstDayDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WEEK HELPERS
  // ===========================================================================

  DateTime _weekStart() {
    final today = DateTime.now();

    final difference = (today.weekday - widget.firstDayOfWeek + 7) % 7;

    return DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: difference));
  }

  List<int> _orderedDays() {
    return List.generate(
      7,
      (index) => ((widget.firstDayOfWeek - 1 + index) % 7) + 1,
    );
  }

  String _fullDayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[weekday - 1];
  }

  String _shortDayName(int weekday) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return names[weekday - 1];
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour $period';
  }

  // ===========================================================================
  // TIMETABLE DIMENSIONS
  // ===========================================================================

  Map<String, dynamic> _getTimetableDimensions({
    required bool isLandscape,
    required double dayWidth,
    required double timeColumnWidth,
  }) {
    int earliestMinutes = 8 * 60;

    int latestMinutes = 18 * 60;

    for (final item in widget.schedule) {
      final start = item.time.hour * 60 + item.time.minute;

      final end = item.endTime.hour * 60 + item.endTime.minute;

      if (start < earliestMinutes) {
        earliestMinutes = start;
      }

      if (end > latestMinutes) {
        latestMinutes = end;
      }
    }

    final firstHour = earliestMinutes ~/ 60;

    final lastHour = (latestMinutes + 59) ~/ 60;

    final hourHeight = isLandscape ? 64.0 : 76.0;

    final headerHeight = isLandscape ? 48.0 : 62.0;

    final gridHeight = (lastHour - firstHour) * hourHeight;

    final totalWidth = timeColumnWidth + (dayWidth * 7);

    final totalHeight = headerHeight + gridHeight;

    return {
      'firstHour': firstHour,
      'lastHour': lastHour,
      'hourHeight': hourHeight,
      'headerHeight': headerHeight,
      'gridHeight': gridHeight,
      'totalWidth': totalWidth,
      'totalHeight': totalHeight,
    };
  }

  // ===========================================================================
  // FIXED MODE
  // ===========================================================================

  Widget _buildFixedSchedule() {
    final weekStart = _weekStart();

    final orderedDays = _orderedDays();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    const double timeColumnWidth = 58.0;

    final dimensions = _getTimetableDimensions(
      isLandscape: isLandscape,
      dayWidth: 100,
      timeColumnWidth: timeColumnWidth,
    );

    final firstHour = dimensions['firstHour'] as int;

    final lastHour = dimensions['lastHour'] as int;

    final hourHeight = dimensions['hourHeight'] as double;

    final headerHeight = dimensions['headerHeight'] as double;

    final gridHeight = dimensions['gridHeight'] as double;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final dayWidth = (availableWidth - timeColumnWidth) / 7;

        final totalWidth = timeColumnWidth + (dayWidth * 7);

        final totalHeight = headerHeight + gridHeight;

        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RepaintBoundary(
              key: _gridCaptureKey,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Column(
                    children: [
                      _buildDayHeader(
                        weekStart: weekStart,
                        orderedDays: orderedDays,
                        dayWidth: dayWidth,
                        timeColumnWidth: timeColumnWidth,
                        headerHeight: headerHeight,
                        isLandscape: isLandscape,
                        compact: true,
                      ),
                      _buildGrid(
                        orderedDays: orderedDays,
                        dayWidth: dayWidth,
                        timeColumnWidth: timeColumnWidth,
                        firstHour: firstHour,
                        lastHour: lastHour,
                        hourHeight: hourHeight,
                        gridHeight: gridHeight,
                        compactCards: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ZOOM MODE
  // ===========================================================================

  Widget _buildZoomSchedule() {
    final weekStart = _weekStart();

    final orderedDays = _orderedDays();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    const double timeColumnWidth = 58.0;

    const double dayWidth = 130.0;

    final dimensions = _getTimetableDimensions(
      isLandscape: isLandscape,
      dayWidth: dayWidth,
      timeColumnWidth: timeColumnWidth,
    );

    final firstHour = dimensions['firstHour'] as int;

    final lastHour = dimensions['lastHour'] as int;

    final hourHeight = dimensions['hourHeight'] as double;

    final headerHeight = dimensions['headerHeight'] as double;

    final gridHeight = dimensions['gridHeight'] as double;

    final totalWidth = dimensions['totalWidth'] as double;

    final totalHeight = dimensions['totalHeight'] as double;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 16;

        final overviewScale = (availableWidth / totalWidth).clamp(0.35, 1.0);

        if (!_scheduleInitialised) {
          _scheduleInitialised = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            final scaledWidth = totalWidth * overviewScale;

            final extraWidth = constraints.maxWidth - scaledWidth;

            final initialX = extraWidth > 0 ? extraWidth / 2 : 0.0;

            _scheduleTransformController.value = Matrix4.identity()
              ..translateByDouble(initialX, 0.0, 0.0, 1.0)
              ..scaleByDouble(overviewScale, overviewScale, overviewScale, 1.0);
          });
        }

        return ClipRect(
          child: InteractiveViewer(
            transformationController: _scheduleTransformController,
            boundaryMargin: const EdgeInsets.symmetric(
              horizontal: 300,
              vertical: 200,
            ),
            minScale: 0.35,
            maxScale: 3.0,
            scaleEnabled: true,
            panEnabled: true,
            constrained: false,
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _zoomCaptureKey,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Column(
                    children: [
                      _buildDayHeader(
                        weekStart: weekStart,
                        orderedDays: orderedDays,
                        dayWidth: dayWidth,
                        timeColumnWidth: timeColumnWidth,
                        headerHeight: headerHeight,
                        isLandscape: isLandscape,
                      ),
                      _buildGrid(
                        orderedDays: orderedDays,
                        dayWidth: dayWidth,
                        timeColumnWidth: timeColumnWidth,
                        firstHour: firstHour,
                        lastHour: lastHour,
                        hourHeight: hourHeight,
                        gridHeight: gridHeight,
                        compactCards: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DAY HEADER
  // ===========================================================================

  Widget _buildDayHeader({
    required DateTime weekStart,
    required List<int> orderedDays,
    required double dayWidth,
    required double timeColumnWidth,
    required double headerHeight,
    required bool isLandscape,
    bool compact = false,
    bool showDate = true,
  }) {
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          SizedBox(width: timeColumnWidth),
          ...List.generate(orderedDays.length, (index) {
            final weekday = orderedDays[index];

            final date = weekStart.add(Duration(days: index));

            final isToday = DateUtils.isSameDay(date, DateTime.now());

            return SizedBox(
              width: dayWidth,
              child: Container(
                margin: const EdgeInsets.only(right: 1),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 2 : 8,
                  vertical: isLandscape ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _shortDayName(weekday),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact
                              ? 12
                              : isLandscape
                              ? 11
                              : 14,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    if (showDate) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${date.day}/${date.month}',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 9 : 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // GRID
  // ===========================================================================

  Widget _buildGrid({
    required List<int> orderedDays,
    required double dayWidth,
    required double timeColumnWidth,
    required int firstHour,
    required int lastHour,
    required double hourHeight,
    required double gridHeight,
    required bool compactCards,
  }) {
    return SizedBox(
      height: gridHeight,
      child: Stack(
        children: [
          // -------------------------------------------------------------------
          // FULL HOUR LINES
          // -------------------------------------------------------------------
          ...List.generate(lastHour - firstHour + 1, (index) {
            final hour = firstHour + index;

            return Positioned(
              top: index * hourHeight,
              left: 0,
              right: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: timeColumnWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatHour(hour),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          }),

          // -------------------------------------------------------------------
          // HALF HOUR LINES
          // -------------------------------------------------------------------
          ...List.generate(lastHour - firstHour, (index) {
            return Positioned(
              top: (index * hourHeight) + (hourHeight / 2),
              left: timeColumnWidth,
              right: 0,
              child: Container(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            );
          }),

          // -------------------------------------------------------------------
          // VERTICAL DAY SEPARATORS
          // -------------------------------------------------------------------
          Positioned(
            left: timeColumnWidth,
            top: 0,
            bottom: 0,
            child: Row(
              children: List.generate(orderedDays.length, (index) {
                return Container(
                  width: dayWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // -------------------------------------------------------------------
          // SCHEDULE CARDS
          // -------------------------------------------------------------------
          ...List.generate(orderedDays.length, (index) {
            final weekday = orderedDays[index];

            final items = widget.schedule
                .where((item) => item.repeatDays.contains(weekday))
                .toList();

            return Stack(
              children: items.map((item) {
                final startMinutes = item.time.hour * 60 + item.time.minute;

                final endMinutes = item.endTime.hour * 60 + item.endTime.minute;

                final top = ((startMinutes - firstHour * 60) / 60) * hourHeight;

                final height = ((endMinutes - startMinutes) / 60) * hourHeight;

                final cardHeight = height > 8 ? height - 4 : 8.0;

                return Positioned(
                  left: timeColumnWidth + (index * dayWidth) + 4,
                  top: top + 2,
                  width: dayWidth - 8,
                  height: cardHeight,
                  child: _gridScheduleCard(
                    item,
                    cardHeight,
                    compact: compactCards,
                  ),
                );
              }).toList(),
            );
          }),

          // -------------------------------------------------------------------
          // NOW BAR
          // -------------------------------------------------------------------
          _buildNowIndicator(
            orderedDays: orderedDays,
            dayWidth: dayWidth,
            timeColumnWidth: timeColumnWidth,
            firstHour: firstHour,
            lastHour: lastHour,
            hourHeight: hourHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildNowIndicator({
    required List<int> orderedDays,
    required double dayWidth,
    required double timeColumnWidth,
    required int firstHour,
    required int lastHour,
    required double hourHeight,
  }) {
    final todayIndex = orderedDays.indexOf(_now.weekday);

    if (todayIndex == -1) {
      return const SizedBox.shrink();
    }

    final nowMinutes = _now.hour * 60 + _now.minute + _now.second / 60.0;

    final firstMinutes = firstHour * 60.0;

    final lastMinutes = lastHour * 60.0;

    if (nowMinutes < firstMinutes || nowMinutes > lastMinutes) {
      return const SizedBox.shrink();
    }

    final top = ((nowMinutes - firstMinutes) / 60.0) * hourHeight;

    final left = timeColumnWidth + (todayIndex * dayWidth);

    const lineColor = Colors.red;

    return Stack(
      children: [
        Positioned(
          left: timeColumnWidth,
          right: 0,
          top: top - 0.5,
          child: Container(height: 1, color: lineColor.withValues(alpha: 0.25)),
        ),
        Positioned(
          left: left + 2,
          top: top - 1,
          width: dayWidth - 4,
          height: 2,
          child: Container(
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: lineColor.withValues(alpha: 0.45),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: left - 2,
          top: top - 5,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: lineColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: lineColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SCHEDULE CARD
  // ===========================================================================

  Widget _gridScheduleCard(
    ScheduleItem item,
    double height, {
    required bool compact,
  }) {
    final courseCode = item.courseCode?.trim();

    final courseName = item.courseName?.trim();

    final subject = (courseName != null && courseName.isNotEmpty)
        ? courseName
        : item.title.trim();

    final compactTitle = (courseCode != null && courseCode.isNotEmpty)
        ? courseCode
        : subject;

    final lecturer = item.lecturer?.trim();

    final venue = item.venue?.trim().isNotEmpty == true
        ? item.venue!.trim()
        : 'No venue yet';

    final startMinutes = item.time.hour * 60 + item.time.minute;

    final endMinutes = item.endTime.hour * 60 + item.endTime.minute;

    String formatTime(int minutes) {
      final hour = minutes ~/ 60;

      final minute = minutes % 60;

      final period = hour >= 12 ? 'PM' : 'AM';

      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return minute == 0
          ? '$displayHour $period'
          : '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    final startTime = formatTime(startMinutes);

    final endTime = formatTime(endMinutes);

    final timeText = '$startTime - $endTime';

    final colorScheme = Theme.of(context).colorScheme;

    final subjectColor = colorForSubject(
      subjectKeyForScheduleItem(item),
      Theme.of(context).brightness,
    );

    Widget compactContent() {
      TextStyle compactCodeStyle(double size) {
        return TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size,
          height: 1.0,
          color: subjectColor.foreground,
        );
      }

      Widget codeLine(String line) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            line,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: compactCodeStyle(12),
          ),
        );
      }

      final rawCode = (item.courseCode?.trim().isNotEmpty == true)
          ? item.courseCode!.trim()
          : null;

      if (rawCode == null || rawCode.isEmpty) {
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              compactTitle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: compactCodeStyle(11),
            ),
          ),
        );
      }

      final tokens = rawCode
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();

      String line1;
      String line2;

      if (tokens.length >= 2) {
        line1 = tokens[0];
        line2 = tokens[1];
      } else {
        final glued = RegExp(r'^([A-Za-z]+)(\d+.*)$').firstMatch(tokens[0]);

        if (glued != null) {
          line1 = glued.group(1)!;
          line2 = glued.group(2)!;
        } else {
          return Center(child: codeLine(tokens[0]));
        }
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [codeLine(line1), codeLine(line2)],
        ),
      );
    }

    Widget infoRow({required IconData icon, required String text}) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: subjectColor.foreground),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  color: subjectColor.foreground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget detailedContent() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;

          return SingleChildScrollView(
            physics: availableHeight < 100
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subject,
                  maxLines: availableHeight >= 140 ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    height: 1.15,
                    color: subjectColor.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    color: subjectColor.foreground.withValues(alpha: 0.75),
                  ),
                ),
                if (lecturer != null && lecturer.isNotEmpty)
                  infoRow(icon: Icons.person_outline, text: lecturer),
                infoRow(icon: Icons.location_on_outlined, text: venue),
              ],
            ),
          );
        },
      );
    }

    return Dismissible(
      key: ValueKey('${item.id}_${item.importKey ?? ''}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete schedule?'),
              content: Text('Delete "$subject" from your schedule?'),
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
      },
      onDismissed: (_) async {
        await widget.onDeleteSchedule(item.id);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 14),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showScheduleDialog(existing: item);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: subjectColor.background,
              border: Border.all(color: subjectColor.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // EVENT CONTENT
                // -------------------------------------------------------------
                Expanded(
                  child: Padding(
                    padding: compact
                        ? const EdgeInsets.symmetric(horizontal: 5, vertical: 4)
                        : const EdgeInsets.all(7),
                    child: compact ? compactContent() : detailedContent(),
                  ),
                ),

                // -------------------------------------------------------------
                // RIGHT-SIDE COLOR BAR
                // -------------------------------------------------------------
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: subjectColor.accent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final firstDayName = _fullDayName(widget.firstDayOfWeek);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Column(
        children: [
          // -------------------------------------------------------------------
          // HEADER
          // -------------------------------------------------------------------
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              isLandscape ? 4 : 20,
              20,
              isLandscape ? 4 : 10,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: isLandscape ? 22 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      onPressed: widget.schedule.isEmpty
                          ? null
                          : _showExportSheet,
                      icon: const Icon(Icons.ios_share_outlined),
                      tooltip: 'Export schedule',
                    ),
                    IconButton(
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Schedule settings',
                    ),
                    IconButton(
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      onPressed: () {
                        showScheduleDialog();
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'Add schedule',
                    ),
                  ],
                ),
                SizedBox(height: isLandscape ? 2 : 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openImaluumImport,
                        icon: const Icon(Icons.school_outlined, size: 18),
                        label: const Text("i-Ma'luum"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.schedule.isEmpty ? null : _clearAll,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // WEEK START
          // -------------------------------------------------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isLandscape ? 2 : 0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Week starts $firstDayName',
                  style: TextStyle(
                    fontSize: isLandscape ? 11 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // VIEW MODE HINT
          // -------------------------------------------------------------------
          if (widget.schedule.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, isLandscape ? 2 : 8, 20, 0),
              child: Row(
                children: [
                  Icon(
                    _viewMode == ScheduleViewMode.fixed
                        ? Icons.view_week_outlined
                        : Icons.pinch_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _viewMode == ScheduleViewMode.fixed
                          ? 'Fixed view • Compact course code and time'
                          : 'Zoom view • Pinch to zoom and drag',
                      style: TextStyle(
                        fontSize: isLandscape ? 10 : 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: isLandscape ? 4 : 12),

          // -------------------------------------------------------------------
          // CONTENT
          // -------------------------------------------------------------------
          Expanded(
            child: widget.schedule.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_view_week_outlined,
                            size: isLandscape ? 40 : 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text('No schedules yet.'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              showScheduleDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add schedule'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _viewMode == ScheduleViewMode.fixed
                ? _buildFixedSchedule()
                : _buildZoomSchedule(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCHEDULE EDITOR
// =============================================================================

class _ScheduleEditorDialog extends StatefulWidget {
  final ScheduleItem? existing;

  const _ScheduleEditorDialog({this.existing});

  @override
  State<_ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<_ScheduleEditorDialog> {
  // ===========================================================================
  // BASIC
  // ===========================================================================

  late final TextEditingController titleController;

  // ===========================================================================
  // CLASS DETAILS
  // ===========================================================================

  late final TextEditingController courseCodeController;

  late final TextEditingController courseNameController;

  late final TextEditingController lecturerController;

  late final TextEditingController venueController;

  late final TextEditingController sectionController;

  late final TextEditingController semesterController;

  // ===========================================================================
  // TIME / DAYS
  // ===========================================================================

  late TimeOfDay selectedTime;
  late TimeOfDay selectedEndTime;
  late List<int> selectedDays;

  // ===========================================================================
  // UI STATE
  // ===========================================================================

  bool showDetails = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    titleController = TextEditingController(text: existing?.title ?? '');

    courseCodeController = TextEditingController(
      text: existing?.courseCode ?? '',
    );

    courseNameController = TextEditingController(
      text: existing?.courseName ?? '',
    );

    lecturerController = TextEditingController(text: existing?.lecturer ?? '');

    venueController = TextEditingController(text: existing?.venue ?? '');

    sectionController = TextEditingController(text: existing?.section ?? '');

    semesterController = TextEditingController(text: existing?.semester ?? '');

    selectedTime = existing?.time ?? const TimeOfDay(hour: 9, minute: 0);

    selectedEndTime =
        existing?.endTime ??
        TimeOfDay(
          hour: selectedTime.hour < 23 ? selectedTime.hour + 1 : 23,
          minute: selectedTime.minute,
        );

    selectedDays = List<int>.from(existing?.repeatDays ?? [1, 2, 3, 4, 5]);

    showDetails =
        existing?.courseCode?.trim().isNotEmpty == true ||
        existing?.courseName?.trim().isNotEmpty == true ||
        existing?.lecturer?.trim().isNotEmpty == true ||
        existing?.venue?.trim().isNotEmpty == true ||
        existing?.section?.trim().isNotEmpty == true ||
        existing?.semester?.trim().isNotEmpty == true;
  }

  @override
  void dispose() {
    titleController.dispose();

    courseCodeController.dispose();

    courseNameController.dispose();

    lecturerController.dispose();

    venueController.dispose();

    sectionController.dispose();

    semesterController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // START TIME
  // ===========================================================================

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedTime = picked;

      final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

      final endMinutes = selectedEndTime.hour * 60 + selectedEndTime.minute;

      if (endMinutes <= startMinutes) {
        final newHour = selectedTime.hour < 23 ? selectedTime.hour + 1 : 23;

        selectedEndTime = TimeOfDay(hour: newHour, minute: selectedTime.minute);
      }
    });
  }

  // ===========================================================================
  // END TIME
  // ===========================================================================

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

    final endMinutes = picked.hour * 60 + picked.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );

      return;
    }

    setState(() {
      selectedEndTime = picked;
    });
  }

  // ===========================================================================
  // DAY SELECTION
  // ===========================================================================

  void _toggleDay(int day, bool selected) {
    setState(() {
      if (selected) {
        if (!selectedDays.contains(day)) {
          selectedDays.add(day);
        }
      } else {
        selectedDays.remove(day);
      }

      selectedDays.sort();
    });
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  void _save() {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name.')),
      );

      return;
    }

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );

      return;
    }

    final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

    final endMinutes = selectedEndTime.hour * 60 + selectedEndTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );

      return;
    }

    final existing = widget.existing;

    final courseCode = courseCodeController.text.trim();

    final courseName = courseNameController.text.trim();

    final lecturer = lecturerController.text.trim();

    final venue = venueController.text.trim();

    final section = sectionController.text.trim();

    final semester = semesterController.text.trim();

    final item = ScheduleItem(
      id: existing?.id ?? 0,
      title: title,
      time: selectedTime,
      endTime: selectedEndTime,
      repeatDays: List<int>.from(selectedDays),
      importKey: existing?.importKey,
      courseCode: courseCode.isEmpty ? null : courseCode,
      courseName: courseName.isEmpty ? null : courseName,
      venue: venue.isEmpty ? null : venue,
      lecturer: lecturer.isEmpty ? null : lecturer,
      section: section.isEmpty ? null : section,
      semester: semester.isEmpty ? null : semester,
    );

    Navigator.of(context).pop(item);
  }

  // ===========================================================================
  // FIELD
  // ===========================================================================

  Widget _detailTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Schedule' : 'Add Schedule'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -----------------------------------------------------------------
              // SCHEDULE NAME
              // -----------------------------------------------------------------
              TextField(
                controller: titleController,
                autofocus: !isEditing,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Schedule name',
                  hintText: 'e.g. Study or CSCI 584',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // -----------------------------------------------------------------
              // DETAILS TOGGLE
              // -----------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text(
                    'Class details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Lecturer, venue, course information and more',
                  ),
                  value: showDetails,
                  onChanged: (value) {
                    setState(() {
                      showDetails = value;
                    });
                  },
                ),
              ),

              // -----------------------------------------------------------------
              // CLASS DETAILS
              // -----------------------------------------------------------------
              if (showDetails) ...[
                const SizedBox(height: 12),

                _detailTextField(
                  controller: courseCodeController,
                  label: 'Course code',
                  hint: 'e.g. CSC584',
                  icon: Icons.menu_book_outlined,
                ),

                const SizedBox(height: 12),

                _detailTextField(
                  controller: courseNameController,
                  label: 'Course name',
                  hint: 'e.g. Network Security',
                  icon: Icons.book_outlined,
                ),

                const SizedBox(height: 12),

                _detailTextField(
                  controller: lecturerController,
                  label: 'Lecturer',
                  hint: 'e.g. Dr. Ahmad',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 12),

                _detailTextField(
                  controller: venueController,
                  label: 'Venue',
                  hint: 'e.g. KICT LT1',
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _detailTextField(
                        controller: sectionController,
                        label: 'Section',
                        hint: 'e.g. 1',
                        icon: Icons.groups_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _detailTextField(
                        controller: semesterController,
                        label: 'Semester',
                        hint: 'e.g. 1',
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // -----------------------------------------------------------------
              // START TIME
              // -----------------------------------------------------------------
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Start time'),
                subtitle: Text(formatTimeOfDay(selectedTime)),
                onTap: _pickStartTime,
              ),

              // -----------------------------------------------------------------
              // END TIME
              // -----------------------------------------------------------------
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timelapse_outlined),
                title: const Text('End time'),
                subtitle: Text(formatTimeOfDay(selectedEndTime)),
                onTap: _pickEndTime,
              ),

              const SizedBox(height: 8),

              // -----------------------------------------------------------------
              // REPEAT
              // -----------------------------------------------------------------
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Repeat',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: List.generate(7, (index) {
                  final day = index + 1;

                  final selected = selectedDays.contains(day);

                  return FilterChip(
                    label: Text(names[index]),
                    selected: selected,
                    onSelected: (value) {
                      _toggleDay(day, value);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // ACTIONS
      // -----------------------------------------------------------------------
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
