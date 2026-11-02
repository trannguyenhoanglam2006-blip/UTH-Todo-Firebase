import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/todo_task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../utils/ui_helpers.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<List<TodoTask>> _tasks;
  bool _busy = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _tasks = TaskService().watchTasks(widget.uid);
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: AuthService.instance.currentUser?.displayName ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa tên hiển thị'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tên của bạn'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Lưu')),
        ],
      ),
    );
    // Dialog đã đóng rồi thì mới giải phóng bộ nhớ của TextEditingController.
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await AuthService.instance.updateName(name);
      if (mounted) setState(() {});
      hienThongBao('Đã cập nhật tên!');
    } catch (e) {
      hienThongBao('Không sửa được tên: $e', loi: true);
    }
  }

  Future<void> _enableFcm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final token = await NotificationService.enableAndroid(thongBaoKey);
      if (mounted) setState(() => _fcmToken = token);
      hienThongBao('Đã kích hoạt FCM. Bạn có thể gửi thông báo thử từ Firebase.');
    } catch (e) {
      hienThongBao('FCM: $e', loi: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthService.instance.logout();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      hienThongBao('Đã đăng xuất.');
    } catch (e) {
      hienThongBao('Không đăng xuất được: $e', loi: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService.instance.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName! : (user?.email?.split('@').first ?? user?.phoneNumber ?? 'Người dùng');
    final contact = user?.email ?? user?.phoneNumber ?? 'Chưa có email';

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Column(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFE8ECFF),
                    child: Text(name.isEmpty ? 'U' : name[0].toUpperCase(),
                        style: const TextStyle(color: mauXanh,
                            fontWeight: FontWeight.bold, fontSize: 28)),
                  ),
                  const SizedBox(height: 12),
                  Text(name, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(contact, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  const Text('Đã đăng nhập với Firebase',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                  TextButton.icon(onPressed: _busy ? null : _editName,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Chỉnh sửa tên')),
                ]),
              ),
              const SizedBox(height: 15),
              StreamBuilder<List<TodoTask>>(
                stream: _tasks,
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  final done = tasks.where((t) => t.isDone).length;
                  final pending = tasks.length - done;
                  return Row(children: [
                    Expanded(child: _statCard('${tasks.length}', 'Tổng việc')),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('$done', 'Đã xong')),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('$pending', 'Đang chờ')),
                  ]);
                },
              ),
              const SizedBox(height: 24),
              const Text('Cài đặt', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: mauXanh),
                  title: const Text('Bật thông báo FCM'),
                  subtitle: const Text('Lấy token để gửi thông báo thử'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : _enableFcm,
                ),
              ),
              if (_fcmToken != null) ...[
                const SizedBox(height: 8),
                const Text('FCM token (chỉ dùng để kiểm thử):',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                SelectableText(_fcmToken!, style: const TextStyle(fontSize: 11)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ]),
  );
}
