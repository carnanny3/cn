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
import '../features/partner/partner_catalog_screen.dart';
import '../features/partner/partner_home_screen.dart';
import '../features/partner/partner_inspection_checklist_screen.dart';
import '../features/partner/partner_jobs_screen.dart';
import '../features/partner/partner_profile_screen.dart';
import '../features/partner/partner_signup_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/services/garage_search_screen.dart';
import '../features/services/services_home_screen.dart';
import '../shell/main_shell.dart';
import '../shell/partner_shell.dart';
import 'state/auth_state.dart';

GoRouter buildRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authState,
    redirect: (context, state) {
      final signedIn = authState.status == AuthStatus.signedIn;
      final onAuthFlow = state.matchedLocation == '/auth' ||
          state.matchedLocation == '/auth/forgot-password' ||
          state.matchedLocation == '/partner-signup';

      if (!signedIn && !onAuthFlow) return '/auth';
      if (signedIn && onAuthFlow) return authState.isPartner ? '/partner' : '/home';

      // Keep partner accounts inside the partner mode, and customer accounts
      // out of it — the two roles share one app binary but not one nav tree.
      final onPartnerRoute = state.matchedLocation.startsWith('/partner');
      if (signedIn && authState.isPartner && !onPartnerRoute) return '/partner';
      if (signedIn && !authState.isPartner && onPartnerRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/partner-signup', builder: (context, state) => const PartnerSignupScreen()),
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
      GoRoute(
        path: '/partner/inspection/:id/checklist',
        builder: (context, state) => PartnerInspectionChecklistScreen(inspectionId: state.pathParameters['id']!),
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PartnerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/partner', builder: (context, state) => const PartnerHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/partner/jobs', builder: (context, state) => const PartnerJobsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/partner/catalog', builder: (context, state) => const PartnerCatalogScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/partner/profile', builder: (context, state) => const PartnerProfileScreen())]),
        ],
      ),
    ],
  );
}
