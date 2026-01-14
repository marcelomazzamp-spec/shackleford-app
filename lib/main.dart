import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/handy_screen.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forzar orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ShacklefordApp());
}

class ShacklefordApp extends StatelessWidget {
  const ShacklefordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
  
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      case AppRoutes.handy:
        final member = settings.arguments as Member?;
        return MaterialPageRoute(
          builder: (_) => HandyScreen(initialMember: member),
        );
        
      case AppRoutes.map:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Mapa - Próximamente')),
          ),
        );
        
      case AppRoutes.events:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Eventos - Próximamente')),
          ),
        );
        
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Configuración - Próximamente')),
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Página no encontrada')),
          ),
        );
    }
  }
}
