class ProfileProgress {
  const ProfileProgress({required this.level, required this.exp});

  factory ProfileProgress.fromProfile(Map<String, dynamic>? profile) {
    final rawLevel = (profile?['level'] as num?)?.toInt() ?? 1;
    final rawExp = (profile?['exp'] as num?)?.toInt() ?? 0;
    return ProfileProgress(
      level: rawLevel < 1 ? 1 : rawLevel,
      exp: rawExp < 0 ? 0 : rawExp,
    );
  }

  final int level;
  final int exp;

  int get target => level * 1000;
  double get fraction => (exp / target).clamp(0.0, 1.0);
  int get remaining => (target - exp).clamp(0, target);
}
