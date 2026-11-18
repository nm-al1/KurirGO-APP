import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/courier_store.dart';
import '../../data/database_factory.dart';
import '../../data/route_service.dart';
import '../controllers/courier_runtime.dart';
import 'auth_page.dart';
import 'home.dart';

const ink = Color(0xFF18181B), lime = Color(0xFFC6FF00);
const authRedirect = 'com.browcyl.kurirgo://login-callback/';
bool _backendInitialized = false;
Future<void> runCourierApp({bool demo = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (demo) {
      final factory = courierDatabaseFactory();
      final db = await factory.openDatabase(
        '${await factory.getDatabasesPath()}/courier_demo.db',
        options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
      );
      final runtime = CourierRuntime(
        CourierStore(db, 'demo', localOnly: true),
        SupabaseClient(
          'https://demo.invalid',
          'demo',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        RouteService(),
      );
      await runtime.load();
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KurirGO Demo',
          theme: courierTheme(),
          home: CourierHome(runtime: runtime),
        ),
      );
      return;
    }
    if (!_backendInitialized) {
      await Supabase.initialize(
        url: const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://joddamojsxuwovltrsdq.supabase.co',
        ),
        publishableKey: const String.fromEnvironment(
          'SUPABASE_KEY',
          defaultValue: 'sb_publishable_lit7BETnU4sCFGOgUe722g_pwkSkJGA',
        ),
      );
      _backendInitialized = true;
    }
    final factory = courierDatabaseFactory();
    final db = await factory.openDatabase(
      '${await factory.getDatabasesPath()}/courier.db',
      options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
    );
    runApp(CourierApp(db: db));
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Penyimpanan aplikasi belum dapat dibuka. Tutup dan buka kembali aplikasi. Data tidak dihapus.',
                    ),
                    TextButton(
                      onPressed: runCourierApp,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData courierTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  colorScheme: ColorScheme.fromSeed(
    seedColor: lime,
    primary: ink,
    onPrimary: Colors.white,
    secondary: lime,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF8FAFC),
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: lime,
      foregroundColor: ink,
      disabledBackgroundColor: const Color(0xFFE2E8F0),
      disabledForegroundColor: const Color(0xFF64748B),
      minimumSize: const Size(48, 54),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: lime,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? ink : Colors.white,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  ),
);

class CourierApp extends StatefulWidget {
  final Database db;
  const CourierApp({required this.db, super.key});
  @override
  State<CourierApp> createState() => _CourierAppState();
}

class _CourierAppState extends State<CourierApp> with WidgetsBindingObserver {
  final backend = Supabase.instance.client;
  CourierRuntime? runtime;
  StreamSubscription<AuthState>? subscription;
  bool recovery = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    subscription = backend.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) recovery = true;
      unawaited(openAccount());
    });
    unawaited(openAccount());
  }

  Future<void> openAccount() async {
    final owner = backend.auth.currentUser?.id;
    if (runtime?.store.owner == owner) {
      if (mounted) setState(() {});
      return;
    }
    runtime?.dispose();
    runtime = null;
    if (owner != null) {
      final next = CourierRuntime(
        CourierStore(widget.db, owner),
        backend,
        RouteService(),
      );
      runtime = next;
      try {
        await next.load();
        await next.prepareGps();
        unawaited(next.sync());
      } catch (_) {
        error = 'Data lokal belum dapat dibaca. Buka ulang aplikasi.';
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(runtime?.sync());
    if (state != AppLifecycleState.resumed) runtime?.timer?.cancel();
    if (state == AppLifecycleState.resumed && runtime != null) {
      runtime!.timer?.cancel();
      runtime!.timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(runtime?.sync()),
      );
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    runtime?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(backend.auth.currentUser?.id),
    debugShowCheckedModeBanner: false,
    title: 'Browcyl Delivery',
    theme: courierTheme(),
    home: error != null
        ? Scaffold(body: Center(child: Text(error!)))
        : recovery
        ? AuthPage(
            key: const ValueKey('recovery'),
            backend: backend,
            recovery: true,
            onRecovered: () => setState(() => recovery = false),
          )
        : runtime == null
        ? AuthPage(backend: backend)
        : CourierHome(key: ValueKey(runtime!.store.owner), runtime: runtime!),
  );
}

void problem(BuildContext context, Object error) {
  final message = error is StateError
      ? error.message
      : error is AuthException
      ? error.message
      : 'Belum berhasil. Periksa koneksi lalu coba lagi.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      PageRouteBuilder(
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
