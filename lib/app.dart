import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/network/auth_storage.dart';
import 'core/providers/nav_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/catalog/screens/catalog_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/deliveries/screens/deliveries_screen.dart';
import 'features/orders/screens/orders_screen.dart';
import 'features/procurement/screens/procurement_screen.dart';
import 'features/riders/screens/riders_screen.dart';
import 'features/customer_support/screens/customer_support_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bajaru Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  String? _otpPhone;

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(authTokenProvider);

    return tokenAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => _buildAuthFlow(),
      data: (token) => token != null ? const _Shell() : _buildAuthFlow(),
    );
  }

  Widget _buildAuthFlow() {
    if (_otpPhone != null) {
      return OtpScreen(
        phoneNumber: _otpPhone!,
        onBack: () => setState(() => _otpPhone = null),
      );
    }
    return LoginScreen(
      onOtpSent: (phone) => setState(() => _otpPhone = phone),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.lime,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  DateTime? _lastBackPressed;

  /// Tracks which tab indices have been visited at least once.
  /// Dashboard (0) is always included so it loads on startup.
  /// All other tabs are built only on first visit — their providers
  /// do not initialize until the user actually navigates to that tab.
  final _visitedTabs = <int>{0};

  static const _allScreens = [
    DashboardScreen(),          // 0
    ProcurementScreen(),        // 1
    OrdersScreen(),             // 2
    RidersScreen(),             // 3
    DeliveriesScreen(),         // 4
    CatalogScreen(),            // 5
    CustomerSupportScreen(),    // 6
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);

    // Mark the current tab as visited so its screen widget is inserted
    // into the tree for the first time (and kept alive thereafter).
    _visitedTabs.add(index);

    final children = List.generate(
      _allScreens.length,
      (i) => _visitedTabs.contains(i) ? _allScreens[i] : const SizedBox.shrink(),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (index != 0) {
          ref.read(navIndexProvider.notifier).state = 0;
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: IndexedStack(index: index, children: children),
    );
  }
}
