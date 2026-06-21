import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/activity_service.dart';
import 'services/chat_service.dart';
import 'services/image_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/student/student_screen.dart';
import 'screens/teacher/teacher_screen.dart';
import 'screens/organization/organization_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CommunityReportApp());
}

class CommunityReportApp extends StatelessWidget {
  const CommunityReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => ActivityService(auth),
              ),
              ChangeNotifierProvider(
                create: (_) => ChatService(auth),
              ),
              Provider(
                create: (_) => ImageService(auth),
              ),
            ],
            child: MaterialApp(
              title: 'แจ้งปัญหาชุมชน',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.themeData,
              home: const AuthGate(),
            ),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _notificationInitialized = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isLoggedIn && !_notificationInitialized) {
      _notificationInitialized = true;
      NotificationService.instance.init(jwtToken: auth.token);
    }

    debugPrint('>>> AuthGate: isLoggedIn=${auth.isLoggedIn} role="${auth.role}"');
    return switch (auth) {
      _ when !auth.isLoggedIn => const WelcomeScreen(),
      _ when auth.role == 'ครู' => const TeacherScreen(),
      _ when auth.role == 'หน่วยงาน' => const OrganizationScreen(),
      _ => const StudentScreen(),
    };
  }
}
