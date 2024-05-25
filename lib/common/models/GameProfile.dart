class GameProfile {
  final int ageRating;
  final String appHostUrl;
  final String description;
  final String displayName;
  final String gameName;
  final List<String> gameTags;
  final String packageId;
  final String iconUrl;

  GameProfile({
    required this.ageRating,
    required this.appHostUrl,
    required this.description,
    required this.displayName,
    required this.gameName,
    required this.gameTags,
    required this.packageId,
    required this.iconUrl,
  });

  factory GameProfile.fromJson(Map<String, dynamic> json) {
    return GameProfile(
      ageRating: json['age_rating'],
      appHostUrl: json['app_host_url'],
      description: json['description'],
      displayName: json['display_name'],
      gameName: json['game_name'],
      gameTags: List<String>.from(json['game_tags']),
      packageId: json['package_id'],
      iconUrl: json['iconUrl'],
    );
  }
}
