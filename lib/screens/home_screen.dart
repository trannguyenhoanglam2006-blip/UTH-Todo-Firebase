import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/todo_task.dart';
import '../services/task_service.dart';
import '../utils/date_helpers.dart';
import '../utils/ui_helpers.dart';
import '../widgets/task_editor_sheet.dart';
import 'profile_screen.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _taskService = TaskService();
  late final Stream<List<TodoTask>> _taskStream;
  bool _showAll = false;
  String _filter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _taskStream = _taskService.watchTasks(widget.user.uid);
  }

  String get _name {
    final display = widget.user.displayName;
    if (display != null && display.trim().isNotEmpty) return display.trim();
    return widget.user.email?.split('@').first ?? widget.user.phoneNumber ?? 'Bạn';
  }

  String get _initial => _name.isEmpty ? 'U' : _name[0].toUpperCase();

  Future<void> _openEditor([TodoTask? task]) async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskEditorSheet(original: task),
    );
    if (draft == null) return;
    try {
      if (task == null) {
  // Bước 1: Lưu công việc lên Firestore
  await _taskService.addTask(
    widget.user.uid,
    title: draft.title,
    category: draft.category,
    dueDate: draft.dueDate,
  );

  // Bước 2: Ghi nhận sự kiện Analytics
  try {
    await AnalyticsService.themCongViec();
  } catch (e) {
    debugPrint('Không thể ghi Analytics: $e');
  }
} else {
        await _taskService.editTask(
          widget.user.uid, task.id,
          title: draft.title,
          category: draft.category,
          dueDate: draft.dueDate,
        );
      }
      hienThongBao(task == null ? 'Đã thêm công việc!' : 'Đã cập nhật công việc!');
    } catch (e) {
      hienThongBao('Không thể lưu công việc: $e', loi: true);
    }
  }

  
Future<void> _setDone(TodoTask task, bool done) async {
  try {
    // Bước 1: Cập nhật trạng thái công việc trên Firestore
    await _taskService.setDone(widget.user.uid, task, done);

    // Bước 2: Chỉ ghi Analytics khi chuyển sang hoàn thành
    if (done && !task.isDone) {
      try {
        await AnalyticsService.hoanThanhCongViec();
      } catch (e) {
        debugPrint('Không thể ghi Analytics: $e');
      }
    }
  } catch (e) {
    hienThongBao('Không cập nhật được: $e', loi: true);
  }
}

  Future<void> _delete(TodoTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('Bạn muốn xóa "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _taskService.deleteTask(widget.user.uid, task.id);
      hienThongBao('Đã xóa công việc.');
    } catch (e) {
      hienThongBao('Không xóa được: $e', loi: true);
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(uid: widget.user.uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: 'Thêm công việc',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _showAll ? 1 : 0,
        onDestinationSelected: (index) {
          if (index == 2) {
            _openProfile();
          } else {
            setState(() {
              _showAll = index == 1;
              _filter = 'Tất cả';
            });
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Danh sách'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: StreamBuilder<List<TodoTask>>(
              stream: _taskStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text('Lỗi Firestore: ${snapshot.error}\nKiểm tra Rules và kết nối mạng.'),
                  ));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _content(snapshot.data!);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(List<TodoTask> tasks) {
    final now = DateTime.now();
    final today = tasks.where((t) => cungNgay(t.dueDate, now)).toList();
    final done = today.where((t) => t.isDone).length;
    final total = today.length;
    // Ví dụ: 2 / 4 = 0.5 = 50%. Không có task -> 0%.
    final progress = total == 0 ? 0.0 : done / total;
    final learning = tasks.where((t) => t.category == 'Học tập' && !t.isDone).length;
    final living = tasks.where((t) => t.category == 'Cuộc sống' && !t.isDone).length;
    final filtered = tasks.where((t) => _filter == 'Tất cả' || t.category == _filter).toList();
    final visible = _showAll ? filtered : today;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 92),
      children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE7EBFF),
            child: Text(_initial, style: const TextStyle(fontWeight: FontWeight.bold, color: mauXanh)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hôm nay, ${hienThiNgay(now)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Chào $_name!', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
          IconButton(
            onPressed: _openProfile,
            tooltip: 'Thông tin cá nhân',
            icon: const Icon(Icons.account_circle_outlined, size: 29),
          ),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: mauXanh,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiến độ hôm nay',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 7),
                Text('$done/$total việc',
                    style: const TextStyle(color: Colors.white, fontSize: 29,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
  total == 0
      ? 'Thêm công việc đầu tiên!'
      : RemoteConfigService.layLoiDongVien(),
  style: const TextStyle(
    color: Colors.white,
    fontSize: 12,
  ),
),
              ],
            )),
            SizedBox(
              height: 78,
              width: 78,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: Colors.white,
                  backgroundColor: Colors.white30,
                  strokeCap: StrokeCap.round,
                )),
                Text('${(progress * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 19,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 23),
        if (!_showAll) ...[
          Row(children: [
            Expanded(child: _categoryCard(
              'Học tập', '$learning việc còn lại', Icons.school_outlined,
              const Color(0xFFEAF0FF), mauXanh,
            )),
            const SizedBox(width: 12),
            Expanded(child: _categoryCard(
              'Cuộc sống', '$living việc còn lại', Icons.home_outlined,
              const Color(0xFFFFF0E3), const Color(0xFFB8753C),
            )),
          ]),
          const SizedBox(height: 24),
          _weekCard(tasks, now),
          const SizedBox(height: 24),
        ] else ...[
          Wrap(spacing: 8, children: [
            for (final category in ['Tất cả', 'Học tập', 'Cuộc sống'])
              ChoiceChip(
                label: Text(category),
                selected: _filter == category,
                onSelected: (_) => setState(() => _filter = category),
              ),
          ]),
          const SizedBox(height: 15),
        ],
        Row(children: [
          Expanded(child: Text(_showAll ? 'Danh sách công việc' : 'Việc hôm nay',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          if (!_showAll) TextButton(
            onPressed: () => setState(() => _showAll = true),
            child: const Text('Xem tất cả'),
          ),
        ]),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Column(children: [
              Icon(Icons.event_note_outlined, color: mauXanh, size: 40),
              SizedBox(height: 8),
              Text('Chưa có công việc trong mục này.'),
              Text('Nhấn nút + để thêm công việc.', style: TextStyle(color: Colors.black54)),
            ]),
          )
        else
          for (final task in visible) _taskTile(task),
      ],
    );
  }

  Widget _categoryCard(String title, String detail, IconData icon, Color bg, Color color) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() {
          _showAll = true;
          _filter = title;
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 11),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _weekCard(List<TodoTask> tasks, DateTime now) {
    final start = dauTuan(now);
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final completedPerDay = days.map((day) => tasks.where((task) =>
        task.isDone && task.completedAt != null &&
        cungNgay(task.completedAt!, day)).length).toList();
    final highest = max(1, completedPerDay.reduce(max));
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tuần này', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Số việc được hoàn thành mỗi ngày',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${completedPerDay[i]}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 5),
                Container(
                  width: 20,
                  height: max(5.0, 68.0 * completedPerDay[i] / highest),
                  decoration: BoxDecoration(
                    color: cungNgay(days[i], now) ? mauXanh : const Color(0xFFA3B7FC),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 7),
                Text(labels[i], style: const TextStyle(fontSize: 11)),
              ])),
          ]),
        ),
      ]),
    );
  }

  Widget _taskTile(TodoTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Checkbox(
            value: task.isDone,
            onChanged: (v) => _setDone(task, v ?? false),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  color: task.isDone ? Colors.black45 : Colors.black87,
                )),
            const SizedBox(height: 3),
            Text('${task.category} • ${hienThiNgay(task.dueDate)}',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ])),
          IconButton(
            tooltip: 'Sửa', onPressed: () => _openEditor(task),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Xóa', onPressed: () => _delete(task),
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
          ),
        ]),
      ),
    );
  }
}
