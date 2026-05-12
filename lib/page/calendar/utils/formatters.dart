part of '../calendar.dart';

String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime dt) {
  return '${dt.month}月${dt.day}日 ${_formatTime(dt)}';
}
