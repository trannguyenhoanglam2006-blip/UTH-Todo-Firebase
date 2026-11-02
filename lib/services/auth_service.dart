import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Service: các thao tác xác thực với Firebase Authentication.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleReady = false;
  String? _verificationId;
  ConfirmationResult? _webConfirmation;

  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> loginEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> loginGoogle() async {
    if (kIsWeb) {
      // Web sử dụng cửa sổ popup do Firebase Auth quản lý.
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    // google_sign_in phiên bản 7: phải initialize trước authenticate.
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final googleAuth = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> sendOtp({
    required String phone,
    required VoidCallback onCodeSent,
    required ValueChanged<String> onError,
    required VoidCallback onAutoVerified,
  }) async {
    _verificationId = null;
    _webConfirmation = null;
    if (kIsWeb) {
      // Trên web, Firebase hiện reCAPTCHA trước khi gửi mã OTP.
      _webConfirmation = await _auth.signInWithPhoneNumber(phone.trim());
      onCodeSent();
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phone.trim(),
      verificationCompleted: (credential) async {
        // Android có thể tự đọc và xác thực OTP.
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified();
        } catch (e) {
          onError(moTaLoi(e));
        }
      },
      verificationFailed: (e) => onError(moTaLoi(e)),
      codeSent: (id, resendToken) {
        _verificationId = id;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  Future<void> verifyOtp(String code) async {
    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) throw StateError('Bạn cần gửi OTP trước.');
      await confirmation.confirm(code.trim());
      return;
    }
    final id = _verificationId;
    if (id == null) throw StateError('Bạn cần gửi OTP trước.');
    final credential = PhoneAuthProvider.credential(
      verificationId: id,
      smsCode: code.trim(),
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> updateName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
  }

  Future<void> logout() async {
    await _auth.signOut();
    // Đăng xuất Google SDK để lần đăng nhập sau có thể chọn tài khoản lại.
    if (!kIsWeb && _googleReady) {
      await GoogleSignIn.instance.signOut();
    }
  }

  String moTaLoi(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email': return 'Địa chỉ email không hợp lệ.';
        case 'invalid-credential': return 'Email hoặc mật khẩu không đúng.';
        case 'user-not-found': return 'Không tìm thấy tài khoản.';
        case 'wrong-password': return 'Mật khẩu không chính xác.';
        case 'email-already-in-use': return 'Email này đã được đăng ký.';
        case 'weak-password': return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
        case 'operation-not-allowed': return 'Firebase: ${error.message} (Mã lỗi: ${error.code})';
        case 'invalid-phone-number': return 'Số điện thoại không hợp lệ. Hãy nhập +84...';
        case 'invalid-verification-code': return 'Mã OTP không chính xác.';
        case 'too-many-requests': return 'Thao tác quá nhiều lần, hãy thử lại sau.';
        case 'network-request-failed': return 'Không có kết nối mạng.';
        case 'popup-closed-by-user': return 'Bạn đã đóng cửa sổ đăng nhập.';
        default: return '${error.message ?? error.code} (${error.code})';
      }
    }
    return error.toString();
  }
}
