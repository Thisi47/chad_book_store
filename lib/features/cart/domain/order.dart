class Order {
  final String id;
  final int totalPrice;
  final String status;
  final DateTime createdAt;
  final List<String> bookIds;

  Order({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.bookIds = const [],
  });

  // Conversion JSON -> Dart
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      totalPrice: (json['total_price'] as num).toInt(),
      status: json['status']?.toString() ?? 'Inconnu',
      createdAt: DateTime.parse(json['created_at'].toString()),
      bookIds: (json['book_ids'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList(),
    );
  }
}
