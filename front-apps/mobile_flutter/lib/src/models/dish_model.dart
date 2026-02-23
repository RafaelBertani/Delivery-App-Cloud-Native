class DishModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final bool isAvailable;

  DishModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    this.isAvailable = true,
  });

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      // Tratamento seguro para converter string ou int para double
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'],
      isAvailable: json['is_available'] ?? true,
    );
  }
}