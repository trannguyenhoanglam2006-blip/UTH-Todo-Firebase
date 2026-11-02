import 'package:flutter_test/flutter_test.dart';
import 'package:uth_todo/utils/date_helpers.dart';

void main() {
  test('cungNgay chỉ so sánh ngày, không so sánh giờ', () {
    expect(cungNgay(DateTime(2026, 11, 2, 8), DateTime(2026, 11, 2, 23)), true);
    expect(cungNgay(DateTime(2026, 11, 2), DateTime(2026, 11, 3)), false);
  });

  test('dauTuan bắt đầu từ thứ Hai', () {
    expect(dauTuan(DateTime(2026, 11, 8)), DateTime(2026, 11, 2));
  });

  test('trongTuan chỉ tính 7 ngày của tuần hiện tại', () {
    expect(trongTuan(DateTime(2026, 11, 8), DateTime(2026, 11, 2)), true);
    expect(trongTuan(DateTime(2026, 11, 9), DateTime(2026, 11, 2)), false);
  });
}
