class UserModel {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? pic;
  final bool isDelivery;
  final bool hasRestaurant;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.pic,
    this.isDelivery = false,
    this.hasRestaurant = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      pic: json['profile_pic'],
      isDelivery: json['is_delivery'] ?? false,
      hasRestaurant: json['has_restaurant'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'pic': pic,
      'is_delivery': isDelivery,
      'has_restaurant': hasRestaurant,
    };
  }
}