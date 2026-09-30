import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/imaluum/imaluum_timetable.dart';

class ImaluumImportPage extends StatefulWidget {
  const ImaluumImportPage({
    super.key,
    required this.onImport,
  });

  final Future<int> Function(List<ImaluumMeeting> meetings) onImport;

  @override
  State<ImaluumImportPage> createState() => _ImaluumImportPageState();
}

class _ImaluumImportPageState extends State<ImaluumImportPage> {
  late final WebViewController _controller;

  final _parser = const ImaluumTimetableParser();

  bool _loading = true;
  bool _extracting = false;

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
              setState(() => _loading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://imaluum.iium.edu.my/'),
      );
  }

  Future<void> _extract() async {
    if (!await _isSchedulePage()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open Class Timetable or Confirmation Slip before reading it.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _extracting = true);
    }

    try {
      const script = r'''
(function () {
  const tables = Array.from(document.querySelectorAll('table'));
  const output = [];

  const semesterMatch = document.body.innerText.match(
    /Schedule\s+sem\s+\d+\s*,?\s*\d{4}\s*\/\s*\d{4}/i
  );

  const semester = semesterMatch
      ? semesterMatch[0].trim()
      : '';

  for (const table of tables) {
    const rows = Array.from(table.querySelectorAll('tr'));

    if (rows.length === 0) {
      continue;
    }

    let headerIndex = -1;

    for (let i = 0; i < rows.length; i++) {
      const cells = Array.from(
        rows[i].querySelectorAll('th, td')
      );

      const values = cells.map((cell) =>
        (cell.innerText || cell.textContent || '').trim()
      );

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

    const headerCells = Array.from(
      rows[headerIndex].querySelectorAll('th, td')
    );

    const headers = headerCells.map((cell) =>
      (cell.innerText || cell.textContent || '').trim()
    );

    const dataRows = [];

    for (let i = headerIndex + 1; i < rows.length; i++) {
      const cells = Array.from(
        rows[i].querySelectorAll('td, th')
      );

      if (cells.length === 0) {
        continue;
      }

      const values = cells.map((cell) =>
        (cell.innerText || cell.textContent || '').trim()
      );

      dataRows.push(values);
    }

    if (headers.length > 0 && dataRows.length > 0) {
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

      final response = await _controller.runJavaScriptReturningResult(script);

      String jsonText = response.toString();

      // Android WebView may return a JSON-encoded string,
      // so decode it once more if necessary.
      if (jsonText.startsWith('"') && jsonText.endsWith('"')) {
        try {
          jsonText = jsonDecode(jsonText) as String;
        } catch (_) {
          // Keep the original value if it was not actually encoded.
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

      if (!mounted) return;

      setState(() {
        _meetings = meetings;
      });

      if (meetings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No class meetings found. Open Class Timetable, then try again.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read this timetable. Please open the Class Timetable page and try again.',
          ),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _extracting = false);
      }
    }
  }

  Future<bool> _isSchedulePage() async {
    final currentUrl = await _controller.currentUrl();

    final path =
        Uri.tryParse(currentUrl ?? '')?.path.toLowerCase() ?? '';

    return path.startsWith('/myacademic/schedule') ||
        path.startsWith('/confirmationslip');
  }

  Future<void> _import() async {
    if (_meetings.isEmpty) {
      return;
    }

    final added = await widget.onImport(_meetings);

    if (!mounted) return;

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
            tooltip: 'Read timetable',
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
              label: Text(
                'Import ${_meetings.length} meetings',
              ),
            ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Sign in directly with IIUM and complete any CAPTCHA yourself. '
              'Open Class Timetable or Confirmation Slip, then tap the '
              'download button. LifeZen does not read or store your password, '
              'cookies, or authentication tokens.',
            ),
          ),
          if (_extracting)
            const LinearProgressIndicator(),
          Expanded(
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}

