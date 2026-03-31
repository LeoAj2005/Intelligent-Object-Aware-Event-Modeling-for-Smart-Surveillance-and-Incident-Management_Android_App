import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../settings_provider.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsProvider settings;

  const SettingsScreen({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 🌐 SERVER URL CONFIGURATION
          ListTile(
            title: const Text('Server Connection URL'),
            subtitle: Text(
              settings.serverUrl.isEmpty
                  ? 'Tap to set URL'
                  : settings.serverUrl,
            ),
            leading: const Icon(Icons.link),
            onTap: () => _showUrlDialog(context),
          ),

          // 📋 VIEW LOGS
          ListTile(
            title: const Text('View System Logs'),
            leading: const Icon(Icons.list_alt),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LogViewerScreen(settings: settings),
                ),
              );
            },
          ),

          const Divider(),

          // 🌙 THEME
          SwitchListTile(
            title: const Text('Dark Theme'),
            secondary: const Icon(Icons.dark_mode),
            value: settings.isDarkMode,
            onChanged: settings.updateTheme,
          ),

          const Divider(),

          // ⚙️ AUTOMATION & SERVER
          Text(
            'Automation & Server',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          ListTile(
            title: const Text('Server Feed Check Interval'),
            subtitle: Text(
              'Refresh every ${settings.checkIntervalSeconds.toInt()} seconds',
            ),
          ),

          Slider(
            value: settings.checkIntervalSeconds,
            min: 2,
            max: 30,
            divisions: 28,
            label: '${settings.checkIntervalSeconds.toInt()} sec',
            onChanged: settings.updateInterval,
          ),

          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts for new incidents'),
            secondary: const Icon(Icons.notifications_active),
            value: settings.notificationsEnabled,
            onChanged: settings.toggleNotifications,
          ),

          const Divider(),

          // 📦 STORAGE & MEDIA
          Text(
            'Storage & Media',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          SwitchListTile(
            title: const Text('Save Event Logs'),
            secondary: const Icon(Icons.receipt_long),
            value: settings.saveLog,
            onChanged: settings.toggleSaveLog,
          ),

          SwitchListTile(
            title: const Text('Auto-Save Media'),
            subtitle: const Text('Download clips automatically'),
            secondary: const Icon(Icons.download),
            value: settings.autoSaveMedia,
            onChanged: settings.toggleAutoSave,
          ),

          // 📁 STORAGE PICKER
          ListTile(
            title: const Text('Storage Location'),
            subtitle: Text(settings.storageLocation),
            leading: const Icon(Icons.folder),
            onTap: () async {
              String? result =
                  await FilePicker.platform.getDirectoryPath();

              if (result != null) {
                settings.updateStorageLocation(result);
              }
            },
          ),

          // 🔔 RINGTONE PICKER
          ListTile(
            title: const Text('Alarm Ringtone'),
            subtitle: Text(settings.alarmRingtone),
            leading: const Icon(Icons.audiotrack),
            onTap: () => _showRingtoneDialog(context),
          ),
        ],
      ),
    );
  }

  // 🌐 SERVER URL DIALOG
  void _showUrlDialog(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: settings.serverUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "https://xxxx.trycloudflare.com",
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();

              if (url.isNotEmpty && url.startsWith('http')) {
                settings.updateServerUrl(url);
              }

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // 🔔 RINGTONE DIALOG
  void _showRingtoneDialog(BuildContext context) {
    final options = [
      'Default Siren',
      'Chime',
      'Klaxon',
      'Silent'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Ringtone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (tone) => ListTile(
                  title: Text(tone),
                  trailing: settings.alarmRingtone == tone
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    settings.updateRingtone(tone);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}