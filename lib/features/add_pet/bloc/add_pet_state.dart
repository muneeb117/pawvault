part of 'add_pet_bloc.dart';

enum AddPetStatus { idle, loading, success, failure }

class AddPetState extends Equatable {
  final int step;
  final PetSpecies species;
  final AvatarMood mood;
  final String name;
  final String breed;
  final DateTime? dob;
  final String? gender;
  final Uint8List? photoBytes;
  final String? photoExt;
  final AddPetStatus status;
  final String? error;
  final Pet? createdPet;

  const AddPetState({
    this.step = 0,
    this.species = PetSpecies.dog,
    this.mood = AvatarMood.idle,
    this.name = '',
    this.breed = '',
    this.dob,
    this.gender,
    this.photoBytes,
    this.photoExt,
    this.status = AddPetStatus.idle,
    this.error,
    this.createdPet,
  });

  AddPetState copyWith({
    int? step,
    PetSpecies? species,
    AvatarMood? mood,
    String? name,
    String? breed,
    DateTime? dob,
    String? gender,
    Uint8List? photoBytes,
    String? photoExt,
    AddPetStatus? status,
    String? error,
    Pet? createdPet,
  }) =>
      AddPetState(
        step: step ?? this.step,
        species: species ?? this.species,
        mood: mood ?? this.mood,
        name: name ?? this.name,
        breed: breed ?? this.breed,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        photoBytes: photoBytes ?? this.photoBytes,
        photoExt: photoExt ?? this.photoExt,
        status: status ?? this.status,
        error: error ?? this.error,
        createdPet: createdPet ?? this.createdPet,
      );

  @override
  List<Object?> get props => [step, species, mood, name, breed, dob, status];
}
