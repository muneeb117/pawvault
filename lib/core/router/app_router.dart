import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/pages/onboarding_page.dart';
import '../../features/auth/pages/auth_landing_page.dart';
import '../../features/auth/pages/sign_in_page.dart';
import '../../features/auth/pages/sign_up_page.dart';
import '../../features/add_pet/pages/add_pet_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/pet_profile/pages/pet_profile_page.dart';
import '../../features/vaccines/pages/vaccines_page.dart';
import '../../features/records/pages/records_page.dart';
import '../../features/medications/pages/medications_page.dart';
import '../../features/care_calendar/pages/care_calendar_page.dart';
import '../../features/ai_assistant/pages/ai_assistant_page.dart';
import '../../features/notifications/pages/notifications_page.dart';
import '../../features/pro_upgrade/pages/pro_upgrade_page.dart';
import '../../shared/widgets/main_shell.dart';
import 'router_helpers.dart';

abstract class AppRoutes {
  static const onboarding   = '/onboarding';
  static const authLanding  = '/auth';
  static const signIn       = '/sign-in';
  static const signUp       = '/sign-up';
  static const home         = '/home';
  static const addPet       = '/add-pet';
  static const careCalendar = '/care';
  static const aiAssistant  = '/ai-assistant';
  static const notifications = '/notifications';
  static const proUpgrade   = '/pro';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.onboarding,
  refreshListenable: AuthRefreshNotifier(),
  redirect: _guard,
  routes: [
    GoRoute(path: AppRoutes.onboarding,  builder: (_, __) => const OnboardingPage()),
    GoRoute(path: AppRoutes.authLanding, builder: (_, __) => const AuthLandingPage()),
    GoRoute(path: AppRoutes.signIn,      builder: (_, __) => const SignInPage()),
    GoRoute(path: AppRoutes.signUp,      builder: (_, __) => const SignUpPage()),
    GoRoute(path: AppRoutes.addPet,      builder: (_, __) => const AddPetPage()),
    GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsPage()),
    GoRoute(path: AppRoutes.proUpgrade,  builder: (_, __) => const ProUpgradePage()),
    GoRoute(
      path: '/pet/:petId/vaccines',
      builder: (_, state) => VaccinesPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId/records',
      builder: (_, state) => RecordsPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId/medications',
      builder: (_, state) => MedicationsPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId',
      builder: (_, state) => PetProfilePage(petId: state.pathParameters['petId']!),
    ),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.home,         builder: (_, __) => const HomePage()),
        GoRoute(path: AppRoutes.careCalendar, builder: (_, __) => const CareCalendarPage()),
        GoRoute(path: AppRoutes.aiAssistant,  builder: (_, __) => const AiAssistantPage()),
      ],
    ),
  ],
);

// Synchronous guard — uses cached AppFlags + Supabase session.
String? _guard(BuildContext context, GoRouterState state) {
  bool isAuth = false;
  try {
    isAuth = Supabase.instance.client.auth.currentUser != null;
  } catch (_) {}

  final loc = state.matchedLocation;
  final isOnboarding = loc == AppRoutes.onboarding;
  final isAuthFlow = loc == AppRoutes.authLanding ||
                     loc == AppRoutes.signIn ||
                     loc == AppRoutes.signUp;

  // Authed: always allow protected screens; bounce out of pre-auth screens.
  if (isAuth) {
    if (isOnboarding || isAuthFlow) return AppRoutes.home;
    return null;
  }

  // Not authed: enforce onboarding → auth → blocked-everywhere-else.
  if (!AppFlags.onboardingDone && !isOnboarding) return AppRoutes.onboarding;
  if (AppFlags.onboardingDone && !isAuthFlow && !isOnboarding) return AppRoutes.authLanding;
  return null;
}
