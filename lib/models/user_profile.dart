class UserProfile {
  final String id;
  final String email;
  final String? name;
  final int dailyGoal; // in minutes
  final int streak;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.dailyGoal = 120,
    this.streak = 0,
  });
}
