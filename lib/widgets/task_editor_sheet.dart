import 'package:flutter/material.dart';
import '../models/todo_task.dart';
import '../utils/date_helpers.dart';

// Dữ liệu người dùng nhập ở form thêm/sửa công việc.
class TaskDraft {
  final String title;
  final String category;
  final DateTime dueDate;
  TaskDraft(this.title, this.category, this.dueDate);
}

class TaskEditorSheet extends StatefulWidget {
  final TodoTask? original;
  const TaskEditorSheet({super.key, this.original});

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _title;
  late String _category;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.original?.title ?? '');
    _category = widget.original?.category ?? 'Học tập';
    _dueDate = widget.original?.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Ngày cần hoàn thành công việc',
    );
    if (chosen != null && mounted) setState(() => _dueDate = chosen);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa nhập tên công việc.')),
      );
      return;
    }
    Navigator.pop(context, TaskDraft(title, _category, _dueDate));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22, 24, 22, MediaQuery.viewInsetsOf(context).bottom + 25,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.original == null ? 'Thêm công việc' : 'Sửa công việc',
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tên công việc', hintText: 'Ví dụ: Ôn chương 3'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: const [
                DropdownMenuItem(value: 'Học tập', child: Text('Học tập')),
                DropdownMenuItem(value: 'Cuộc sống', child: Text('Cuộc sống')),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'Học tập'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Ngày làm: ${hienThiNgay(_dueDate)}'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Lưu công việc')),
            ),
          ],
        ),
      ),
    );
  }
}
