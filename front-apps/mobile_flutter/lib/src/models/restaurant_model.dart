class RestaurantModel {
  final int id;
  final String name;
  final String? description;
  final String? logo;
  final bool isOpen;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  RestaurantModel({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.isOpen = false,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      logo: json['logo'],
      isOpen: json['is_open'] ?? false, // Mapeando o snake_case do Node pro camelCase do Dart
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'] ?? '',
      country: json['country'] ?? 'Brasil',
    );
  }
}