import 'package:flutter/material.dart';

// Một key dùng chung để SnackBar vẫn hiện khi thay màn hình Login -> Home.
final GlobalKey<ScaffoldMessengerState> thongBaoKey =
    GlobalKey<ScaffoldMessengerState>();

void hienThongBao(String noiDung, {bool loi = false}) {
  final messenger = thongBaoKey.currentState;
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Text(noiDung),
      backgroundColor: loi ? const Color(0xFFC43D42) : const Color(0xFF2454DA),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

const mauXanh = Color(0xFF365CE3);
const mauNen = Color(0xFFF6F7FB);
