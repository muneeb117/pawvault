abstract class AppConstants {
  // Supabase – replace with your project values
  static const supabaseUrl = 'https://ntmuoxcfxsdydhxoxbrt.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_Xh0bHdjJJh2W6n38N6wR6g_5h4wO-Xj';

  // OpenAI (for AI Assistant + document extraction).
  // Provide your key via --dart-define so it never lands in source control:
  //
  //   flutter run --dart-define=OPENAI_API_KEY=sk-...your-key...
  //
  // In Android Studio: Edit Configurations → Additional run args →
  //   --dart-define=OPENAI_API_KEY=sk-...
  //
  // Get a key at https://platform.openai.com/api-keys
  static const openAiApiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const openAiModel  = 'gpt-4o-mini';

  // Padding
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;

  // Border radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Pet species
  static const List<String> species = ['Dog', 'Cat', 'Rabbit', 'Bird'];

  // Avatar moods
  static const List<String> avatarMoods = ['Idle', 'Happy', 'Running', 'Sleeping'];

  // Record types
  static const List<String> recordTypes = ['Vet', 'Vaccine', 'Medication', 'Procedure', 'Other'];

  // Quick care actions
  static const List<String> quickCareActions = ['Vet', 'Meds', 'Walk', 'Meal'];
}
