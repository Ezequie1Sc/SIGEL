import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/pages/Student/home_screen.dart';
import 'package:flutter_application_hola/src/pages/Student/inventory_screen.dart';
import 'package:flutter_application_hola/src/pages/Student/listtask_Screen.dart';
import 'package:flutter_application_hola/src/pages/schedule_screen.dart';
import 'package:flutter_application_hola/src/pages/setting_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class MainStudentScreen extends StatefulWidget {
  final int userId;
  final String userRole;

  const MainStudentScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<MainStudentScreen> createState() => _MainStudentScreenState();
}

class _MainStudentScreenState extends State<MainStudentScreen> {
  int _currentIndex = 2;
  bool _isLocaleInitialized = false;
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0;
  
  // ValueNotifier para controlar la visibilidad de la barra de navegación
  final ValueNotifier<bool> _navBarVisibilityNotifier = ValueNotifier<bool>(true);

  late final List<Widget> _screens;

  final List<NavItem> _navItems = [
     NavItem(index: 2, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    NavItem(index: 0, icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Agenda'),
    NavItem(index: 1, icon: Icons.science_outlined, activeIcon: Icons.science, label: 'Reactivos'),
    NavItem(index: 3, icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Tareas'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocaleData();
    _setupNavBarListener();

    _screens = [
      ScheduleScreen(
        userId: widget.userId,
        userRole: widget.userRole,
      ),
      InventoryScreen(
        userId: widget.userId,
        userRole: widget.userRole,
        
      ),
      HomeScreen(userId: widget.userId),
      ListTaskScreen(
        userId: widget.userId,
        userRole: widget.userRole,
        
      ),
      SettingScreen(
        userId: widget.userId,
      ),
    ];
  }

  @override
  void dispose() {
    _navBarVisibilityNotifier.dispose();
    super.dispose();
  }

  void _setupNavBarListener() {
    // Escuchar cambios en la visibilidad de la barra de navegación
    _navBarVisibilityNotifier.addListener(() {
      if (_navBarVisibilityNotifier.value != _isNavBarVisible) {
        setState(() {
          _isNavBarVisible = _navBarVisibilityNotifier.value;
        });
      }
    });
  }

  Future<void> _initializeLocaleData() async {
    await initializeDateFormatting('es', null);
    if (mounted) {
      setState(() {
        _isLocaleInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.indigo,
          ),
        ),
      );
    }

    return Material(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            // Pantalla principal con NotificationListener global
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  final currentOffset = scrollNotification.metrics.pixels;
                  
                  if (currentOffset > _lastScrollOffset + 15 && _isNavBarVisible) {
                    // Scroll hacia abajo - ocultar navbar
                    _navBarVisibilityNotifier.value = false;
                  } else if (currentOffset < _lastScrollOffset - 8 && !_isNavBarVisible && currentOffset > 0) {
                    // Scroll hacia arriba - mostrar navbar
                    _navBarVisibilityNotifier.value = true;
                  } else if (currentOffset <= 0 && !_isNavBarVisible) {
                    // Llegamos al top - mostrar navbar
                    _navBarVisibilityNotifier.value = true;
                  }
                  
                  _lastScrollOffset = currentOffset;
                }
                return false;
              },
              child: _screens[_currentIndex],
            ),
            
            // Barra de navegación flotante
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildAnimatedNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastEaseInToSlowEaseOut,
      transform: Matrix4.translationValues(
        0,
        _isNavBarVisible ? 0 : 100,
        0,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isNavBarVisible ? 1.0 : 0.0,
        child: _buildFloatingNavBar(),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.map((item) => _buildFloatingNavItem(item)).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(NavItem item) {
    final isSelected = _currentIndex == item.index;
    
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = item.index);
        // Asegurarse de que la barra sea visible al cambiar de pestaña
        _navBarVisibilityNotifier.value = true;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.indigo.withOpacity(0.15),
                    Colors.indigo.withOpacity(0.05),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Colors.indigo.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de selección animado - SOLO COLOR INDIGO
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: 3,
              width: isSelected ? 28 : 0,
              decoration: BoxDecoration(
                color: Colors.indigo, // Solo color indigo, sin gradiente
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Icono con animación de escala
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isSelected ? 1.15 : 1.0,
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? Colors.indigo : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            // Texto con animación de opacidad
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 1.0 : 0.8,
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.indigo : Colors.grey[700],
                  letterSpacing: isSelected ? 0.5 : 0.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}