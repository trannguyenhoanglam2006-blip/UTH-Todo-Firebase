
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  // Khởi tạo Firebase Analytics
  static final FirebaseAnalytics analytics =
      FirebaseAnalytics.instance;

  // Ghi nhận khi người dùng đăng nhập
  static Future<void> dangNhap(String phuongThuc) async {
    await analytics.logLogin(
      loginMethod: phuongThuc,
    );
  }

  // Ghi nhận khi người dùng thêm công việc
  static Future<void> themCongViec() async {
    await analytics.logEvent(
      name: 'them_cong_viec',
    );
  }

  // Ghi nhận khi hoàn thành công việc
  static Future<void> hoanThanhCongViec() async {
    await analytics.logEvent(
      name: 'hoan_thanh_cong_viec',
    );
  }
}
