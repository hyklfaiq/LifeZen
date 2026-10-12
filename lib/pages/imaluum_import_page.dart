import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/imaluum/imaluum_timetable.dart';

class ImaluumImportPage extends StatefulWidget {
  const ImaluumImportPage({super.key, required this.onImport});

  final Future<int> Function(List<ImaluumMeeting> meetings) onImport;

  @override
  State<ImaluumImportPage> createState() => _ImaluumImportPageState();
}

class _ImaluumImportPageState extends State<ImaluumImportPage> {
  late final WebViewController _controller;

  final _parser = const ImaluumTimetableParser();

  bool _loading = true;
  bool _extracting = false;


  bool _schedulePageDetected = false;

  Timer? _autoTimer;


  int _pageSerial = 0;

  /// Re-entrancy guard: [_autoPoll] is async, so timer ticks and navigation
  /// callbacks could otherwise overlap and stack heavy DOM reads on top of
  /// each other, freezing the page inside the WebView.
  bool _polling = false;

  List<ImaluumMeeting> _meetings = const [];

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                // Fresh page: drop the previous read so the poller picks
                // up the new timetable instead of keeping a stale count.
                _meetings = const [];
                _pageSerial += 1;
              });
              // Restart polling for the newly loading page. Gentle 5s
              // cadence so the portal server is never hammered.
              _autoTimer ??= Timer.periodic(
                const Duration(seconds: 5),
                (_) => _autoPoll(),
              );
              _autoPoll();
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
              });
              // Try a read right away; the periodic poll below covers
              // client-side navigation and late-rendered tables.
              _autoPoll();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://imaluum.iium.edu.my/'));

    _autoTimer = Timer.periodic(
      // Gentle cadence: the poller backs off further once a reading
      // succeeds, and stops entirely (see _autoPoll).
      const Duration(seconds: 5),
      (_) => _autoPoll(),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  /// Lightweight poller: cheap schedule-path gate first (no DOM scan off the
  /// timetable, so SSO/CAPTCHA/dashboard pages cost nothing), at most one
  /// poll at a time, and the timer parks once a reading succeeds.
  Future<void> _autoPoll() async {
    if (!mounted || _loading || _extracting || _polling) return;
    if (_meetings.isNotEmpty) return;
    _polling = true;
    try {
      int signal;
      try {
        signal = await _timetableSignal();
      } catch (_) {
        return;
      }
      if (!mounted || _meetings.isNotEmpty) return;

      final onSchedule = signal > 0;
      if (onSchedule != _schedulePageDetected) {
        setState(() {
          _schedulePageDetected = onSchedule;
        });
      }
      if (signal != 2) return;

      final serial = _pageSerial;

      await _extract(automatic: true, skipScheduleCheck: true, serial: serial);
      if (!mounted || serial != _pageSerial) return;
    } finally {
      _polling = false;
    }
  }

  Future<int> _timetableSignal() async {
    const probe = r'''
(function () {
  const path = (window.location.pathname || '').toLowerCase();
  const onSchedulePath = path.indexOf('/myacademic/schedule') === 0;
  const tables = Array.from(document.querySelectorAll('table'));
  for (const table of tables) {
    const rows = Array.from(table.querySelectorAll('tr')).filter(
      (row) => row.closest('table') === table
    );
    for (const row of rows) {
      const cells = Array.from(row.children).filter(
        (child) => child.tagName === 'TD' || child.tagName === 'TH'
      );
      // textContent instead of innerText: innerText forces a layout
      // reflow of the timetable on every poll, which can freeze the page.
      const text = cells
        .map((cell) => cell.textContent || '')
        .join(' ')
        .toLowerCase();
      if (
        text.indexOf('code') !== -1 &&
        text.indexOf('day') !== -1 &&
        text.indexOf('time') !== -1
      ) {
        return 2;
      }
    }
  }
  if (onSchedulePath) return 1;
  return 0;
})()
''';
    final response = await _controller
        .runJavaScriptReturningResult(probe)
        .timeout(const Duration(seconds: 8));
    var text = response.toString().trim();
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1);
    }
    return int.tryParse(text) ?? 0;
  }

  Future<void> _extract(
      {bool automatic = false,
      bool skipScheduleCheck = false,
      int? serial}) async {
    if (_extracting) return;

    if (!skipScheduleCheck && !await _isSchedulePage()) {
      // Automatic reads stay silent off the schedule page (the user may
      // still be signing in); manual taps keep the guidance message.
      if (!automatic && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open Class Timetable before reading it.'),
          ),
        );
      }

      return;
    }

    if (mounted) {
      setState(() {
        _extracting = true;
      });
    }

    try {
      const script = r'''
(function () {
  const tables = Array.from(
    document.querySelectorAll('table')
  );

  const output = []

  // Find semester from the page.
  //
  // Example text on i-Ma'luum:
  // "Schedule Sem 1, 2026/2027"
  //
  // We only keep:
  // "Sem 1, 2026/2027"
  const bodyText = document.body.innerText || '';

  const semesterMatch = bodyText.match(
    /Schedule\s+sem\s+\d+\s*,?\s*\d{4}\s*\/\s*\d{4}/i
  );

  let semester = '';

  if (semesterMatch) {
    semester = semesterMatch[0]
      .replace(/^Schedule\s*/i, '')
      .trim();

    // Make the formatting consistent.
    semester = semester.replace(
      /^sem\s+/i,
      'Sem '
    );
  }

  for (const table of tables) {
    // Only rows that belong to this table itself: each nested table is
    // visited again on its own turn, so its rows must not leak into the
    // outer table. Without this filter an outer row merges its cell text
    // with every nested cell, collapsing two subjects into one row and
    // hiding the next subject entirely.
    const rows = Array.from(
      table.querySelectorAll('tr')
    ).filter((row) => row.closest('table') === table);

    // Direct cell children only, so a cell that holds a nested table
    // does not leak the nested cells into this row.
    const directCells = (row) =>
      Array.from(row.children).filter(
        (child) => child.tagName === 'TD' || child.tagName === 'TH'
      );

    const cellText = (cell) =>
      (cell.innerText || cell.textContent || '').trim();

    if (rows.length === 0) {
      continue;
    }

    let headerIndex = -1;

    for (let i = 0; i < rows.length; i++) {
      const values = directCells(rows[i]).map(cellText);

      const text = values.join(' ').toLowerCase();

      if (
        text.includes('code') &&
        text.includes('day') &&
        text.includes('time')
      ) {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex === -1) {
      continue;
    }

    const headers = directCells(rows[headerIndex]).map(cellText);

    // Expand rowspan/colspan so every data row carries the full column
    // count. A subject that shares a cell with the row above (course
    // block, shared venue) or whose empty cell was absorbed by a span
    // otherwise shifts every value left: its day/time land in the wrong
    // columns and fail to parse, and the same block hides the next
    // subject's cells as well.
    const dataRows = [];
    const active = [];

    for (
      let i = headerIndex + 1;
      i < rows.length;
      i++
    ) {
      const cells = directCells(rows[i]);

      if (cells.length === 0) {
        continue;
      }

      const values = [];
      let domIndex = 0;

      for (let col = 0; domIndex < cells.length; col++) {
        const carried = active[col];

        if (carried && carried.left > 0) {
          carried.left -= 1;
          values.push(carried.value);

          if (carried.left <= 0) {
            active[col] = undefined;
          }

          continue;
        }

        const cell = cells[domIndex++];

        const text = cellText(cell);

        const rowSpan = Math.max(
          1,
          parseInt(cell.getAttribute('rowspan') || '1', 10) || 1
        );

        const colSpan = Math.max(
          1,
          parseInt(cell.getAttribute('colspan') || '1', 10) || 1
        );

        for (let k = 0; k < colSpan; k++) {
          active[col + k] = rowSpan > 1
            ? { value: text, left: rowSpan - 1 }
            : undefined;
          values.push(text);
        }

        col += colSpan - 1;
      }

      // Carry spanned values from the row above into trailing columns.
      for (let col = values.length; col < active.length; col++) {
        const carried = active[col];

        if (carried && carried.left > 0) {
          carried.left -= 1;
          values.push(carried.value);

          if (carried.left <= 0) {
            active[col] = undefined;
          }
        } else {
          break;
        }
      }

      dataRows.push(values);
    }

    if (
      headers.length > 0 &&
      dataRows.length > 0
    ) {
      output.push({
        headers: headers,
        rows: dataRows,
        semester: semester
      });
    }
  }

  return JSON.stringify(output);
})()
''';

      final response = await _controller
          .runJavaScriptReturningResult(script)
          .timeout(const Duration(seconds: 15));

      String jsonText = response.toString();

      // Android WebView may return a JSON-encoded string,
      // so decode it once more if necessary.
      if (jsonText.startsWith('"') && jsonText.endsWith('"')) {
        try {
          jsonText = jsonDecode(jsonText) as String;
        } catch (_) {
          // Keep original value if it was not actually encoded.
        }
      }

      final decoded = jsonDecode(jsonText);

      if (decoded is! List) {
        throw const FormatException('Invalid timetable data');
      }

      final tables = decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      final meetings = _parser.parseTables(tables);

      if (!mounted || (serial != null && serial != _pageSerial)) {
        return;
      }

      setState(() {
        _meetings = meetings;
      });

      // First valid read: park the auto-poller so the portal is left alone.
      // Navigation restarts it; the AppBar button re-reads on demand.
      if (automatic && meetings.isNotEmpty) {
        _autoTimer?.cancel();
        _autoTimer = null;
      }

      if (meetings.isEmpty && !automatic) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No class meetings found. Open Class Timetable, then try again.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not read this timetable. Please open the Class Timetable page and try again.',
          ),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _extracting = false;
        });
      }
    }
  }

  /// Visible auto-read status
  Widget _buildAutoStatus() {
    final scheme = Theme.of(context).colorScheme;
    late final String text;
    late final bool busy;
    late final IconData icon;
    if (_extracting) {
      text = 'Reading timetable…';
      busy = true;
      icon = Icons.sync_outlined;
    } else if (_meetings.isNotEmpty) {
      text = 'Found ${_meetings.length} '
          'meeting${_meetings.length == 1 ? '' : 's'} — tap Import below.';
      busy = false;
      icon = Icons.check_circle_outlined;
    } else if (_schedulePageDetected) {
      text = 'Timetable page open — waiting for the table to load…';
      busy = true;
      icon = Icons.hourglass_bottom_outlined;
    } else {
      text = 'Open your Class Timetable in the page below.';
      busy = false;
      icon = Icons.info_outlined;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<bool> _isSchedulePage() async {
    final currentUrl = await _controller.currentUrl();

    final path = Uri.tryParse(currentUrl ?? '')?.path.toLowerCase() ?? '';

    return path.startsWith('/myacademic/schedule');
  }

  Future<void> _import() async {
    if (_meetings.isEmpty) {
      return;
    }

    final added = await widget.onImport(_meetings);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'Your timetable is already up to date.'
              : 'Imported $added class ${added == 1 ? 'meeting' : 'meetings'}.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import from i-Ma'luum"),
        actions: [
          IconButton(
            onPressed: (_loading || _extracting) ? null : _extract,
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Re-read timetable',
          ),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: _meetings.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _extracting ? null : _import,
              icon: const Icon(Icons.add_task_outlined),
              label: Text('Import ${_meetings.length} meetings'),
            ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Sign in directly with IIUM and complete any CAPTCHA yourself. '
              'Open Class Timetable and your meetings are read automatically. '
              'LifeZen does not read or store your password, cookies, '
              'or authentication tokens.',
            ),
          ),

          _buildAutoStatus(),

          if (_extracting) const LinearProgressIndicator(),

          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
