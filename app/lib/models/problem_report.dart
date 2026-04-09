import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ProblemCategory { flood, trash, traffic, infrastructure, other }

enum ProblemStatus { pending, inProgress, resolved }

enum ProblemSource { user, government, urgent }

class ProblemReport {
  final String id;
  final String title;
  final String description;
  final ProblemCategory category;
  final ProblemStatus status;
  final ProblemSource source;
  final LatLng location;
  final String address;
  final DateTime createdAt;
  final String reportedBy;
  final List<String> imageUrls;

  const ProblemReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.source,
    required this.location,
    required this.address,
    required this.createdAt,
    required this.reportedBy,
    this.imageUrls = const [],
  });

  factory ProblemReport.fromJson(Map<String, dynamic> json) {
    return ProblemReport(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['category'] ?? ''),
      status: _parseStatus(json['status'] ?? ''),
      source: _parseSource(json['source'] ?? ''),
      location: LatLng(
        (json['lat'] as num?)?.toDouble() ?? 0,
        (json['lng'] as num?)?.toDouble() ?? 0,
      ),
      address: json['address'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      reportedBy: json['owner_id'] ?? '',
      imageUrls: (json['image_ids'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': _categoryToString(category),
    'source': _sourceToString(source),
    'lat': location.latitude,
    'lng': location.longitude,
    'address': address,
  };

  static ProblemCategory _parseCategory(String s) => switch (s) {
    'flood' => ProblemCategory.flood,
    'trash' => ProblemCategory.trash,
    'traffic' => ProblemCategory.traffic,
    'infrastructure' => ProblemCategory.infrastructure,
    _ => ProblemCategory.other,
  };

  static ProblemStatus _parseStatus(String s) => switch (s) {
    'in_progress' => ProblemStatus.inProgress,
    'resolved' => ProblemStatus.resolved,
    _ => ProblemStatus.pending,
  };

  static ProblemSource _parseSource(String s) => switch (s) {
    'government' => ProblemSource.government,
    'urgent' => ProblemSource.urgent,
    _ => ProblemSource.user,
  };

  static String _categoryToString(ProblemCategory c) => switch (c) {
    ProblemCategory.flood => 'flood',
    ProblemCategory.trash => 'trash',
    ProblemCategory.traffic => 'traffic',
    ProblemCategory.infrastructure => 'infrastructure',
    ProblemCategory.other => 'other',
  };

  static String _sourceToString(ProblemSource s) => switch (s) {
    ProblemSource.user => 'user',
    ProblemSource.government => 'government',
    ProblemSource.urgent => 'urgent',
  };

  String get categoryLabel {
    switch (category) {
      case ProblemCategory.flood:
        return 'น้ำท่วม';
      case ProblemCategory.trash:
        return 'ขยะ';
      case ProblemCategory.traffic:
        return 'การจราจร';
      case ProblemCategory.infrastructure:
        return 'โครงสร้างพื้นฐาน';
      case ProblemCategory.other:
        return 'อื่นๆ';
    }
  }

  String get statusLabel {
    switch (status) {
      case ProblemStatus.pending:
        return 'รอดำเนินการ';
      case ProblemStatus.inProgress:
        return 'กำลังดำเนินการ';
      case ProblemStatus.resolved:
        return 'แก้ไขแล้ว';
    }
  }

  String get sourceLabel {
    switch (source) {
      case ProblemSource.user:
        return 'ผู้ใช้';
      case ProblemSource.government:
        return 'ภาครัฐ';
      case ProblemSource.urgent:
        return 'เร่งด่วน';
    }
  }
}
