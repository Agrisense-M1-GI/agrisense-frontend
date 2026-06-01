import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/capteur_service.dart';
import 'services/seuil_service.dart';
import 'services/utilisateur_service.dart';
import 'services/champ_service.dart';
import 'auth/login_page.dart';
import 'app_colors.dart';
import 'config/api_config.dart';

import 'interfaces/tableau_de_bord/tableau_page.dart';
import 'interfaces/carte/carte_page.dart';
import 'interfaces/irrigation/irrigation_page.dart';
import 'interfaces/images/images_page.dart';
import 'interfaces/profil/profil_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  // Token disponible dès le démarrage
  final token = authService.token;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => CapteurService(
            baseUrl: ApiConfig.baseUrl,
            token: token,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SeuilService(
            baseUrl: ApiConfig.baseUrl,
            token: token,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UtilisateurService(
            baseUrl: ApiConfig.baseUrl,
            token: token,
          ),
        ),
        Provider(
          create: (context) => ChampService(
            baseUrl: ApiConfig.baseUrl,
            authService: authService,
          ),
        ),
      ],
      child: const AgriSenseApp(),
    ),
  );
}

class AgriSenseApp extends StatelessWidget {
  const AgriSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green600,
          primary: AppColors.green600,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.green700,
          unselectedItemColor: Color(0xFF9AAA9A),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// ─── AuthWrapper ──────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) return const _SplashScreen();
        if (!auth.isLoggedIn) return const LoginScreen();
        return const MainShell();
      },
    );
  }
}

// ─── Splash ───────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.grass_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'AgriSense',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

// ─── MainShell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CarteScreen(),
    IrrigationScreen(),
    ImagesScreen(),
    ProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Après le build → pas d'erreur setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.token != null) {
        context.read<CapteurService>().setToken(auth.token!);
        context.read<SeuilService>().setToken(auth.token!);
        context.read<UtilisateurService>().setToken(auth.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded), label: 'Tableau'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined), label: 'Carte'),
            BottomNavigationBarItem(
                icon: Icon(Icons.water_drop_outlined), label: 'Irrigation'),
            BottomNavigationBarItem(
                icon: Icon(Icons.photo_camera_outlined), label: 'Images'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}