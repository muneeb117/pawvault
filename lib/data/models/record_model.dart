import 'package:equatable/equatable.dart';

enum RecordType { vet, vaccine, medication, procedure, other }

class HealthRecord extends Equatable {
  final String id;
  final String petId;
  final RecordType type;
  final String title;
  final String? clinic;
  final String? vet;
  final double? cost;
  final DateTime date;
  final String? notes;
  final List<String> documentUrls;
  final DateTime createdAt;

  const HealthRecord({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    this.clinic,
    this.vet,
    this.cost,
    required this.date,
    this.notes,
    this.documentUrls = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'type': type.name,
        'title': title,
        'clinic': clinic,
        'vet': vet,
        'cost': cost,
        'date': date.toIso8601String(),
        'notes': notes,
        'document_urls': documentUrls,
        'created_at': createdAt.toIso8601String(),
      };

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
        id: json['id'],
        petId: json['pet_id'],
        type: RecordType.values.byName(json['type'] ?? 'other'),
        title: json['title'],
        clinic: json['clinic'],
        vet: json['vet'],
        cost: (json['cost'] as num?)?.toDouble(),
        date: DateTime.parse(json['date']),
        notes: json['notes'],
        documentUrls: List<String>.from(json['document_urls'] ?? []),
        createdAt: DateTime.parse(json['created_at']),
      );

  @override
  List<Object?> get props => [id, petId, type, date];
}
