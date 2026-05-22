import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services et Authentification
import 'services/auth_service.dart';
import 'auth/login_page.dart';
import 'app_colors.dart';

// Vos imports d'interfaces d'origine
import 'interfaces/tableau_de_bord/tableau_page.dart';
import 'interfaces/carte/carte_page.dart';
import 'interfaces/irrigation/irrigation_page.dart';
import 'interfaces/images/images_page.dart';
import 'interfaces/profil/profil_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const AgriSenseApp(),
    ),
  );
}

// ─── App Root ─────────────────────────────────────────────────────────────────
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
      // On pointe d'abord sur l'AuthWrapper pour vérifier l'état de connexion
      home: const AuthWrapper(),
      //home: const MainShell(),
    );
  }
}

// ─── AuthWrapper — Décide quel écran afficher au démarrage ────────────────────
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Charge le token sauvegardé au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Optionnel : Splash / chargement initial pendant la vérification du token
        if (auth.isLoading && auth.user == null) {
          return const _SplashScreen();
        }
        
        // Si l'utilisateur n'est pas connecté → direction l'écran de Login
        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }
        
        // Si l'utilisateur est connecté → direction l'application principale
        return const MainShell();
      },
    );
  }
}

// ─── Splash Screen Éphémère ───────────────────────────────────────────────────
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
            const Text(
              'AgriSense',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

// ─── Shell principal avec votre navigation d'origine ─────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Utilisation de vos écrans et imports d'origine
  final List<Widget> _screens = const [
    DashboardScreen(),
    CarteScreen(),
    IrrigationScreen(),
    ImagesScreen(),
    ProfilScreen(),
  ];

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
              icon: Icon(Icons.grid_view_rounded),
              label: 'Tableau',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Carte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              label: 'Irrigation',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_camera_outlined),
              label: 'Images',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}