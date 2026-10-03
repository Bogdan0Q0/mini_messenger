/// Инициалы для аватара: первые буквы первых двух слов имени.
/// Для пустого имени возвращает 'U'.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final buf = StringBuffer();
  for (final part in parts.take(2)) {
    if (part.isNotEmpty) buf.write(part[0]);
  }
  final result = buf.toString().toUpperCase();
  return result.isEmpty ? 'U' : result;
}
