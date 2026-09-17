class UserModel {
  final int id;
  final String email;
  final String role;
  final String token;
  final String targetDashboard;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
    required this.targetDashboard,
  });

  // Factory to create a User instance from Laravel JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user']['id'],
      email: json['user']['email'],
      role: json['role'],
      token: json['token'],
      targetDashboard: json['target_dashboard'],
    );
  }
}