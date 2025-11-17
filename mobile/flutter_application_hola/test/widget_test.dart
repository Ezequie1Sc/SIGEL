// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_hola/main.dart';
import 'package:flutter_application_hola/src/pages/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreen se muestra correctamente', (WidgetTester tester) async {
    // Construye la aplicación y renderiza un frame
    await tester.pumpWidget(const MyApp());

    // Espera a que las operaciones asíncronas (como ApiService.initSession) terminen
    await tester.pumpAndSettle();

    // Verifica que la SplashScreen esté presente
    expect(find.byType(SplashScreen), findsOneWidget);

    // Opcional: Verifica widgets específicos en SplashScreen
    // Reemplaza 'Texto de Bienvenida' con el texto real de tu SplashScreen
    expect(find.text('Texto de Bienvenida'), findsOneWidget); // Ajusta según tu UI
    // Si tu SplashScreen tiene una imagen (por ejemplo, sigelLogo.png)
    expect(find.byType(Image), findsOneWidget);
  });
}