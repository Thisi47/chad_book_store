class Order {
  final String id;
  final int totalPrice;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.createdAt
  });

  // Conversion JSON -> Dart
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id : json['id'],
      totalPrice : json['total_price'],
      status : json['status'] ?? "Inconnu",
      createdAt : DateTime.parse(json['created_at']),
    );
  }

}