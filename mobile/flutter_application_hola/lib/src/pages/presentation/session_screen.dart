import 'package:flutter/material.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 400;
          final bool isMediumScreen = constraints.maxWidth < 600;
          final double screenHeight = constraints.maxHeight;
          final double screenWidth = constraints.maxWidth;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/labo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Espacio superior
                  SizedBox(height: screenHeight * 0.03),

                  // Contenido principal centrado
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  // Panel inferior con botones (contenedor blanco)
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: screenHeight * 0.35,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          spreadRadius: 3,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 28 : 36,
                      vertical: 36,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "BIENVENIDO",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo[900],
                            fontFamily: 'Montserrat',
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Selecciona una opción para continuar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontFamily: 'Roboto',
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Botón de Iniciar Sesión
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 60 : 65,
                          child: ElevatedButton(
                            onPressed: () => _navigateTo(context, 'login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 4,
                              shadowColor: Colors.indigo.withOpacity(0.5),
                            ),
                            child: Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 17 : 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Botón de Crear Cuenta
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 60 : 65,
                          child: OutlinedButton(
                            onPressed: () => _navigateTo(context, 'register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo[700],
                              side: BorderSide(
                                color: Colors.indigo[700]!,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 1,
                              shadowColor: Colors.indigo.withOpacity(0.2),
                            ),
                            child: Text(
                              'CREAR CUENTA',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 17 : 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
}