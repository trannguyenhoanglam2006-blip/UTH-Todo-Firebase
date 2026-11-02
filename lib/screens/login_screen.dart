import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/ui_helpers.dart';
import '../services/analytics_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController(text: '+84');
  final _otp = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  bool _register = false;
  bool _phoneMode = false;
  bool _otpSent = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  // Dùng chung cho các thao tác bất đồng bộ để hiển thị đang tải/lỗi.
  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      hienThongBao(success);
    } catch (e) {
      hienThongBao(AuthService.instance.moTaLoi(e), loi: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  
Future<void> _emailSubmit() async {
  if (!_formKey.currentState!.validate()) return;

  await _run(
    () async {
      if (_register) {
        // Đăng ký tài khoản mới
        await AuthService.instance.registerEmail(
          _email.text,
          _password.text,
        );
      } else {
        // Đăng nhập tài khoản có sẵn
        await AuthService.instance.loginEmail(
          _email.text,
          _password.text,
        );

        // Ghi nhận sự kiện đăng nhập thành công
        await AnalyticsService.dangNhap('email');
      }
    },
    _register ? 'Tạo tài khoản thành công!' : 'Đăng nhập thành công!',
  );
}


  Future<void> _sendOtp() async {
    if (!_phone.text.trim().startsWith('+') || _phone.text.trim().length < 9) {
      hienThongBao('Nhập số theo dạng quốc tế, ví dụ +84912345678.', loi: true);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthService.instance.sendOtp(
        phone: _phone.text,
        onCodeSent: () {
          if (mounted) setState(() => _otpSent = true);
          hienThongBao('Đã yêu cầu mã OTP. Nhập mã để xác thực.');
        },
        onError: (error) => hienThongBao(error, loi: true),
        onAutoVerified: () =>
            hienThongBao('Xác minh số điện thoại thành công!'),
      );
    } catch (e) {
      hienThongBao(AuthService.instance.moTaLoi(e), loi: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 38, 26, 26),
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: mauXanh,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: mauXanh.withValues(alpha: 0.22),
                            blurRadius: 18)
                      ],
                    ),
                    child: const Icon(Icons.checklist_rounded,
                        color: Colors.white, size: 42),
                  ),
                ),
                const SizedBox(height: 25),
                const Text('Chào mừng đến với UTH Todo',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Quản lý công việc và đồng bộ trên Firebase',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 35),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false,
                        icon: Icon(Icons.email_outlined),
                        label: Text('Email')),
                    ButtonSegment(
                        value: true,
                        icon: Icon(Icons.phone_android),
                        label: Text('Điện thoại')),
                  ],
                  selected: {_phoneMode},
                  onSelectionChanged: _busy
                      ? null
                      : (values) {
                          setState(() => _phoneMode = values.first);
                        },
                ),
                const SizedBox(height: 24),
                if (!_phoneMode) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Nhập địa chỉ email hợp lệ'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mật khẩu phải có tối thiểu 6 ký tự'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _emailSubmit,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: Text(_register ? 'Tạo tài khoản' : 'Đăng nhập'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký ngay'),
                  ),
                  const SizedBox(height: 10),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('hoặc')),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy
                    ? null
                    : () => _run(
                      () async {
                        // Đăng nhập bằng Google
                        await AuthService.instance.loginGoogle();
                        // Ghi nhận sự kiện trên Firebase Analytics
                        await AnalyticsService.dangNhap('google');
                        },
                        'Đăng nhập bằng Google thành công!',
                        ),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Tiếp tục với Google'),
                  ),
                ] else ...[
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại (+84...)',
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _sendOtp,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: const Text('Gửi mã OTP'),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 18),
                    TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                          labelText: 'Nhập mã OTP (6 số)'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _busy
                      ? null
                      : () => _run(
                        () async {
                          // Kiểm tra mã OTP với Firebase
                          await AuthService.instance.verifyOtp(_otp.text);
                          // Ghi nhận sự kiện đăng nhập bằng số điện thoại
                          await AnalyticsService.dangNhap('phone');
                          },
                          'Đăng nhập số điện thoại thành công!',
                          ),

                      child: const Text('Xác nhận OTP'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                      'Firebase có thể yêu cầu reCAPTCHA. Với bài thực hành, nên dùng số thử nghiệm trên Console.',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
                if (_busy) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
