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
  List<ImaluumMeeting> _meetings = const [];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => mounted ? setState(() => _loading = true) : null,
        onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
      ))
      ..loadRequest(Uri.parse('https://imaluum.iium.edu.my/MyAcademic/schedule'));
  }

  Future<void> _extract() async {
    setState(() => _extracting = true);
    try {
      // Read the rendered timetable only. The web view retains its own session;
      // no cookie, password, or auth header is read by this app.
      const script = '''
        JSON.stringify(Array.from(document.querySelectorAll('table')).map(table => {
          const activeSpans = [];
          const logicalRows = Array.from(table.querySelectorAll('tr')).map(tr => {
            const output = []; let column = 0;
            const copySpans = () => { while (activeSpans[column]) { output[column] = activeSpans[column].text; if (--activeSpans[column].left === 0) activeSpans[column] = null; column++; } };
            Array.from(tr.cells).forEach(cell => { copySpans(); const text = cell.innerText.trim(); const width = cell.colSpan || 1; const height = cell.rowSpan || 1; for (let index = 0; index < width; index++) { output[column + index] = text; if (height > 1) activeSpans[column + index] = { text: text, left: height - 1 }; } column += width; });
            copySpans(); return { isHeader: tr.querySelectorAll('th').length > 0, values: output };
          });
          const header = logicalRows.find(row => row.isHeader);
          const semesterMatch = document.body.innerText.match(/semester\s*\d+\s*[,/-]?\s*\d{4}\s*\/\s*\d{4}/i);
          return { headers: header ? header.values : [], rows: logicalRows.filter(row => !row.isHeader && row.values.length).map(row => row.values), semester: semesterMatch ? semesterMatch[0] : '' };
        }).filter(table => table.headers.length > 0));
      ''';
      final response = await _controller.runJavaScriptReturningResult(script);
      final decoded = jsonDecode(response as String) as List<dynamic>;
      final tables = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final meetings = _parser.parseTables(tables);
      if (!mounted) return;
      setState(() => _meetings = meetings);
      if (meetings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No class meetings found. Open Class Timetable, then try again.'),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not read this timetable. Please open the Class Timetable page and try again.'),
      ));
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _import() async {
    final added = await widget.onImport(_meetings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added == 0 ? 'Your timetable is already up to date.' : 'Imported $added class ${added == 1 ? 'meeting' : 'meetings'}.'),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Import from i-Ma'luum"),
          actions: [IconButton(onPressed: _loading ? null : _extract, icon: const Icon(Icons.download_outlined), tooltip: 'Read timetable')],
          bottom: _loading ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator()) : null,
        ),
        floatingActionButton: _meetings.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: _import,
                icon: const Icon(Icons.add_task_outlined),
                label: Text('Import ${_meetings.length} meetings'),
              ),
        body: Column(children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(12),
            child: const Text('Sign in directly with IIUM and complete any CAPTCHA yourself. LifeZen does not read or store your password, cookies, or authentication tokens. Then open Class Timetable and tap the download button.'),
          ),
          if (_extracting) const LinearProgressIndicator(),
          Expanded(child: WebViewWidget(controller: _controller)),
        ]),
      );
}
