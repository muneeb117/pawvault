import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProUpgradePage extends StatefulWidget {
  const ProUpgradePage({super.key});

  @override
  State<ProUpgradePage> createState() => _ProUpgradePageState();
}

class _ProUpgradePageState extends State<ProUpgradePage> {
  bool _isYearly = true;

  static const _features = [
    (Icons.pets, 'Unlimited pets', 'Track the whole household'),
    (Icons.auto_awesome, 'AI symptom triage', 'Trained on veterinary literature'),
    (Icons.share_rounded, 'Shareable PDF records', 'Send to vets & sitters in one tap'),
    (Icons.notifications_active_outlined, 'Smart refill reminders', 'Never run out of meds again'),
    (Icons.cloud_outlined, 'Cloud backup', 'iCloud + cross-device sync'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.bone,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Restore',
                style: TextStyle(color: AppColors.stone)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.clay500.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets, color: AppColors.clay500, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('PAWVAULT PRO',
                      style: TextStyle(
                          color: AppColors.stone,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Care for them\nlike you mean it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: AppColors.bone)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Features
            ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.clay500.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(f.$1, color: AppColors.clay500, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.$2,
                                style: const TextStyle(
                                    color: AppColors.bone,
                                    fontWeight: FontWeight.w600)),
                            Text(f.$3,
                                style: const TextStyle(
                                    color: AppColors.stone, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle,
                          color: AppColors.sage500, size: 18),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Testimonial
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surface.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: List.generate(5, (_) =>
                      const Icon(Icons.star, color: AppColors.ochre500, size: 14))),
                  const SizedBox(height: 8),
                  const Text(
                    '"Pro caught Luna\'s overdue rabies the week before boarding. Lifesaver"',
                    style: TextStyle(color: AppColors.bone, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _PlanOption(
                    label: 'MONTHLY',
                    price: '\$4.99',
                    sub: 'per month',
                    selected: !_isYearly,
                    onTap: () => setState(() => _isYearly = false),
                  ),
                  _PlanOption(
                    label: 'YEARLY',
                    price: '\$29.99',
                    sub: '\$2.50/mo · billed yearly',
                    selected: _isYearly,
                    badge: 'SAVE 50%',
                    onTap: () => setState(() => _isYearly = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.clay500,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {},
                child: const Text('Start 7-Day Free Trial',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.bone)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Cancel anytime · No commitment',
                  style: TextStyle(color: AppColors.stone, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String label;
  final String price;
  final String sub;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _PlanOption({
    required this.label, required this.price, required this.sub,
    required this.selected, required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.clay500 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.bone.withOpacity(0.2) : AppColors.clay500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: selected ? AppColors.bone : AppColors.clay500)),
                ),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 1,
                      color: selected ? AppColors.bone : AppColors.stone)),
              const SizedBox(height: 4),
              Text(price,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: selected ? AppColors.bone : AppColors.bone)),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected ? AppColors.bone.withOpacity(0.7) : AppColors.stone)),
            ],
          ),
        ),
      ),
    );
  }
}
