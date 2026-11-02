// Các hàm về ngày tháng: tách riêng để dùng được ở mọi màn hình.
bool cungNgay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// weekday = 1 là thứ Hai, 7 là Chủ nhật.
DateTime dauTuan(DateTime ngay) =>
    DateTime(ngay.year, ngay.month, ngay.day)
        .subtract(Duration(days: ngay.weekday - 1));

bool trongTuan(DateTime ngay, DateTime homNay) {
  final dau = dauTuan(homNay);
  final cuoi = dau.add(const Duration(days: 7));
  return !ngay.isBefore(dau) && ngay.isBefore(cuoi);
}

String hienThiNgay(DateTime ngay) =>
    '${ngay.day.toString().padLeft(2, '0')}/${ngay.month.toString().padLeft(2, '0')}/${ngay.year}';
