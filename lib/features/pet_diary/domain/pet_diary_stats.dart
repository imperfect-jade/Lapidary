/// Daily behavior statistics used to generate one pet diary entry.
class PetDiaryStats {
  const PetDiaryStats({
    required this.completedTaskCount,
    required this.focusMinutes,
    required this.focusSessionCount,
    required this.lateNightTaskCount,
  });

  /// Number of tasks completed on this date.
  final int completedTaskCount;

  /// Total completed focus minutes on this date.
  final int focusMinutes;

  /// Number of completed focus sessions on this date.
  final int focusSessionCount;

  /// Number of tasks completed at or after 21:00 on this date.
  final int lateNightTaskCount;

  /// Whether there is enough user activity to generate a meaningful diary.
  bool get hasSourceData => completedTaskCount > 0 || focusSessionCount > 0;
}
