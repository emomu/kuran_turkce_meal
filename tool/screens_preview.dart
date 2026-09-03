// Geliştirme aracı: ekranları simülatörde sırayla gezip görsel olarak
// doğrulamak için. Uygulamanın kendisine dahil değildir.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/router/app_router.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const _Preview(),
  ));
}

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      locale: const Locale('tr', 'TR'),
      routerConfig: appRouter,
      builder: (context, child) => Stack(
        children: [
          child!,
          // Tema değiştirme düğmesi — sağ üstte, ekranların üstünde durur.
          Positioned(
            top: 50,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: () => setState(() => _mode =
                  _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
              child: const Icon(Icons.contrast),
            ),
          ),
        ],
      ),
    );
  }
}
