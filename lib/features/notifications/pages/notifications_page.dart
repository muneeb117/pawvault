import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _filter = 'All';

  static const _filters = ['All', 'Mentions', 'Reminders', 'AI'];

  static final _notifications = [
    _Notif(type: 'AI', title: 'Paw Assistant followed up',
        body: 'Has Biscuit\'s ear scratching improved?', time: '2:14 PM', group: 'TODAY'),
    _Notif(type: 'Med', title: 'Heartgard given',
        body: 'Marked complete by Jack', time: '8:02 AM', group: 'TODAY'),
    _Notif(type: 'Vet', title: 'Reminder: Rabies booster in 12 days',
        body: 'Tap to book with Happy Paws Vet', time: '7:15 PM', group: 'YESTERDAY'),
    _Notif(type: 'Activity', title: 'Luna logged a play session',
        body: '12 minutes · indoor laser chase', time: '11:00 AM', group: 'YESTERDAY'),
    _Notif(type: 'Doc', title: 'Vaccine certificate ready',
        body: 'PDF available · Bordetella + DHPP', time: 'Mon', group: 'THIS WEEK'),
    _Notif(type: 'Insurance', title: 'Trupanion claim approved',
        body: '\$78 reimbursement for ear meds', time: 'Sun', group: 'THIS WEEK'),
  ];

  static const _typeColors = {
    'AI': AppColors.clay500,
    'Med': AppColors.ochre500,
    'Vet': AppColors.rose500,
    'Activity': AppColors.sage500,
    'Doc': AppColors.stone,
    'Insurance': AppColors.sage500,
  };

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_Notif>>{};
    for (final n in _notifications) {
      grouped.putIfAbsent(n.group, () => []).add(n);
    }

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: AppBar(title: const Text('Notifications')),
      body: Column(
        children: [
          // Filter row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: AppColors.bone,
            child: Row(
              children: _filters.map((f) {
                final isSelected = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.ink : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected ? AppColors.ink : AppColors.border),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.bone : AppColors.ink,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.expand((entry) => [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(entry.key,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w600)),
                ),
                ...entry.value.map((n) => _NotifTile(notif: n,
                    color: _typeColors[n.type] ?? AppColors.stone)),
              ]).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notif {
  final String type;
  final String title;
  final String body;
  final String time;
  final String group;
  const _Notif({required this.type, required this.title, required this.body,
      required this.time, required this.group});
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final Color color;
  const _NotifTile({required this.notif, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(notif.type[0],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ),
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontSize: 13)),
                    ),
                    Text(notif.time,
                        style: const TextStyle(fontSize: 11, color: AppColors.stone)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(notif.body,
                    style: const TextStyle(fontSize: 12, color: AppColors.stone)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
