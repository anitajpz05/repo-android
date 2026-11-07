// =============================================================================
// main.dart
// Punto de entrada de "El Pistón · Garage" (solución B, tema oscuro).
// 1. Abre la base de datos SQLite local (Drift) -> funciona sin internet.
// 2. Crea el repositorio con las reglas de negocio.
// 3. Lo pone en un TallerScope (InheritedWidget) por encima de toda la app,
//    para que cualquier pantalla lo obtenga con TallerScope.of(context).
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/base_datos.dart';
import 'data/repositorio_taller.dart';
import 'data/taller_scope.dart';
import 'ui/pantallas/principal.dart';
import 'ui/tema.dart';

void main() {
  // Necesario antes de usar plugins (la BD) fuera de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final repo = RepositorioTaller(db);
  runApp(TallerScope(repo: repo, child: const MiApp()));
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Pistón · Garage',
      debugShowCheckedModeBanner: false,
      theme: temaGarage(),
      // Español: textos de Material (calendario, botones, tooltips) en es.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const PantallaPrincipal(),
    );
  }
}
