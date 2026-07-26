import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/app_router.dart';
import 'core/state/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'features/ai/ai_repository.dart';
import 'features/concierge/concierge_repository.dart';
import 'features/garage/garage_repository.dart';
import 'features/insurance/insurance_repository.dart';
import 'features/inspection/inspection_repository.dart';
import 'features/partner/partner_repository.dart';
import 'features/profile/user_repository.dart';
import 'features/rewards/rewards_repository.dart';
import 'features/roadside/roadside_repository.dart';
import 'features/services/services_repository.dart';
import 'features/support/support_repository.dart';
import 'features/warranty/warranty_repository.dart';

void main() {
  runApp(const CarNannyApp());
}

class CarNannyApp extends StatefulWidget {
  const CarNannyApp({super.key});

  @override
  State<CarNannyApp> createState() => _CarNannyAppState();
}

class _CarNannyAppState extends State<CarNannyApp> {
  late final ApiClient _apiClient;
  late final AuthState _authState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authState = AuthState(_apiClient);
    _apiClient.onUnauthorized = _authState.logout;
    _router = buildRouter(_authState);
    _authState.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authState),
        Provider.value(value: _apiClient),
        Provider(create: (_) => GarageRepository(_apiClient)),
        Provider(create: (_) => InspectionRepository(_apiClient)),
        Provider(create: (_) => ServicesRepository(_apiClient)),
        Provider(create: (_) => AiRepository(_apiClient)),
        Provider(create: (_) => UserRepository(_apiClient)),
        Provider(create: (_) => PartnerRepository(_apiClient)),
        Provider(create: (_) => RewardsRepository(_apiClient)),
        Provider(create: (_) => SupportRepository(_apiClient)),
        Provider(create: (_) => WarrantyRepository(_apiClient)),
        Provider(create: (_) => InsuranceRepository(_apiClient)),
        Provider(create: (_) => RoadsideRepository(_apiClient)),
        Provider(create: (_) => ConciergeRepository(_apiClient)),
      ],
      child: MaterialApp.router(
        title: 'Car Nanny',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        darkTheme: AppTheme.build(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
      ),
    );
  }
}
