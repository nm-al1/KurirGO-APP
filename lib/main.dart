import 'package:flutter/material.dart';

import 'features/production/app.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'features/controllers/delivery_controller.dart';
import 'features/shared/delivery_scope.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/load_verification/load_verification_screen.dart';
import 'features/route_preview/route_preview_screen.dart';
import 'features/live_navigation/live_navigation_screen.dart';
import 'features/history/history_screen.dart';
import 'features/profile/courier_pages.dart';

void main() {
  if (const bool.fromEnvironment('DEMO_MODE')) {
    runCourierApp(demo: true);
  } else {
    runCourierApp();
  }
}

class MyApp extends StatefulWidget {
  final DeliveryController? controller;
  const MyApp({this.controller, super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final c = widget.controller ?? DeliveryController();
  @override
  void dispose() {
    if (widget.controller == null) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeliveryScope(
    controller: c,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KurirGO • Browcyl Delivery',
      initialRoute: '/login',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.matteCharcoal,
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
        colorScheme: const ColorScheme.dark(
          primary: AppColors.electricLime,
          onPrimary: AppColors.matteCharcoal,
          surface: AppColors.matteCharcoal,
          onSurface: AppColors.textLight,
          secondary: AppColors.electricLime,
          onSecondary: AppColors.matteCharcoal,
        ),
        textTheme: TextTheme(
          bodyMedium: AppTypography.bodyStreet.copyWith(fontSize: 14),
          titleLarge: AppTypography.heading,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.matteCharcoal,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSecondary,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: const WidgetStatePropertyAll(AppColors.matteCharcoal),
        ),
        chipTheme: const ChipThemeData(
          side: BorderSide(color: AppColors.darkBorder),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ),
      onGenerateInitialRoutes: (initial) => [
        _route(RouteSettings(name: initial)),
      ],
      onGenerateRoute: _route,
    ),
  );
  Route<void> _route(RouteSettings settings) {
    var route = settings.name;
    if (!c.loggedIn && route != '/register') route = '/login';
    if ((route == '/verification' || route == '/route-preview') &&
        c.isNavigating) {
      route = c.currentStopIndex == 2 ? '/history' : '/navigation';
    }
    if (route == '/route-preview' && c.activeTourResult == null) {
      route = '/verification';
    }
    if (route == '/navigation' && !c.isNavigating) {
      route = '/dashboard';
    }
    if (route == '/history' && c.currentStopIndex != 2) {
      route = '/dashboard';
    }
    final screen = switch (route) {
      '/register' => const RegisterScreen(),
      '/dashboard' => const DashboardScreen(),
      '/verification' => const LoadVerificationScreen(),
      '/route-preview' => const RoutePreviewScreen(),
      '/navigation' => const LiveNavigationScreen(),
      '/history' => const HistoryScreen(),
      '/performance' => const CourierDetailsPage(performance: true),
      '/profile' => const CourierDetailsPage(),
      '/edit-profile' => const EditProfilePage(),
      _ => const LoginScreen(),
    };
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: route),
      builder: (_) => screen,
    );
  }
}
