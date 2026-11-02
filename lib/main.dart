import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Do flutterfire configure sinh ra (không có sẵn trong ZIP).
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/ui_helpers.dart';
import 'services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Tải lời động viên từ Firebase Remote Config
try {
  await RemoteConfigService.khoiTao();
} catch (e) {
  debugPrint('Không tải được Remote Config: $e');
}
  runApp(const UthTodoApp());
}

class UthTodoApp extends StatelessWidget {
  const UthTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTH Todo',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: thongBaoKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: mauXanh),
        scaffoldBackgroundColor: mauNen,
        appBarTheme: const AppBarTheme(backgroundColor: mauNen),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
      home: const CongXacThuc(),
    );
  }
}

// StreamBuilder tự đổi Login <-> Home khi Firebase thay trạng thái đăng nhập.
class CongXacThuc extends StatelessWidget {
  const CongXacThuc({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Lỗi xác thực: ${snapshot.error}')));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return HomeScreen(key: ValueKey(user.uid), user: user);
      },
    );
  }
}
