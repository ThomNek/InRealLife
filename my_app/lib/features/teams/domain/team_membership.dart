/// Nguồn quyết định phía giao diện cho quyền chat đội.
///
/// Đây chỉ là UX để đóng màn hình sớm khi membership đổi. Supabase RLS/RPC vẫn
/// là lớp bảo mật bắt buộc và không tin kết quả tính ở client.
bool hasJoinedTeamMembership(Iterable<Map<String, dynamic>> memberships) {
  return memberships.any((row) => row['status'] == 'joined');
}
