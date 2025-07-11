class AppUser {
  final String id;
  final String email;
  final String username;

  AppUser({required this.id, required this.email, required this.username});

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(id: id, email: data['email'], username: data['username']);
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'username': username};
  }
}
