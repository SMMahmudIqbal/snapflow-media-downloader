// ==========================================================
// SnapFlow Mobile Media Downloader
// Swiss Brutalism Theme Specification
// Developed by S. M. Mahmud Iqbal
// ==========================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/media_item.dart';
import 'screens/home_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/about_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFE4E2DD),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SnapFlowApp());
}

class SnapFlowApp extends StatelessWidget {
  const SnapFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapFlow - Developed by S. M. Mahmud Iqbal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE4E2DD),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFDB4A2B), // Accent Red
          secondary: Color(0xFFF8A348), // Warm Orange
          tertiary: Color(0xFFFF89A9), // Soft Pink
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFE4E2DD),
          onPrimary: Colors.white,
          onBackground: Color(0xFF1E1E1E),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFDB4A2B),
          selectionColor: Color(0xFFDB4A2B),
          selectionHandleColor: Color(0xFFDB4A2B),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final List<DownloadedTask> _downloads = [];

  void _addDownload(DownloadedTask task) {
    setState(() {
      _downloads.insert(0, task);
    });
  }

  void _clearDownloads() {
    setState(() {
      _downloads.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onDownloadComplete: _addDownload),
      DownloadsScreen(tasks: _downloads, onClear: _clearDownloads),
      const AboutScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE4E2DD),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE4E2DD),
          border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              backgroundColor: const Color(0xFFE4E2DD),
              indicatorColor: const Color(0xFFDB4A2B).withOpacity(0.18),
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.bolt_rounded, color: Color(0xFF1E1E1E)),
                  selectedIcon: Icon(Icons.bolt_rounded, color: Color(0xFFDB4A2B)),
                  label: 'EXTRACTOR',
                ),
                NavigationDestination(
                  icon: Icon(Icons.archive_outlined, color: Color(0xFF1E1E1E)),
                  selectedIcon: Icon(Icons.archive_rounded, color: Color(0xFFDB4A2B)),
                  label: 'LOG & CACHE',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline_rounded, color: Color(0xFF1E1E1E)),
                  selectedIcon: Icon(Icons.info_rounded, color: Color(0xFFDB4A2B)),
                  label: 'SPEC / ABOUT',
                ),
              ],
            ),
            // Persistent Brand Attribution Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFF1E1E1E),
              child: const Center(
                child: Text(
                  'DEVELOPED BY S. M. MAHMUD IQBAL',
                  style: TextStyle(
                    color: Color(0xFFE4E2DD),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
