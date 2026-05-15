part of 'add_pet_bloc.dart';

abstract class AddPetEvent extends Equatable {
  const AddPetEvent();
  @override
  List<Object?> get props => [];
}

class AddPetSpeciesSelected extends AddPetEvent {
  final PetSpecies species;
  const AddPetSpeciesSelected(this.species);
  @override List<Object?> get props => [species];
}

class AddPetMoodSelected extends AddPetEvent {
  final AvatarMood mood;
  const AddPetMoodSelected(this.mood);
  @override List<Object?> get props => [mood];
}

class AddPetNameChanged extends AddPetEvent {
  final String name;
  const AddPetNameChanged(this.name);
  @override List<Object?> get props => [name];
}

class AddPetBreedChanged extends AddPetEvent {
  final String breed;
  const AddPetBreedChanged(this.breed);
  @override List<Object?> get props => [breed];
}

class AddPetDobChanged extends AddPetEvent {
  final DateTime dob;
  const AddPetDobChanged(this.dob);
  @override List<Object?> get props => [dob];
}

class AddPetGenderChanged extends AddPetEvent {
  final String gender;
  const AddPetGenderChanged(this.gender);
  @override List<Object?> get props => [gender];
}

class AddPetPhotoSelected extends AddPetEvent {
  final Uint8List bytes;
  final String ext;
  const AddPetPhotoSelected(this.bytes, this.ext);
  @override List<Object?> get props => [ext];
}

class AddPetStepAdvanced extends AddPetEvent {
  const AddPetStepAdvanced();
}

class AddPetStepBacked extends AddPetEvent {
  const AddPetStepBacked();
}

class AddPetSubmitted extends AddPetEvent {
  final String userId;
  const AddPetSubmitted(this.userId);
  @override List<Object?> get props => [userId];
}
