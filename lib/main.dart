import 'package:flutter/material.dart';
import 'settings_provider.dart';
import 'services/security_service.dart'; // Background service
import 'screens/settings_screen.dart';
import 'screens/video_feed_screen.dart';
import 'screens/video_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for background tasks
  runApp(const FinalYearApp());
}

class FinalYearApp extends StatefulWidget {
  const FinalYearApp({super.key});

  @override
  State<FinalYearApp> createState() => _FinalYearAppState();
}

class _FinalYearAppState extends State<FinalYearApp> {
  final SettingsProvider _settings = SettingsProvider();
  late final SecurityService _securityService; // Background service

  @override
  void initState() {
    super.initState();
    // ✅ Use named parameter for SecurityService
    _securityService = SecurityService(settings: _settings);

    // Rebuild the UI when settings change (theme, server URL, etc.)
    _settings.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _securityService.stopMonitoring(); // Clean up when the app closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Year App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      themeMode: _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigation(settings: _settings),
    );
  }
}

// Bottom navigation with three tabs
class MainNavigation extends StatefulWidget {
  final SettingsProvider settings;

  // ✅ Modern super.key syntax
  const MainNavigation({super.key, required this.settings});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _hasShownWarning = false;

  @override
  Widget build(BuildContext context) {
    final screens = [
      VideoFeedScreen(settings: widget.settings),
      VideoUploadScreen(settings: widget.settings),
      SettingsScreen(settings: widget.settings),
    ];

    // Show a warning if the server URL is not configured
    if (widget.settings.isInitialized &&
        widget.settings.serverUrl.isEmpty &&
        !_hasShownWarning) {
      _hasShownWarning = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Switch to Settings tab if not already there
        if (_currentIndex != 2) {
          setState(() => _currentIndex = 2);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please configure your Server URL to begin.'),
          ),
        );
      });
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.videocam),
            label: 'Live Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            label: 'Analyze',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}