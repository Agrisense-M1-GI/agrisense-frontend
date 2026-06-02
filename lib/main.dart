import 'package:agrisense/interfaces/carte/configurer_champ_page.dart';
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
  await authService.init(); // charge token + vérifie backend

  final token = authService.token; // token valide ou null

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProxyProvider<AuthService, CapteurService>(
          create: (_) => CapteurService(baseUrl: ApiConfig.baseUrl, token: token),
          update: (_, auth, capteur) {
            if (auth.token != null) capteur!.setToken(auth.token!);
            return capteur!;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, SeuilService>(
          create: (_) => SeuilService(baseUrl: ApiConfig.baseUrl, token: token),
          update: (_, auth, seuil) {
            if (auth.token != null) seuil!.setToken(auth.token!);
            return seuil!;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, UtilisateurService>(
          create: (_) => UtilisateurService(baseUrl: ApiConfig.baseUrl, token: token),
          update: (_, auth, user) {
            if (auth.token != null) user!.setToken(auth.token!);
            return user!;
          },
        ),
        ProxyProvider<AuthService, ChampService>(
          create: (_) => ChampService(baseUrl: ApiConfig.baseUrl, authService: authService),
          update: (_, auth, champ) => champ!,
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
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
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
        return KeyedSubtree(
          key: ValueKey(auth.user!.id),
          child: const MainShell(),
        );
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
              child: const Icon(Icons.grass_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('AgriSense',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _verifierPremiereLancement();
    });
  }

  Future<void> _verifierPremiereLancement() async {
    try {
      final champService = context.read<ChampService>();
      final champs = await champService.getChamps();
      if (champs.isEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfigurerChampScreen()),
        );
      }
    } catch (_) {
      // Pas de réseau → on laisse passer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
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