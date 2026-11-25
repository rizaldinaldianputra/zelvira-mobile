class UserModel {
  final int id;
  final String email;
  final String? fullName;
  final String? profilePicture;
  final List<String>? roles;
  final String? avatarUrl;
  final String? phoneNumber;
  final int points;
  final double balance;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.profilePicture,
    this.roles,
    this.avatarUrl,
    this.phoneNumber,
    this.points = 0,
    this.balance = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] as String?,
      profilePicture: json['profilePicture'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),
      points: json['points'] ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (fullName != null) 'fullName': fullName,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (roles != null) 'roles': roles,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'points': points,
      'balance': balance,
    };
  }
}
