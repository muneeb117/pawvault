import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<OnboardingPageChanged>((e, emit) => emit(state.copyWith(currentPage: e.page)));
    on<OnboardingCompleted>((e, emit) => emit(state.copyWith(isCompleted: true)));
    on<OnboardingSpeciesChosen>((e, emit) => emit(state.copyWith(primarySpecies: e.species)));
    on<OnboardingPetCountChosen>((e, emit) => emit(state.copyWith(petCount: e.count)));
    on<OnboardingPriorityToggled>((e, emit) {
      final list = List<String>.from(state.priorities);
      list.contains(e.value) ? list.remove(e.value) : list.add(e.value);
      emit(state.copyWith(priorities: list));
    });
    on<OnboardingCareTimeChosen>((e, emit) => emit(state.copyWith(careTime: e.time)));
    on<OnboardingReferralChosen>((e, emit) => emit(state.copyWith(referralSource: e.source)));
    on<OnboardingNotificationsToggled>((e, emit) => emit(state.copyWith(notificationsEnabled: e.enabled)));
  }
}
