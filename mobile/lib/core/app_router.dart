import 'package:go_router/go_router.dart';
import '../features/ai/ai_chat_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/bookings/bookings_list_screen.dart';
import '../features/garage/add_vehicle_screen.dart';
import '../features/garage/garage_list_screen.dart';
import '../features/garage/vehicle_profile_screen.dart';
import '../features/home/home_screen.dart';
import '../features/inspection/book_inspection_screen.dart';
import '../features/inspection/inspection_report_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/services/garage_search_screen.dart';
import '../features/services/services_home_screen.dart';
import '../shell/main_shell.dart';
import 'state/auth_state.dart';

GoRouter buildRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authState,
    redirect: (context, state) {
      final signedIn = authState.status == AuthStatus.signedIn;
      final onAuthFlow = state.matchedLocation == '/auth' || state.matchedLocation == '/auth/forgot-password';

      if (!signedIn && !onAuthFlow) return '/auth';
      if (signedIn && onAuthFlow) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/garage/add', builder: (context, state) => const AddVehicleScreen()),
      GoRoute(
        path: '/garage/:id',
        builder: (context, state) => VehicleProfileScreen(vehicleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/inspection/book', builder: (context, state) => const BookInspectionScreen()),
      GoRoute(
        path: '/inspection/:id/report',
        builder: (context, state) => InspectionReportScreen(inspectionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/services/:category',
        builder: (context, state) => GarageSearchScreen(serviceCategory: state.pathParameters['category']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/garage', builder: (context, state) => const GarageListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/services', builder: (context, state) => const ServicesHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/bookings', builder: (context, state) => const BookingsListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ai', builder: (context, state) => const AiChatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
}
