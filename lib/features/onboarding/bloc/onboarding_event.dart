part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class OnboardingPageChanged extends OnboardingEvent {
  final int page;
  const OnboardingPageChanged(this.page);
  @override
  List<Object?> get props => [page];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

class OnboardingSpeciesChosen extends OnboardingEvent {
  final String species;
  const OnboardingSpeciesChosen(this.species);
  @override
  List<Object?> get props => [species];
}

class OnboardingPetCountChosen extends OnboardingEvent {
  final String count;
  const OnboardingPetCountChosen(this.count);
  @override
  List<Object?> get props => [count];
}

class OnboardingPriorityToggled extends OnboardingEvent {
  final String value;
  const OnboardingPriorityToggled(this.value);
  @override
  List<Object?> get props => [value];
}

class OnboardingCareTimeChosen extends OnboardingEvent {
  final String time;
  const OnboardingCareTimeChosen(this.time);
  @override
  List<Object?> get props => [time];
}

class OnboardingReferralChosen extends OnboardingEvent {
  final String source;
  const OnboardingReferralChosen(this.source);
  @override
  List<Object?> get props => [source];
}

class OnboardingNotificationsToggled extends OnboardingEvent {
  final bool enabled;
  const OnboardingNotificationsToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}
