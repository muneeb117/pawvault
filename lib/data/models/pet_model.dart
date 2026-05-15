import 'package:equatable/equatable.dart';

enum PetSpecies { dog, cat, rabbit, bird }

enum AvatarMood { idle, happy, running, sleeping }

class Pet extends Equatable {
  final String id;
  final String name;
  final PetSpecies species;
  final String breed;
  final DateTime dateOfBirth;
  final String? gender;
  final double? weightKg;
  final String? photoUrl;
  final AvatarMood mood;
  final String? microchipNumber;
  final String? primaryVet;
  final bool isNeutered;
  final bool isInsured;
  final List<String> allergies;
  final String? about;
  final String userId;
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.dateOfBirth,
    this.gender,
    this.weightKg,
    this.photoUrl,
    this.mood = AvatarMood.idle,
    this.microchipNumber,
    this.primaryVet,
    this.isNeutered = false,
    this.isInsured = false,
    this.allergies = const [],
    this.about,
    required this.userId,
    required this.createdAt,
  });

  String get ageLabel {
    final now = DateTime.now();
    final years = now.year - dateOfBirth.year;
    final months = now.month - dateOfBirth.month;
    final totalMonths = years * 12 + months;
    final y = totalMonths ~/ 12;
    final m = totalMonths % 12;
    if (y == 0) return '$m mo';
    if (m == 0) return '$y yr';
    return '$y yr $m mo';
  }

  String get lottieAsset {
    final speciesName = species.name; // dog, cat, rabbit, bird
    final moodName = mood.name;       // idle, happy, running, sleeping
    return 'assets/animations/${speciesName}_$moodName.json';
  }

  Pet copyWith({
    String? name,
    PetSpecies? species,
    String? breed,
    DateTime? dateOfBirth,
    String? gender,
    double? weightKg,
    String? photoUrl,
    AvatarMood? mood,
    String? microchipNumber,
    String? primaryVet,
    bool? isNeutered,
    bool? isInsured,
    List<String>? allergies,
    String? about,
  }) {
    return Pet(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      photoUrl: photoUrl ?? this.photoUrl,
      mood: mood ?? this.mood,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      primaryVet: primaryVet ?? this.primaryVet,
      isNeutered: isNeutered ?? this.isNeutered,
      isInsured: isInsured ?? this.isInsured,
      allergies: allergies ?? this.allergies,
      about: about ?? this.about,
      userId: userId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species.name,
        'breed': breed,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'weight_kg': weightKg,
        'photo_url': photoUrl,
        'mood': mood.name,
        'microchip_number': microchipNumber,
        'primary_vet': primaryVet,
        'is_neutered': isNeutered,
        'is_insured': isInsured,
        'allergies': allergies,
        'about': about,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'],
        name: json['name'],
        species: PetSpecies.values.byName(json['species']),
        breed: json['breed'] ?? '',
        dateOfBirth: DateTime.parse(json['date_of_birth']),
        gender: json['gender'],
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        photoUrl: json['photo_url'],
        mood: AvatarMood.values.byName(json['mood'] ?? 'idle'),
        microchipNumber: json['microchip_number'],
        primaryVet: json['primary_vet'],
        isNeutered: json['is_neutered'] ?? false,
        isInsured: json['is_insured'] ?? false,
        allergies: List<String>.from(json['allergies'] ?? []),
        about: json['about'],
        userId: json['user_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  @override
  List<Object?> get props => [id, name, species, breed, dateOfBirth, mood];
}
