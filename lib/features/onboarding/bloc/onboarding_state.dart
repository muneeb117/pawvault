part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  final int currentPage;
  final bool isCompleted;

  // Question answers
  final String? primarySpecies;
  final String? petCount;
  final List<String> priorities;
  final String? careTime;
  final String? referralSource;
  final bool notificationsEnabled;

  const OnboardingState({
    this.currentPage = 0,
    this.isCompleted = false,
    this.primarySpecies,
    this.petCount,
    this.priorities = const [],
    this.careTime,
    this.referralSource,
    this.notificationsEnabled = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    bool? isCompleted,
    String? primarySpecies,
    String? petCount,
    List<String>? priorities,
    String? careTime,
    String? referralSource,
    bool? notificationsEnabled,
  }) => OnboardingState(
        currentPage: currentPage ?? this.currentPage,
        isCompleted: isCompleted ?? this.isCompleted,
        primarySpecies: primarySpecies ?? this.primarySpecies,
        petCount: petCount ?? this.petCount,
        priorities: priorities ?? this.priorities,
        careTime: careTime ?? this.careTime,
        referralSource: referralSource ?? this.referralSource,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  List<Object?> get props => [
        currentPage, isCompleted, primarySpecies, petCount,
        priorities, careTime, referralSource, notificationsEnabled,
      ];
}
