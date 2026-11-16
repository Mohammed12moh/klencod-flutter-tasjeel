class Player {
  final String id; // معرف ثابت وفريد (UUID)
  final String name;
  final String normalizedName; // للمطابقة وتجنب تكرار نفس اللاعب بأسماء مختلفة قليلاً
  final String? avatarPath;
  final int wins;
  final int losses;
  final int draws;
  final int totalMatches;
  final bool synced; // هل تمت مزامنته مع Supabase

  Player({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.avatarPath,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalMatches = 0,
    this.synced = false,
  });

  double get winRate => totalMatches == 0 ? 0 : (wins / totalMatches) * 100;

  static String normalize(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Player copyWith({
    String? name,
    String? avatarPath,
    int? wins,
    int? losses,
    int? draws,
    int? totalMatches,
    bool? synced,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      normalizedName: name != null ? Player.normalize(name) : normalizedName,
      avatarPath: avatarPath ?? this.avatarPath,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      totalMatches: totalMatches ?? this.totalMatches,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'normalized_name': normalizedName,
        'avatar_path': avatarPath,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'total_matches': totalMatches,
        'synced': synced ? 1 : 0,
      };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: map['id'] as String,
        name: map['name'] as String,
        normalizedName: map['normalized_name'] as String,
        avatarPath: map['avatar_path'] as String?,
        wins: map['wins'] as int? ?? 0,
        losses: map['losses'] as int? ?? 0,
        draws: map['draws'] as int? ?? 0,
        totalMatches: map['total_matches'] as int? ?? 0,
        synced: (map['synced'] as int? ?? 0) == 1,
      );
}
