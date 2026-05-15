import 'package:equatable/equatable.dart';

enum DocType { vaccineCard, labReport, prescription, insurance, receipt, vetVisit, other }

extension DocTypeX on DocType {
  String get wireName => switch (this) {
        DocType.vaccineCard  => 'vaccine_card',
        DocType.labReport    => 'lab_report',
        DocType.prescription => 'prescription',
        DocType.insurance    => 'insurance',
        DocType.receipt      => 'receipt',
        DocType.vetVisit     => 'vet_visit',
        DocType.other        => 'other',
      };

  String get label => switch (this) {
        DocType.vaccineCard  => 'Vaccine card',
        DocType.labReport    => 'Lab report',
        DocType.prescription => 'Prescription',
        DocType.insurance    => 'Insurance',
        DocType.receipt      => 'Receipt',
        DocType.vetVisit     => 'Vet visit',
        DocType.other        => 'Other',
      };

  static DocType fromWire(String? s) {
    switch (s) {
      case 'vaccine_card':  return DocType.vaccineCard;
      case 'lab_report':    return DocType.labReport;
      case 'prescription':  return DocType.prescription;
      case 'insurance':     return DocType.insurance;
      case 'receipt':       return DocType.receipt;
      case 'vet_visit':     return DocType.vetVisit;
      default:              return DocType.other;
    }
  }
}

/// Structured fields extracted by AI Vision from a document.
class ExtractedHealth {
  final String? petName;
  final String? clinic;
  final String? vet;
  final DateTime? visitDate;
  final DateTime? nextVisit;
  final String? diagnosis;
  final List<ExtractedVaccine> vaccines;
  final List<ExtractedMed> medications;
  final double? cost;

  const ExtractedHealth({
    this.petName, this.clinic, this.vet, this.visitDate, this.nextVisit,
    this.diagnosis, this.vaccines = const [], this.medications = const [],
    this.cost,
  });

  Map<String, dynamic> toJson() => {
        'pet_name': petName,
        'clinic': clinic, 'vet': vet,
        'visit_date': visitDate?.toIso8601String(),
        'next_visit': nextVisit?.toIso8601String(),
        'diagnosis': diagnosis,
        'vaccines': vaccines.map((v) => v.toJson()).toList(),
        'medications': medications.map((m) => m.toJson()).toList(),
        'cost': cost,
      };

  factory ExtractedHealth.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ExtractedHealth();
    DateTime? p(String? s) {
      if (s == null || s.isEmpty) return null;
      try { return DateTime.parse(s); } catch (_) { return null; }
    }
    return ExtractedHealth(
      petName: j['pet_name']?.toString(),
      clinic: j['clinic']?.toString(),
      vet: j['vet']?.toString(),
      visitDate: p(j['visit_date']?.toString()),
      nextVisit: p(j['next_visit']?.toString()),
      diagnosis: j['diagnosis']?.toString(),
      vaccines: (j['vaccines'] as List?)
              ?.map((e) => ExtractedVaccine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      medications: (j['medications'] as List?)
              ?.map((e) => ExtractedMed.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cost: (j['cost'] as num?)?.toDouble(),
    );
  }

  bool get isEmpty =>
      petName == null && clinic == null && visitDate == null &&
      vaccines.isEmpty && medications.isEmpty && diagnosis == null;
}

class ExtractedVaccine {
  final String name;
  final DateTime? givenOn;
  final DateTime? nextDue;
  const ExtractedVaccine({required this.name, this.givenOn, this.nextDue});

  Map<String, dynamic> toJson() => {
        'name': name,
        'given_on': givenOn?.toIso8601String(),
        'next_due': nextDue?.toIso8601String(),
      };
  factory ExtractedVaccine.fromJson(Map<String, dynamic> j) {
    DateTime? p(String? s) {
      if (s == null || s.isEmpty) return null;
      try { return DateTime.parse(s); } catch (_) { return null; }
    }
    return ExtractedVaccine(
      name: (j['name'] ?? '').toString(),
      givenOn: p(j['given_on']?.toString()),
      nextDue: p(j['next_due']?.toString()),
    );
  }
}

class ExtractedMed {
  final String name;
  final String? dosage;
  final String? frequency;
  const ExtractedMed({required this.name, this.dosage, this.frequency});

  Map<String, dynamic> toJson() => {
        'name': name, 'dosage': dosage, 'frequency': frequency,
      };
  factory ExtractedMed.fromJson(Map<String, dynamic> j) => ExtractedMed(
        name: (j['name'] ?? '').toString(),
        dosage: j['dosage']?.toString(),
        frequency: j['frequency']?.toString(),
      );
}

class PetDocument extends Equatable {
  final String id;
  final String petId;
  final DocType type;
  final String title;
  final String documentUrl;
  final String? thumbnailUrl;
  final String? notes;
  final String? capturedText;
  final ExtractedHealth captured;
  final bool isImage;
  final DateTime createdAt;

  const PetDocument({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.documentUrl,
    this.thumbnailUrl,
    this.notes,
    this.capturedText,
    this.captured = const ExtractedHealth(),
    this.isImage = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'type': type.wireName,
        'title': title,
        'document_url': documentUrl,
        'thumbnail_url': thumbnailUrl,
        'notes': notes,
        'captured_text': capturedText,
        'captured_data': captured.toJson(),
        'is_image': isImage,
        'created_at': createdAt.toIso8601String(),
      };

  factory PetDocument.fromJson(Map<String, dynamic> json) => PetDocument(
        id: json['id'],
        petId: json['pet_id'],
        type: DocTypeX.fromWire(json['type']),
        title: json['title'] ?? '',
        documentUrl: json['document_url'] ?? '',
        thumbnailUrl: json['thumbnail_url'],
        notes: json['notes'],
        capturedText: json['captured_text'],
        captured: ExtractedHealth.fromJson(
            (json['captured_data'] as Map?)?.cast<String, dynamic>()),
        isImage: json['is_image'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
      );

  @override
  List<Object?> get props => [id, petId, type, title, documentUrl, createdAt];
}
