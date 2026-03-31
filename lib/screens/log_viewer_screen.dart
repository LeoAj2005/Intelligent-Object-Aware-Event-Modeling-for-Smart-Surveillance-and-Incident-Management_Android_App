import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/incident.dart';
import '../settings_provider.dart';

class LogViewerScreen extends StatefulWidget {
  final SettingsProvider settings;

  const LogViewerScreen({Key? key, required this.settings}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<Incident> _logs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    if (widget.settings.serverUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Server URL not set. Please configure in settings.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Ensure the URL ends without a slash before appending /logs
      final baseUrl = widget.settings.serverUrl.replaceAll(RegExp(r'/$'), '');
      final response = await http.get(Uri.parse('$baseUrl/logs'));

      if (response.statusCode == 200) {
        setState(() {
          _logs = Incident.parseJsonl(response.body);
          // Sort newest first
          _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _isLoading = false;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load logs: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() { _isLoading = true; _errorMessage = ''; });
            _fetchLogs();
          }),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }
    if (_logs.isEmpty) return const Center(child: Text('No incidents recorded.'));

    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              log.event.contains('Zone') ? Icons.warning : Icons.directions_run,
              color: log.confidence > 0.7 ? Colors.red : Colors.orange,
            ),
            title: Text(log.event, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Cam: ${log.cameraId ?? 'Unknown'} | Conf: ${(log.confidence * 100).toStringAsFixed(1)}%'),
            trailing: Text(
              DateFormat('MMM dd, HH:mm').format(log.timestamp),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}