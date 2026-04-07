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

// Sample data for demo
final List<ProblemReport> sampleProblems = [
  ProblemReport(
    id: '1',
    title: 'น้ำท่วมถนนหลัก',
    description:
        'น้ำท่วมสูงประมาณ 30 ซม. บริเวณถนนพหลโยธิน ใกล้แยกเกษตร ทำให้การจราจรติดขัดมาก รถเล็กไม่สามารถผ่านได้',
    category: ProblemCategory.flood,
    status: ProblemStatus.inProgress,
    source: ProblemSource.urgent,
    location: const LatLng(13.8446, 100.5714),
    address: 'ถนนพหลโยธิน แยกเกษตร',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    reportedBy: 'นักเรียน 65012345',
    imageUrls: ['https://picsum.photos/400/300?random=1'],
  ),
  ProblemReport(
    id: '2',
    title: 'ขยะกองใหญ่ริมทาง',
    description:
        'มีขยะกองใหญ่สะสมบริเวณซอยลาดพร้าว 71 ส่งกลิ่นเหม็นรบกวนชาวบ้านในพื้นที่',
    category: ProblemCategory.trash,
    status: ProblemStatus.pending,
    source: ProblemSource.user,
    location: const LatLng(13.8100, 100.5800),
    address: 'ซอยลาดพร้าว 71',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    reportedBy: 'หน่วยงาน',
    imageUrls: ['https://picsum.photos/400/300?random=2'],
  ),
  ProblemReport(
    id: '3',
    title: 'ไฟถนนเสีย 5 ดวง',
    description:
        'ไฟถนนเสียต่อเนื่อง 5 ดวง บริเวณถนนรัชดาภิเษก ช่วงหน้า MRT ลาดพร้าว ทำให้มืดมากในเวลากลางคืน',
    category: ProblemCategory.infrastructure,
    status: ProblemStatus.resolved,
    source: ProblemSource.government,
    location: const LatLng(13.8050, 100.5620),
    address: 'ถนนรัชดาภิเษก หน้า MRT ลาดพร้าว',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    reportedBy: 'ครูประจำ',
    imageUrls: ['https://picsum.photos/400/300?random=3'],
  ),
  ProblemReport(
    id: '4',
    title: 'สัญญาณไฟจราจรขัดข้อง',
    description:
        'สัญญาณไฟจราจรบริเวณแยกรัชโยธิน ไฟเขียวเปิดเพียง 5 วินาที ทำให้รถติดยาวมาก',
    category: ProblemCategory.traffic,
    status: ProblemStatus.pending,
    source: ProblemSource.user,
    location: const LatLng(13.8380, 100.5690),
    address: 'แยกรัชโยธิน',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    reportedBy: 'นักเรียน 65099887',
    imageUrls: ['https://picsum.photos/400/300?random=4'],
  ),
  ProblemReport(
    id: '5',
    title: 'ท่อระบายน้ำอุดตัน',
    description:
        'ท่อระบายน้ำอุดตันบริเวณปากซอยวิภาวดี 20 เมื่อฝนตกน้ำจะท่วมขังทุกครั้ง',
    category: ProblemCategory.flood,
    status: ProblemStatus.inProgress,
    source: ProblemSource.government,
    location: const LatLng(13.8300, 100.5550),
    address: 'ปากซอยวิภาวดี 20',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    reportedBy: 'เทศบาล',
    imageUrls: ['https://picsum.photos/400/300?random=5'],
  ),
];
