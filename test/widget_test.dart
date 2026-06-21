import 'package:flutter_test/flutter_test.dart';
import 'package:community_report/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CommunityReportApp());
    expect(find.text('แจ้งปัญหาชุมชน'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });
}
