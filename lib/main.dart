import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/player_provider.dart';
import 'utils/theme.dart';
import 'screens/songs_screen.dart';
import 'screens/library_screen.dart';
import 'screens/playlists_screen.dart';
import 'widgets/common_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgSurface,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: const TealWaveApp(),
    ),
  );
}

class TealWaveApp extends StatelessWidget {
  const TealWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TealWave',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  bool _permissionGranted = false;
  bool _loading = true;

  final _screens = const [
    SongsScreen(),
    LibraryScreen(),
    PlaylistsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status;
    // Request storage permission for Android 8 (J7 Duo)
    if (await Permission.storage.isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.storage.request();
    }
    if (status.isDenied) {
      status = await Permission.audio.request();
    }
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      await context.read<PlayerProvider>().loadSongs();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.tealPrimary),
              SizedBox(height: 16),
              Text('Loading TealWave...',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (!_permissionGranted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_off_rounded,
                    color: AppTheme.tealPrimary, size: 72),
                const SizedBox(height: 16),
                const Text('Storage Permission Required',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                    'TealWave needs access to your storage to find and play music.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    openAppSettings();
                    setState(() => _loading = true);
                    Future.delayed(
                        const Duration(seconds: 2), _requestPermissions);
                  },
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealPrimary,
                    foregroundColor: AppTheme.bgPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: _screens,
            ),
          ),
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (i) => setState(() => _currentTab = i),
            backgroundColor: AppTheme.bgSurface,
            indicatorColor: AppTheme.tealAlpha,
            surfaceTintColor: Colors.transparent,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.music_note_rounded),
                selectedIcon: Icon(Icons.music_note_rounded,
                    color: AppTheme.tealPrimary),
                label: 'Songs',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_rounded),
                selectedIcon: Icon(Icons.library_music_rounded,
                    color: AppTheme.tealPrimary),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_rounded),
                selectedIcon: Icon(Icons.queue_music_rounded,
                    color: AppTheme.tealPrimary),
                label: 'Playlists',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
