class Activity {
  final String id;
  final String teacherId;
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String supervisor;
  final String supervisorPhone;
  final DateTime startAt;
  final DateTime endAt;
  final int maxSlots;
  final List<String> imageIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    this.supervisor = '',
    this.supervisorPhone = '',
    required this.startAt,
    required this.endAt,
    required this.maxSlots,
    this.imageIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      supervisor: json['supervisor'] ?? '',
      supervisorPhone: json['supervisor_phone'] ?? '',
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      maxSlots: json['max_slots'] ?? 0,
      imageIds: (json['image_ids'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'supervisor': supervisor,
    'supervisor_phone': supervisorPhone,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt.toIso8601String(),
    'max_slots': maxSlots,
    'image_ids': imageIds,
  };
}

class Registration {
  final String id;
  final String activityId;
  final String studentId;
  final String status; // registered/submitted/passed/failed
  final DateTime createdAt;
  final Activity? activity;

  Registration({
    required this.id,
    required this.activityId,
    required this.studentId,
    required this.status,
    required this.createdAt,
    this.activity,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] ?? '',
      activityId: json['activity_id'] ?? '',
      studentId: json['student_id'] ?? '',
      status: json['status'] ?? 'registered',
      createdAt: DateTime.parse(json['created_at']),
      activity: json['activity'] != null
          ? Activity.fromJson(json['activity'])
          : null,
    );
  }
}

class Submission {
  final String id;
  final String registrationId;
  final String content;
  final List<String> imageIds;
  final int? score;
  final String feedback;
  final String status; // pending/passed/failed
  final String reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final String studentId;
  final String activityId;

  Submission({
    required this.id,
    required this.registrationId,
    required this.content,
    this.imageIds = const [],
    this.score,
    required this.feedback,
    required this.status,
    required this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.studentId = '',
    this.activityId = '',
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] ?? '',
      registrationId: json['registration_id'] ?? '',
      content: json['content'] ?? '',
      imageIds: (json['image_ids'] as List?)?.cast<String>() ?? [],
      score: json['score'],
      feedback: json['feedback'] ?? '',
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewed_by'] ?? '',
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      studentId: json['student_id'] ?? '',
      activityId: json['activity_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'image_ids': imageIds,
  };
}
