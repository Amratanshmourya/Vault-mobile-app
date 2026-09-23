import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/services/auto_lock_service.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/theme_provider.dart';
import 'data/repositories/vault_repository.dart';
import 'presentation/screens/lock/lock_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/state/auth_state.dart';
import 'presentation/state/security_dashboard_state.dart';
import 'presentation/state/vault_state.dart';
import 'presentation/widgets/privacy_curtain.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final clipboardService = ClipboardService(storageService: storageService);
  final vaultRepository = VaultRepository(storageService: storageService);

  runApp(
    VaultRootApp(
      storageService: storageService,
      clipboardService: clipboardService,
      vaultRepository: vaultRepository,
    ),
  );
}

class VaultRootApp extends StatefulWidget {
  final StorageService storageService;
  final ClipboardService clipboardService;
  final VaultRepository vaultRepository;

  const VaultRootApp({
    super.key,
    required this.storageService,
    required this.clipboardService,
    required this.vaultRepository,
  });

  @override
  State<VaultRootApp> createState() => _VaultRootAppState();
}

class _VaultRootAppState extends State<VaultRootApp> with WidgetsBindingObserver {
  late final AuthState _authState;
  late final VaultState _vaultState;
  late final SecurityDashboardState _dashboardState;
  late final ThemeProvider _themeProvider;
  late final AutoLockService _autoLockService;
  bool _isShielded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authState = AuthState(storageService: widget.storageService);
    _vaultState = VaultState(
      repository: widget.vaultRepository,
      clipboardService: widget.clipboardService,
    );
    _dashboardState = SecurityDashboardState();
    _themeProvider = ThemeProvider();

    _autoLockService = AutoLockService(
      storageService: widget.storageService,
      onLockTriggered: () {
        _authState.lock();
        _vaultState.lockMemory();
      },
    );

    _authState.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isShielded) {
        setState(() => _isShielded = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isShielded) {
        setState(() => _isShielded = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLockService.dispose();
    widget.clipboardService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _authState),
        ChangeNotifierProvider.value(value: _vaultState),
        ChangeNotifierProvider.value(value: _dashboardState),
      ],
      child: Consumer2<ThemeProvider, AuthState>(
        builder: (context, themeProv, auth, _) {
          return Listener(
            onPointerDown: (_) => _autoLockService.recordUserActivity(),
            behavior: HitTestBehavior.translucent,
            child: MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: themeProv.getLightTheme(),
              darkTheme: themeProv.getDarkTheme(),
              themeMode: themeProv.themeMode,
              home: PrivacyCurtain(
                isShielded: _isShielded,
                child: Builder(
                  builder: (ctx) {
                    if (auth.isUninitialized) {
                      return const OnboardingScreen();
                    }
                    if (auth.isLocked) {
                      return const LockScreen();
                    }
                    return const MainNavigationScreen();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
