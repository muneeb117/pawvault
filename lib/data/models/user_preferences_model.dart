class UserPreferences {
  final String userId;
  final String? displayName;
  final String? primarySpecies;     // dog | cat | rabbit | bird | multiple
  final String? petCount;           // 1 | 2 | 3 | 4+
  final List<String> priorities;    // vaccines | meds | records | activities
  final String? careTime;           // morning | afternoon | evening | anytime
  final String? referralSource;     // app_store | friend | vet | social | other
  final bool notificationsEnabled;

  const UserPreferences({
    required this.userId,
    this.displayName,
    this.primarySpecies,
    this.petCount,
    this.priorities = const [],
    this.careTime,
    this.referralSource,
    this.notificationsEnabled = false,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'primary_species': primarySpecies,
        'pet_count': petCount,
        'priorities': priorities,
        'care_time': careTime,
        'referral_source': referralSource,
        'notifications_enabled': notificationsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences(
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String?,
        primarySpecies: j['primary_species'] as String?,
        petCount: j['pet_count'] as String?,
        priorities: List<String>.from(j['priorities'] ?? const []),
        careTime: j['care_time'] as String?,
        referralSource: j['referral_source'] as String?,
        notificationsEnabled: j['notifications_enabled'] ?? false,
      );
}
