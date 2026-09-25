import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientations for mobile-landscape-first experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable immersive edge-to-edge mode for mobile displays
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const TeamBApp());
}

class TeamBApp extends StatelessWidget {
  const TeamBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team B',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF0284C7),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LobbyScreen(),
    );
  }
}

/// Backward compatibility alias for tests
typedef MiniMilitiaApp = TeamBApp;
