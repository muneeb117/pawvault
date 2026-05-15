import 'package:equatable/equatable.dart';

enum VaccineStatus { upToDate, dueSoon, overdue }

class Vaccine extends Equatable {
  final String id;
  final String petId;
  final String name;
  final String? description;
  final DateTime lastGiven;
  final DateTime nextDue;
  final String? clinic;
  final String? vet;
  final double? cost;
  final DateTime createdAt;

  const Vaccine({
    required this.id,
    required this.petId,
    required this.name,
    this.description,
    required this.lastGiven,
    required this.nextDue,
    this.clinic,
    this.vet,
    this.cost,
    required this.createdAt,
  });

  VaccineStatus get status {
    final now = DateTime.now();
    final daysUntilDue = nextDue.difference(now).inDays;
    if (daysUntilDue < 0) return VaccineStatus.overdue;
    if (daysUntilDue <= 30) return VaccineStatus.dueSoon;
    return VaccineStatus.upToDate;
  }

  int get daysUntilDue => nextDue.difference(DateTime.now()).inDays;

  String get dueLabelShort {
    final days = daysUntilDue;
    if (days < 0) return '${days.abs()} days late';
    if (days == 0) return 'Today';
    if (days < 30) return 'in $days days';
    final months = (days / 30).round();
    return '$months mo left';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'description': description,
        'last_given': lastGiven.toIso8601String(),
        'next_due': nextDue.toIso8601String(),
        'clinic': clinic,
        'vet': vet,
        'cost': cost,
        'created_at': createdAt.toIso8601String(),
      };

  factory Vaccine.fromJson(Map<String, dynamic> json) => Vaccine(
        id: json['id'],
        petId: json['pet_id'],
        name: json['name'],
        description: json['description'],
        lastGiven: DateTime.parse(json['last_given']),
        nextDue: DateTime.parse(json['next_due']),
        clinic: json['clinic'],
        vet: json['vet'],
        cost: (json['cost'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at']),
      );

  @override
  List<Object?> get props => [id, petId, name, lastGiven, nextDue];
}
