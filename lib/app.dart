import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/pets/cubit/active_pet_cubit.dart';

class PawVaultApp extends StatelessWidget {
  const PawVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivePetCubit()..load(),
      child: _SessionWatcher(
        child: MaterialApp.router(
          title: 'PawVault',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}

/// Re-loads active pets whenever the Supabase auth session changes,
/// so signing in / out / switching accounts keeps the cubit in sync.
class _SessionWatcher extends StatefulWidget {
  final Widget child;
  const _SessionWatcher({required this.child});
  @override
  State<_SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<_SessionWatcher> {
  late final dynamic _sub;

  @override
  void initState() {
    super.initState();
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (mounted) context.read<ActivePetCubit>().load();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    try { _sub?.cancel(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
