import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/pet_model.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';

class PetProfilePage extends StatefulWidget {
  final String petId;
  const PetProfilePage({super.key, required this.petId});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AvatarMood _mood = AvatarMood.happy;

  // Demo data — replace with BLoC fetch
  final _pet = Pet(
    id: '1', name: 'Biscuit', species: PetSpecies.dog,
    breed: 'Golden Retriever', dateOfBirth: DateTime(2022, 12, 14),
    gender: 'Male', weightKg: 28.1,
    isNeutered: true, isInsured: true,
    allergies: ['Chicken'],
    about: 'Loves a slow morning, an enthusiastic afternoon, and zoomies right before bed. '
        'Allergic to chicken; loves salmon, sweet potato, and stealing socks.',
    microchipNumber: '985 113 002 145 880',
    primaryVet: 'Happy Paws Vet',
    userId: '', createdAt: DateTime(2022),
  );

  static const _tabs3 = ['Overview', 'Health', 'Photos'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildBanner(context)],
        body: TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(pet: _pet),
            _HealthTab(pet: _pet),
            const _PhotosTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.clay50, AppColors.bone],
          ),
        ),
        child: Stack(
          children: [
            // Paw watermark
            Positioned(
              right: -8, bottom: -16,
              child: Icon(Icons.pets, size: 120, color: AppColors.clay600.withValues(alpha: 0.06)),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top actions row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _IconBtn(onTap: () => context.pop(),
                            child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.ink)),
                        const Spacer(),
                        _IconBtn(child: const Icon(Icons.share_outlined, size: 18, color: AppColors.ink)),
                        const SizedBox(width: 8),
                        _IconBtn(child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.ink)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Avatar
                  GestureDetector(
                    onTap: () {
                      final moods = AvatarMood.values;
                      setState(() => _mood = moods[(moods.indexOf(_mood) + 1) % moods.length]);
                    },
                    child: SizedBox(
                      width: 168, height: 168,
                      child: PetAvatarWidget(
                        pet: _pet.copyWith(mood: _mood),
                        size: 168,
                        showMoodRing: false,
                      ),
                    ),
                  ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
                      duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 4),

                  // Name
                  Text(_pet.name,
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 42, fontWeight: FontWeight.w600,
                          color: AppColors.ink, letterSpacing: -1.5, height: 1.0)),

                  const SizedBox(height: 3),
                  Text('${_pet.breed} · ${_pet.gender ?? ''}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.stone)),

                  const SizedBox(height: 12),

                  // Mood pills
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: AvatarMood.values.map((m) {
                        final active = m == _mood;
                        return GestureDetector(
                          onTap: () => setState(() => _mood = m),
                          child: AnimatedContainer(
                            duration: 150.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: active ? AppColors.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _moodLabel(m),
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500,
                                  color: active ? AppColors.bone : AppColors.stone),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _StatCell(value: _pet.ageLabel, label: 'AGE', bordered: true),
                          _StatCell(
                            value: '${(_pet.weightKg! * 2.205).toStringAsFixed(0)} lbs',
                            label: 'WEIGHT', bordered: true,
                          ),
                          _StatCell(value: 'Playful', label: 'MOOD', bordered: false),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab bar (pill style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(3, (i) {
                        final active = _tabs.index == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _tabs.animateTo(i);
                              setState(() {});
                            },
                            child: AnimatedContainer(
                              duration: 180.ms,
                              margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? AppColors.ink : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: active ? AppColors.ink : AppColors.border),
                              ),
                              child: Center(
                                child: Text(_tabs3[i],
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                                        color: active ? AppColors.bone : AppColors.stone)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _moodLabel(AvatarMood m) {
    switch (m) {
      case AvatarMood.idle:     return 'Idle';
      case AvatarMood.happy:    return 'Happy';
      case AvatarMood.running:  return 'Running';
      case AvatarMood.sleeping: return 'Sleeping';
    }
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool bordered;
  const _StatCell({required this.value, required this.label, required this.bordered});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          border: bordered ? const Border(right: BorderSide(color: AppColors.line2)) : null,
        ),
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22, fontWeight: FontWeight.w600,
                    color: AppColors.ink, letterSpacing: -0.5, height: 1)),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppColors.stone2, letterSpacing: 0.1 * 10)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Pet pet;
  const _OverviewTab({required this.pet});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // About
        _SectionLabel('ABOUT'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pet.about ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.ink2, height: 1.55)),
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (pet.allergies.isNotEmpty)
                  ...pet.allergies.map((a) => _Chip(label: '$a allergy',
                      bg: AppColors.rose50, fg: AppColors.rose600)),
                if (pet.isNeutered)
                  const _Chip(label: 'Neutered', bg: AppColors.neutral100, fg: AppColors.ink2),
                if (pet.isInsured)
                  const _Chip(label: 'Insured', bg: AppColors.ochre50, fg: AppColors.ochre600),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Weight chart
        _SectionLabel('WEIGHT · LAST 6 MONTHS'),
        const SizedBox(height: 8),
        _WeightCard(
          weightLbs: (pet.weightKg! * 2.205).toStringAsFixed(0),
        ),

        const SizedBox(height: 20),

        // Identification
        _SectionLabel('IDENTIFICATION'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _IdRow(icon: Icons.tag_outlined,         label: 'Microchip',     value: pet.microchipNumber ?? '—'),
              _IdRow(icon: Icons.cake_outlined,         label: 'Date of birth', value: '${_months[pet.dateOfBirth.month - 1]} ${pet.dateOfBirth.day}, ${pet.dateOfBirth.year}'),
              _IdRow(icon: Icons.medical_services_outlined, label: 'Primary vet', value: pet.primaryVet ?? '—'),
              _IdRow(icon: Icons.favorite_outline,     label: 'Insurance',     value: 'Trupanion · #PT-44219', last: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightCard extends StatelessWidget {
  final String weightLbs;
  const _WeightCard({required this.weightLbs});

  static const _weights = [59.0, 60.2, 61.5, 60.8, 62.0, 62.0];
  static const _months  = ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: weightLbs,
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 30, fontWeight: FontWeight.w600,
                          color: AppColors.ink, letterSpacing: -0.8),
                    ),
                    TextSpan(
                      text: ' lbs',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.stone2, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sage50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Ideal range',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.sage600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 13, color: AppColors.sage600),
              const SizedBox(width: 4),
              Text('+1.2 lbs vs Dec',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.sage600)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      _months[v.toInt() % _months.length],
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.stone),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _weights.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: AppColors.clay500,
                  barWidth: 2.0,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: Colors.white, strokeWidth: 1.8,
                      strokeColor: AppColors.clay500,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [AppColors.clay500.withValues(alpha: 0.18), AppColors.clay500.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppColors.stone2));
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

class _IdRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _IdRow({required this.icon, required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line2)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.clay50, borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.clay600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                const SizedBox(height: 1),
                Text(value,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.stone2),
        ],
      ),
    );
  }
}

// ─── Health tab ───────────────────────────────────────────────────────────────
class _HealthTab extends StatelessWidget {
  final Pet pet;
  const _HealthTab({required this.pet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _SectionLabel('WEIGHT · LAST 6 MONTHS'),
        const SizedBox(height: 8),
        _WeightCard(weightLbs: (pet.weightKg! * 2.205).toStringAsFixed(0)),
        const SizedBox(height: 20),
        _SectionLabel('VACCINATIONS'),
        const SizedBox(height: 8),
        _PlaceholderCard(label: 'No vaccine records yet', icon: Icons.vaccines_outlined),
        const SizedBox(height: 20),
        _SectionLabel('MEDICATIONS'),
        const SizedBox(height: 8),
        _PlaceholderCard(label: 'No medications recorded', icon: Icons.medication_outlined),
      ],
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.stone2),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
        ],
      ),
    );
  }
}

// ─── Photos tab ───────────────────────────────────────────────────────────────
class _PhotosTab extends StatelessWidget {
  const _PhotosTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.clay50, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.photo_library_outlined, size: 28, color: AppColors.clay500),
          ),
          const SizedBox(height: 16),
          Text('No photos yet',
              style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text('Capture their best moments.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text('Add photos', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
