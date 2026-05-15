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
import '../../features/vaccines/pages/vaccine_edit_page.dart';
import '../../features/vaccines/pages/vaccine_detail_page.dart';
import '../../data/repositories/vaccine_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/records/pages/records_page.dart';
import '../../features/records/pages/record_edit_page.dart';
import '../../features/records/pages/record_detail_page.dart';
import '../../data/repositories/records_repository.dart';
import '../../data/repositories/pet_repository.dart';
import '../../features/medications/pages/medications_page.dart';
import '../../features/medications/pages/medication_edit_page.dart';
import '../../features/medications/pages/medication_detail_page.dart';
import '../../data/repositories/medication_repository.dart';
import '../../features/care_calendar/pages/care_calendar_page.dart';
import '../../features/ai_assistant/pages/ai_assistant_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/documents/pages/documents_page.dart';
import '../../features/documents/pages/document_upload_page.dart';
import '../../features/documents/pages/document_detail_page.dart';
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
  static const profile      = '/profile';
  static const recordsHub   = '/records';
  static const documents    = '/documents';
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
    // ── Full-screen routes (NO bottom nav): edit + detail + add-pet ────
    GoRoute(
      path: '/pet/:petId/vaccines/edit',
      builder: (_, state) => VaccineEditPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId/vaccines/:vaccineId/edit',
      builder: (_, state) => _VaccineEditLoader(
        petId: state.pathParameters['petId']!,
        vaccineId: state.pathParameters['vaccineId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId/vaccines/:vaccineId',
      builder: (_, state) => VaccineDetailPage(
        petId: state.pathParameters['petId']!,
        vaccineId: state.pathParameters['vaccineId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId/records/edit',
      builder: (_, state) => RecordEditPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId/records/:recordId/edit',
      builder: (_, state) => _RecordEditLoader(
        petId: state.pathParameters['petId']!,
        recordId: state.pathParameters['recordId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId/records/:recordId',
      builder: (_, state) => RecordDetailPage(
        petId: state.pathParameters['petId']!,
        recordId: state.pathParameters['recordId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId/medications/edit',
      builder: (_, state) => MedicationEditPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId/medications/:medId/edit',
      builder: (_, state) => _MedEditLoader(
        petId: state.pathParameters['petId']!,
        medId: state.pathParameters['medId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId/medications/:medId',
      builder: (_, state) => MedicationDetailPage(
        petId: state.pathParameters['petId']!,
        medId: state.pathParameters['medId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId/documents/upload',
      builder: (_, state) => DocumentUploadPage(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pet/:petId/documents/:documentId',
      builder: (_, state) => DocumentDetailPage(
        petId: state.pathParameters['petId']!,
        documentId: state.pathParameters['documentId']!,
      ),
    ),
    GoRoute(
      path: '/pet/:petId',
      builder: (_, state) => PetProfilePage(petId: state.pathParameters['petId']!),
    ),

    // ── Shell routes (WITH bottom nav) ──
    // List pages live here so the nav stays visible while browsing.
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.home,         builder: (_, __) => const HomePage()),
        GoRoute(path: AppRoutes.careCalendar, builder: (_, __) => const CareCalendarPage()),
        GoRoute(path: AppRoutes.aiAssistant,  builder: (_, __) => const AiAssistantPage()),
        GoRoute(path: AppRoutes.profile,      builder: (_, __) => const ProfilePage()),
        GoRoute(path: AppRoutes.recordsHub,   builder: (_, __) => const _RecordsHub()),
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
        GoRoute(path: AppRoutes.documents, builder: (_, __) => const DocumentsPage()),
      ],
    ),
  ],
);

// Synchronous guard — uses cached AppFlags + Supabase session.
// Loads a single vaccine then renders the edit page with it pre-filled.
/// Resolves the user's first pet, then renders its records page.
/// Used by the bottom-nav Records tab.
class _RecordsHub extends StatefulWidget {
  const _RecordsHub();
  @override
  State<_RecordsHub> createState() => _RecordsHubState();
}

class _RecordsHubState extends State<_RecordsHub> {
  @override
  void initState() {
    super.initState();
    _resolveAndGo();
  }

  Future<void> _resolveAndGo() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final pets = await PetRepository(Supabase.instance.client).getPets(uid);
        if (pets.isNotEmpty && mounted) {
          context.go('/pet/${pets.first.id}/records');
          return;
        }
      }
    } catch (_) {}
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFFFAF7F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB85C32), strokeWidth: 2)),
      );
}

class _VaccineEditLoader extends StatelessWidget {
  final String petId, vaccineId;
  const _VaccineEditLoader({required this.petId, required this.vaccineId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: VaccineRepository(Supabase.instance.client).getVaccines(petId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAF7F0),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        try {
          final v = snap.data!.firstWhere((x) => x.id == vaccineId);
          return VaccineEditPage(petId: petId, existing: v);
        } catch (_) {
          return VaccineEditPage(petId: petId);
        }
      },
    );
  }
}

class _MedEditLoader extends StatelessWidget {
  final String petId, medId;
  const _MedEditLoader({required this.petId, required this.medId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MedicationRepository(Supabase.instance.client).getMedications(petId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAF7F0),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        try {
          final m = snap.data!.firstWhere((x) => x.id == medId);
          return MedicationEditPage(petId: petId, existing: m);
        } catch (_) {
          return MedicationEditPage(petId: petId);
        }
      },
    );
  }
}

class _RecordEditLoader extends StatelessWidget {
  final String petId, recordId;
  const _RecordEditLoader({required this.petId, required this.recordId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: RecordsRepository(Supabase.instance.client).getRecords(petId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAF7F0),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        try {
          final r = snap.data!.firstWhere((x) => x.id == recordId);
          return RecordEditPage(petId: petId, existing: r);
        } catch (_) {
          return RecordEditPage(petId: petId);
        }
      },
    );
  }
}

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
