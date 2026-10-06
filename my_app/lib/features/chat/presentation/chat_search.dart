/// So khớp không phân biệt hoa/thường và dấu cách thừa cho ô tìm kiếm chat.
/// Đây là hàm thuần nên có thể kiểm thử mà không cần kết nối Supabase.
bool chatSearchMatches(Map<String, dynamic> row, String rawQuery) {
  final query = _normalizeForSearch(rawQuery);
  if (query.isEmpty) return true;

  const searchableFields = [
    'display_name',
    'username',
    'city',
    'last_message',
    'title',
  ];
  return searchableFields.any(
    (field) =>
        _normalizeForSearch(row[field]?.toString() ?? '').contains(query),
  );
}

String _normalizeForSearch(String value) {
  var normalized = value.trim().toLowerCase();
  const replacements = <String, String>{
    '[àáạảãâầấậẩẫăằắặẳẵ]': 'a',
    '[èéẹẻẽêềếệểễ]': 'e',
    '[ìíịỉĩ]': 'i',
    '[òóọỏõôồốộổỗơờớợởỡ]': 'o',
    '[ùúụủũưừứựửữ]': 'u',
    '[ỳýỵỷỹ]': 'y',
    'đ': 'd',
  };
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(RegExp(entry.key), entry.value);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}
