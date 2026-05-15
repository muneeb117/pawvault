import 'package:equatable/equatable.dart';

enum MedFrequency { once, daily, twiceDaily, threeTimesDaily, weekly, monthly, asNeeded }

class Medication extends Equatable {
  final String id;
  final String petId;
  final String name;
  final String? category; // Heartworm, Allergy, Supplement, Joint
  final MedFrequency frequency;
  final String dosage; // "1 chewable", "1 tablet", etc.
  final int? remainingCount;
  final DateTime? nextDoseAt;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const Medication({
    required this.id,
    required this.petId,
    required this.name,
    this.category,
    required this.frequency,
    required this.dosage,
    this.remainingCount,
    this.nextDoseAt,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  bool get isLowRefill => (remainingCount ?? 99) <= 5;

  String get frequencyLabel {
    switch (frequency) {
      case MedFrequency.once:
        return 'Once';
      case MedFrequency.daily:
        return '1× daily';
      case MedFrequency.twiceDaily:
        return '2× daily';
      case MedFrequency.threeTimesDaily:
        return '3× daily';
      case MedFrequency.weekly:
        return 'Weekly';
      case MedFrequency.monthly:
        return 'Monthly';
      case MedFrequency.asNeeded:
        return 'As needed';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'category': category,
        'frequency': frequency.name,
        'dosage': dosage,
        'remaining_count': remainingCount,
        'next_dose_at': nextDoseAt?.toIso8601String(),
        'is_active': isActive,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'],
        petId: json['pet_id'],
        name: json['name'],
        category: json['category'],
        frequency: MedFrequency.values.byName(json['frequency'] ?? 'daily'),
        dosage: json['dosage'] ?? '',
        remainingCount: json['remaining_count'],
        nextDoseAt: json['next_dose_at'] != null ? DateTime.parse(json['next_dose_at']) : null,
        isActive: json['is_active'] ?? true,
        startDate: DateTime.parse(json['start_date']),
        endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        createdAt: DateTime.parse(json['created_at']),
      );

  @override
  List<Object?> get props => [id, petId, name, frequency];
}
