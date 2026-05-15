import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

enum _NotifKind { ai, med, vet, doc, insurance, activity }

class _Notif {
  final _NotifKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool unread;
  const _Notif({
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.unread = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _filter = 'all';

  // Placeholder feed — wire to a `notifications` Supabase table or to local
  // scheduled-notification history later.
  final List<_Notif> _all = [
    _Notif(
      kind: _NotifKind.ai,
      title: 'Paw Assistant followed up',
      body: "Has your pet's ear scratching improved?",
      at: DateTime.now().subtract(const Duration(hours: 2)),
      unread: true,
    ),
    _Notif(
      kind: _NotifKind.med,
      title: 'Heartgard given',
      body: 'Marked complete this morning',
      at: DateTime.now().subtract(const Duration(hours: 6)),
      unread: true,
    ),
    _Notif(
      kind: _NotifKind.vet,
      title: 'Reminder: Rabies booster in 12 days',
      body: 'Tap to book with your vet',
      at: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      unread: true,
    ),
    _Notif(
      kind: _NotifKind.activity,
      title: 'Play session logged',
      body: '12 minutes · indoor laser chase',
      at: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      unread: false,
    ),
    _Notif(
      kind: _NotifKind.doc,
      title: 'Vaccine certificate ready',
      body: 'PDF available · Bordetella + DHPP',
      at: DateTime.now().subtract(const Duration(days: 3)),
      unread: true,
    ),
    _Notif(
      kind: _NotifKind.insurance,
      title: 'Trupanion claim approved',
      body: '\$78 reimbursement for ear meds',
      at: DateTime.now().subtract(const Duration(days: 4)),
      unread: false,
    ),
  ];

  static const _filters = [
    ('all',       'All'),
    ('mentions',  'Mentions'),
    ('reminders', 'Reminders'),
    ('ai',        'AI'),
  ];

  List<_Notif> get _filtered {
    switch (_filter) {
      case 'mentions':  return _all.where((n) => n.kind == _NotifKind.ai).toList();
      case 'reminders': return _all.where((n) => n.kind == _NotifKind.vet || n.kind == _NotifKind.med).toList();
      case 'ai':        return _all.where((n) => n.kind == _NotifKind.ai).toList();
      default:          return _all;
    }
  }

  int get _unread => _all.where((n) => n.unread).length;

  Map<String, List<_Notif>> _groupByDay(List<_Notif> list) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final out = <String, List<_Notif>>{};
    for (final n in list) {
      String key;
      if (_isSameDay(n.at, today)) {
        key = 'TODAY';
      } else if (_isSameDay(n.at, yesterday)) {
        key = 'YESTERDAY';
      } else if (today.difference(n.at).inDays < 7) {
        key = 'THIS WEEK';
      } else {
        key = 'EARLIER';
      }
      out.putIfAbsent(key, () => []).add(n);
    }
    return out;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(_filtered);

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(unread: _unread)),
            SliverToBoxAdapter(child: _FilterRow(
              filters: _filters, value: _filter,
              onChanged: (f) => setState(() => _filter = f),
            )),
            if (_filtered.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _EmptyState()),
            for (final entry in grouped.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(entry.key,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: AppColors.stone2)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _NotificationTile(notif: entry.value[i], index: i),
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int unread;
  const _TopBar({required this.unread});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _IconBtn(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.ink),
          ),
          Expanded(
            child: Column(
              children: [
                Text('$unread UNREAD',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: AppColors.clay500)),
                Text('Notifications',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22, fontWeight: FontWeight.w600,
                        color: AppColors.ink, letterSpacing: -0.5)),
              ],
            ),
          ),
          _IconBtn(
            onTap: () {},
            child: const Icon(LucideIcons.settings, size: 18, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<(String, String)> filters;
  final String value;
  final ValueChanged<String> onChanged;
  const _FilterRow({required this.filters, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        children: filters.map((f) {
          final active = f.$1 == value;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: AnimatedContainer(
                duration: 180.ms,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(f.$2,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.ink2)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _Notif notif;
  final int index;
  const _NotificationTile({required this.notif, required this.index});

  (IconData, Color, Color, String) _meta() {
    switch (notif.kind) {
      case _NotifKind.ai:        return (LucideIcons.sparkles,    AppColors.clay50,  AppColors.clay600,  'AI');
      case _NotifKind.med:       return (LucideIcons.pill,        AppColors.rose50,  AppColors.rose600,  'Med');
      case _NotifKind.vet:       return (LucideIcons.stethoscope, AppColors.ochre50, AppColors.ochre600, 'Vet');
      case _NotifKind.doc:       return (LucideIcons.fileText,    AppColors.ochre50, AppColors.ochre600, 'Doc');
      case _NotifKind.insurance: return (LucideIcons.shieldCheck, AppColors.sage50,  AppColors.sage600,  'Insurance');
      case _NotifKind.activity:  return (LucideIcons.activity,    AppColors.sage50,  AppColors.sage600,  'Activity');
    }
  }

  String _timeLabel() {
    final now = DateTime.now();
    final diff = now.difference(notif.at);
    if (diff.inDays >= 1) return DateFormat('EEE').format(notif.at);
    return DateFormat('h:mm a').format(notif.at);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, tint, fg, chip) = _meta();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ),
                      Text(_timeLabel(),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone2)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notif.body,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tint, borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(chip,
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
                  ),
                ],
              ),
            ),
            if (notif.unread)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.clay500, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.08, end: 0);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(18)),
                child: const Icon(LucideIcons.bellOff, size: 26, color: AppColors.clay500),
              ),
              const SizedBox(height: 14),
              Text("You're all caught up",
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('Nothing new here right now.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
            ],
          ),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconBtn({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: child),
        ),
      );
}
