import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/pages/Student/inventory_screen.dart';
import 'package:flutter_application_hola/src/pages/presentation/loggin_screen.dart';
import 'package:flutter_application_hola/src/pages/Student/mainstuden_Screen.dart';
import 'package:flutter_application_hola/src/pages/Teacher/mainteacher_screen.dart';
import 'package:flutter_application_hola/src/pages/Teacher/publications_Screen.dart';
import 'package:flutter_application_hola/src/pages/presentation/register_screen.dart';
import 'package:flutter_application_hola/src/pages/schedule_screen.dart';
import 'package:flutter_application_hola/src/pages/presentation/session_screen.dart';
import 'package:flutter_application_hola/src/pages/setting_screen.dart';
import 'package:flutter_application_hola/src/pages/presentation/splash_screen.dart';
import 'package:flutter_application_hola/src/pages/Teacher/taskteacher_Screen.dart';
import 'package:flutter_application_hola/src/pages/Teacher/teacheralum_screen.dart';
import 'package:flutter_application_hola/src/pages/Teacher/teacheriventory_screen.dart';
import 'package:flutter_application_hola/src/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "splash",
      routes: {
        "splash": (context) => const SplashScreen(),
        "session": (context) => const SessionScreen(),
        "login": (context) => const LoginScreen(),
        "register": (context) => const RegisterScreen(),
        "home": (context) => _buildHomeScreen(),
        "inventory": (context) => _buildInventoryScreen(),
        "teachertask": (context) => _buildTaskTeacherScreen(),
        "teacher_home": (context) => const MainTeacherScreen(),
        "publication": (context) => const PublicationsScreen(),
        "teacherinventory": (context) => _buildTeacherInventoryScreen(),
        "teacheralum": (context) => const TeacheralumScreen(),
        "schedule": (context) => _buildScheduleScreen(),
        "teacherinventory": (context) => _buildTeacherInventoryScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final userId = ApiService.currentUserId;
    final userToken = ApiService.currentUserToken;

    if (userId == null || userToken == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          ApiService.clearSession();
          return const LoginScreen();
        }

        final userRole = snapshot.data!;
        if (userRole == 'docente') {
          return const MainTeacherScreen();
        } else {
          return MainStudentScreen(
            userId: userId,
            userRole: userRole,
          );
        }
      },
    );
  }

  Widget _buildTaskTeacherScreen() {
    final userId = ApiService.currentUserId;
    final userToken = ApiService.currentUserToken;

    if (userId == null || userToken == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          ApiService.clearSession();
          return const LoginScreen();
        }

        final userRole = snapshot.data!;
        return ProfessionalTaskManagementScreen(
          userId: userId,
          userRole: userRole,
        );
      },
    );
  }

  Widget _buildScheduleScreen() {
    final userId = ApiService.currentUserId;
    final userToken = ApiService.currentUserToken;

    if (userId == null || userToken == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          ApiService.clearSession();
          return const LoginScreen();
        }

        final userRole = snapshot.data!;
        return ScheduleScreen(
          userId: userId,
          userRole: userRole,
        );
      },
    );
  }

  Widget _buildInventoryScreen() {
    final userId = ApiService.currentUserId;
    final userToken = ApiService.currentUserToken;

    if (userId == null || userToken == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          ApiService.clearSession();
          return const LoginScreen();
        }

        final userRole = snapshot.data!;
        return InventoryScreen(
          userId: userId,
          userRole: userRole,
        );
      },
    );
  }

  Widget _buildTeacherInventoryScreen() {
    final userId = ApiService.currentUserId;
    final userToken = ApiService.currentUserToken;

    if (userId == null || userToken == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          ApiService.clearSession();
          return const LoginScreen();
        }

        final userRole = snapshot.data!;
        return TeacherInventoryScreen(
          
        );
      },
    );
  }

  Future<String?> _getUserRole(int userId) async {
    try {
      final user = await ApiService.getUsuarioById(userId);
      return user?.rol;
    } catch (e) {
      return null;
    }
  }
}