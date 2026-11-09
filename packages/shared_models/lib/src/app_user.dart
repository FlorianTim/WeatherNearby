class AppUser {
  AppUser({required this.id, required this.displayName});

  final String id;
  final String displayName;

  Map<String, Object?> toJson() => {'id': id, 'displayName': displayName};

  factory AppUser.fromJson(Map<String, Object?> json) {
    return AppUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
    );
  }
}
