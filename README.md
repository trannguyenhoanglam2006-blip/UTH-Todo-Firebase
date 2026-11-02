# UTH Todo — Flutter + Firebase (BT về nhà 01 và 02)

Bộ source được viết cho Flutter mới (Dart 3.6+), với chú thích tiếng Việt.
- BT01: Đăng nhập Email/Mật khẩu, Google, Số điện thoại (OTP); báo lỗi/thành công; màn Home; Profile; đăng xuất.
- BT02: Firestore CRUD realtime, danh mục Học tập/Cuộc sống, tiến độ theo ngày/tuần; FCM cơ bản cho Android.
- **Không có dữ liệu Firebase giả**: mỗi tài khoản có danh sách công việc riêng ở `users/{uid}/tasks/{taskId}`.

> LƯU Ý: Đây là **bộ mã nguồn để ghép vào Flutter project**, không phải toàn bộ scaffold do `flutter create` sinh ra. Không có `lib/firebase_options.dart` vì mỗi người dùng có Firebase project ID/API config riêng. Bạn bắt buộc chạy `flutterfire configure` trên máy mình để tạo file đó. Mã chưa thể biên dịch/kiểm thử thực tế trong môi trường tạo ZIP vì môi trường này không có Flutter SDK.

## A. Tạo dự án mới trên Windows / VS Code

Mở PowerShell trong thư mục bạn muốn làm đồ án:

```powershell
flutter doctor
flutter create --org vn.edu.uth uth_todo
cd uth_todo
code .
```

Giải nén **toàn bộ nội dung ZIP** và chép vào thư mục `uth_todo` vừa tạo, cho phép ghi đè `pubspec.yaml`, `lib` và `test`. Giữ lại các thư mục Android/Web mà `flutter create` sinh ra. **Không** để source bị lồng thành `uth_todo/uth_todo_source/lib`.

```powershell
flutter pub get
```

## B. Tạo Firebase Project

1. Vào https://console.firebase.google.com/ -> **Add project / Create a project** -> đặt tên `UTH Todo` -> tiếp tục tới khi tạo xong.
2. Vào **Build > Authentication > Get started** (hoặc **Security > Authentication** tùy giao diện Console), chọn **Sign-in method**:
   - Bật **Email/Password**.
   - Bật **Google** và chọn email hỗ trợ.
   - Bật **Phone**.
3. Nếu cần thử OTP mà không gửi SMS, trong cấu hình nhà cung cấp **Phone** mở **Phone numbers for testing** -> thêm số giả hợp lệ, ví dụ `+16505553434` / mã `654321` (chọn số khác nếu trùng); không dùng số thật để test. Số test không gửi SMS.
4. Với SMS thật: phải dùng gói **Blaze** (có tài khoản thanh toán), bật **SMS region policy** cho quốc gia hợp lệ và tuân thủ chi phí/hạn mức. Với bài thực hành, dùng test number.
5. Vào **Build > Firestore Database > Create database**, chọn địa điểm gần (nếu có, `asia-southeast1`) và chọn **Production mode**. Không cần tạo collection thủ công.
6. Vào tab **Rules**, thay bằng nội dung `firestore.rules` trong ZIP, sau đó nhấn **Publish**.

### Firestore rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Lý do: account A không được phép đọc/sửa task của account B. Quy tắc này đủ cho demo; ứng dụng thật nên bổ sung xác thực cấu trúc dữ liệu, giới hạn kích thước và App Check.

## C. Kết nối Flutter với Firebase

Cài Firebase CLI và FlutterFire CLI trong PowerShell:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Nếu Windows báo `flutterfire is not recognized`, thêm `C:\Users\<TenUser>\AppData\Local\Pub\Cache\bin` vào PATH, mở PowerShell mới. Bạn cũng có thể chạy `dart pub global run flutterfire_cli:flutterfire configure`.

Tại thư mục `uth_todo` (có `pubspec.yaml`), chạy:

```powershell
flutterfire configure
```

- Chọn Firebase project `UTH Todo` vừa tạo.
- Chọn **Android** và **Web**. Để làm trước trên điện thoại Android, chọn Android cũng được.
- CLI tự đăng ký/mapping ứng dụng và sinh `lib/firebase_options.dart`.
- Chạy lại `flutterfire configure` khi thay đổi nền tảng hoặc các dịch vụ cần cấu hình lại.

**Android package name** khi tạo với lệnh ở trên thường là `vn.edu.uth.uth_todo` — đối chiếu chính xác giá trị `applicationId` trong `android/app/build.gradle.kts` và trên Firebase Console, không phỏng đoán.

**Đặt tên hiển thị ứng dụng:** trong `android/app/src/main/AndroidManifest.xml`, sửa thuộc tính `<application android:label="UTH Todo" ...>`. Nếu chạy Web, sửa thẻ `<title>` của `web/index.html` thành `UTH Todo`. Tên project Dart (`name: uth_todo`) vẫn giữ dấu gạch dưới theo quy tắc Dart.

### Cấu hình dấu vân tay SHA cho Google / Phone trên Android

```powershell
cd android
.\gradlew signingReport
cd ..
```

Sao chép **SHA-1** và **SHA-256** của build `debug`; vào Firebase Console **Project settings > General > Your apps > Android app > Add fingerprint**, thêm cả hai. Sau đó chạy lại `flutterfire configure` và `flutter run`. Khi Google Sign-in trên Android lỗi, kiểm tra cấu hình `google-services.json` và OAuth Web client theo hướng dẫn plugin `google_sign_in_android`.

## D. Chạy app

```powershell
flutter devices
flutter run -d chrome
```

Hoặc cắm điện thoại Android đã bật **Developer options > USB debugging**, kiểm tra `flutter devices`, rồi:

```powershell
flutter run -d <device_id>
```

**Khuyến nghị kiểm tra bài trên Android** để thử Google, OTP và FCM. Trên Chrome, Email/Password + Google + Firestore hoạt động sau khi setup đúng; OTP web yêu cầu reCAPTCHA và cấu hình domain hợp lệ. Chức năng **FCM của bộ source này chỉ thiết lập cho Android**, không bao gồm VAPID/service worker của Web Push. Windows desktop chưa phải nền tảng thử nghiệm của bài.

Nếu xuất bản APK Android ở chế độ release, kiểm tra `android/app/src/main/AndroidManifest.xml` có dòng `<uses-permission android:name="android.permission.INTERNET" />` bên trong `<manifest>` nhưng ở ngoài `<application>`, vì ứng dụng cần mạng để kết nối Firebase. SDK FCM hiện đại tự khai báo `POST_NOTIFICATIONS` qua manifest merge; người dùng vẫn cần cấp quyền thông báo trên Android 13+. 

## E. Kiểm tra 2 bài trước khi nộp

1. Đăng ký với Email/Password -> xuất hiện tài khoản trong **Authentication > Users** và vào Home.
2. Đăng xuất trong Profile -> về Login. Nhập sai mật khẩu -> Snackbar đỏ.
3. Đăng nhập Google -> hiển thị tên/email và vào Home (Android cần SHA).
4. Chọn **Điện thoại** -> dùng số test + OTP -> vào Home.
5. Thêm task "Ôn chương 3", danh mục Học tập, ngày hôm nay. Thêm ba task khác cùng ngày; tick hoàn thành 2 task -> hiện **2/4 việc, 50%**.
6. Mở **Firestore Database > Data** -> thấy đường dẫn `users / UID / tasks / taskId` với thuộc tính thật.
7. Sửa tên task, xóa một task; quan sát màn hình và Firestore thay đổi ngay. Thử thêm task ở một thiết bị và mở cùng account trên một thiết bị khác để quan sát tự đồng bộ.
8. Profile -> **Bật thông báo FCM (Android)** -> cho phép thông báo; lấy token, dùng mục gửi **test message** trong Firebase Messaging Console (nếu tính năng này có trong Console). App mở foreground sẽ hiện Snackbar nếu nhận tin chứa notification.
9. Đăng nhập account khác -> không xem được task của account trước nhờ Firestore Rules.

## F. Giải thích các phần quan trọng để bảo vệ

| Câu hỏi | Câu trả lời ngắn |
|---|---|
| Firebase Authentication dùng làm gì? | Xác minh người dùng, quản lý phiên đăng nhập và cung cấp `uid` riêng cho từng người. |
| `authStateChanges()` là gì? | Stream báo khi trạng thái login/logout thay đổi; `StreamBuilder` tự hiển thị Login hoặc Home. |
| Vì sao có `await`? | Chờ Firebase trả kết quả trước khi báo thành công/thất bại; không chặn giao diện trong lúc đợi. |
| `setState()` làm gì? | Báo Flutter vẽ lại widget khi đổi trạng thái như `_busy`, `_showAll`, `_otpSent`. |
| `TextEditingController` làm gì? | Lấy nội dung người dùng nhập trong TextField. `dispose()` giải phóng controller khi màn hình bị hủy. |
| `snapshots()` khác `get()`? | `get()` lấy dữ liệu một lần; `snapshots()` liên tục phát thay đổi từ Firestore. |
| Vì sao dùng `users/{uid}/tasks`? | Tách dữ liệu theo từng user và dùng Rules kiểm tra `request.auth.uid`. |
| Tính 50% như thế nào? | `done / total * 100`, nếu `total == 0` trả 0%. |
| Thống kê tuần dựa trên đâu? | Khi tick hoàn thành, Firestore lưu `completedAt = FieldValue.serverTimestamp()`; biểu đồ đếm theo ngày hoàn thành trong tuần. |
| FCM là gì? | Firebase Cloud Messaging: server có thể gửi thông báo tới ứng dụng thông qua token thiết bị. |

## G. Cấu trúc mã nguồn

```text
uth_todo/
├── android/                   # flutter create tự sinh
├── web/                       # flutter create tự sinh
├── lib/
│   ├── main.dart              # khởi tạo Firebase và AuthGate
│   ├── firebase_options.dart   # flutterfire configure tự sinh
│   ├── models/
│   │   └── todo_task.dart      # model công việc
│   ├── services/
│   │   ├── auth_service.dart   # Email, Google, OTP, Sign out
│   │   ├── task_service.dart   # CRUD + realtime Firestore
│   │   └── notification_service.dart # FCM Android
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/
│   │   └── task_editor_sheet.dart
│   └── utils/
│       ├── date_helpers.dart
│       └── ui_helpers.dart
├── firestore.rules
├── test/
│   ├── date_helpers_test.dart
│   └── widget_test.dart
└── pubspec.yaml
```

## H. Các lỗi hay gặp

- **Target of URI doesn't exist: `firebase_options.dart`**: chưa chạy thành công `flutterfire configure`.
- **`permission-denied` khi thêm task**: chưa Publish rules; đang chưa đăng nhập; hoặc rules/path không khớp.
- **`operation-not-allowed`**: chưa bật Email/Google/Phone trong Authentication.
- **Google lỗi `ApiException: 10` / `clientConfigurationError`**: kiểm tra package name, SHA-1/SHA-256, OAuth web client, `google-services.json`, rồi rebuild.
- **Phone `BILLING_NOT_ENABLED`**: gửi OTP số thật không có Blaze, chuyển sang số test; đồng thời kiểm tra SMS region policy.
- **`MissingPluginException`**: dừng chạy hoàn toàn rồi chạy `flutter pub get`, `flutter run` lại; hot reload không cài plugin native mới.
- **FCM không có token/không thấy thông báo**: thử Android thật hoặc emulator Google Play, cho phép notification, không chạy Web trong demo FCM. Khi ứng dụng ở foreground, mã hiện Snackbar chứ không tự tạo system notification.
- **Lỗi SDK Android do plugin mới**: cập nhật Android Studio SDK/Gradle theo thông báo của Flutter; tránh hạ phiên bản ngẫu nhiên.

Nguồn tài liệu:
- FlutterFire setup: https://firebase.google.com/docs/flutter/setup
- Firebase Auth Flutter Google: https://firebase.google.com/docs/auth/flutter/federated-auth
- Firebase phone auth Flutter: https://firebase.google.com/docs/auth/flutter/phone-auth
- Cloud Firestore Rules: https://firebase.google.com/docs/rules/rules-and-auth
- FCM Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
