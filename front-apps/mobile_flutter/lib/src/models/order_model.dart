class OrderModel {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String? restaurantLogo;
  final String? restaurantAddress;
  final double totalAmount;
  final String status;
  final String deliveryCode;
  final String? deliveryStreet;
  final String? deliveryCity;
  final DateTime createdAt;
  final String? pickupCode;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantLogo,
    this.restaurantAddress,
    required this.totalAmount,
    required this.status,
    required this.deliveryCode,
    this.deliveryStreet,
    this.deliveryCity,
    required this.createdAt,
    this.pickupCode,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      restaurantId: json['restaurant_id'] ?? 0,
      restaurantName: json['restaurant_name'] ?? 'Restaurante',
      restaurantLogo: json['restaurant_logo'],
      restaurantAddress: json['restaurant_address'], // Mapeando
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      deliveryCode: json['delivery_code'] ?? '---',
      deliveryStreet: json['delivery_street'], // Mapeando
      deliveryCity: json['delivery_city'],     // Mapeando
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      items: json['items'] != null 
          ? (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList()
          : [],
    );
  }
  
}

class OrderItemModel {
  final int quantity;
  final String? dishName;
  final int? dishId;
  final double unitPrice;

  OrderItemModel({
    required this.quantity,
    this.dishName,
    this.dishId,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      quantity: json['quantity'] ?? 1,
      dishName: json['dish_name'],
      dishId: json['dish_id'],
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
    );
  }
}