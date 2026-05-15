import 'package:equatable/equatable.dart';

enum CareEventType { medication, walk, meal, vet, vaccine, activity }

class CareEvent extends Equatable {
  final String id;
  final String petId;
  final CareEventType type;
  final String title;
  final String? subtitle;
  final DateTime scheduledAt;
  final bool isDone;
  final DateTime createdAt;

  const CareEvent({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    this.subtitle,
    required this.scheduledAt,
    this.isDone = false,
    required this.createdAt,
  });

  CareEvent copyWith({bool? isDone}) => CareEvent(
        id: id,
        petId: petId,
        type: type,
        title: title,
        subtitle: subtitle,
        scheduledAt: scheduledAt,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_done': isDone,
        'created_at': createdAt.toIso8601String(),
      };

  factory CareEvent.fromJson(Map<String, dynamic> json) => CareEvent(
        id: json['id'],
        petId: json['pet_id'],
        type: CareEventType.values.byName(json['type'] ?? 'activity'),
        title: json['title'],
        subtitle: json['subtitle'],
        scheduledAt: DateTime.parse(json['scheduled_at']),
        isDone: json['is_done'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );

  @override
  List<Object?> get props => [id, petId, type, scheduledAt];
}
