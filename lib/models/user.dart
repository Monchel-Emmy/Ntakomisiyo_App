class User {
  final String id;
  final String name;
  final String phone;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'],
      phone: json['phone'],
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'is_admin': isAdmin,
    };
  }
}
