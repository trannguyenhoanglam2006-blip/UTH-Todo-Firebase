
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  // Lấy đối tượng Firebase Remote Config
  static final FirebaseRemoteConfig remoteConfig =
      FirebaseRemoteConfig.instance;

  // Nội dung mặc định khi chưa lấy được từ Firebase
  static const String loiDongVienMacDinh =
      'Cố gắng hoàn thành mục tiêu nhé!';

  // Khởi tạo và tải cấu hình từ Firebase
  static Future<void> khoiTao() async {
    await remoteConfig.setDefaults({
      'todo_message': loiDongVienMacDinh,
    });

    // Thời gian tối thiểu giữa các lần tải cấu hình
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ),
    );

    // Lấy cấu hình từ Firebase và kích hoạt
    await remoteConfig.fetchAndActivate();
  }

  // Đọc lời động viên đã được cấu hình
  static String layLoiDongVien() {
    return remoteConfig.getString('todo_message');
  }
}
