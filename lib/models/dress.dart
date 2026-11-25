class Dress {
  final int id;
  final String name;
  final String description;
  final String category;
  final String size;
  final String color;
  final double price;
  final int stock;
  final String imageUrl;
  final bool available;

  const Dress({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.size,
    required this.color,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.available,
  });

  /// Mismos nombres de campo que devuelve tu API Spring Boot (GET /dresses).
  factory Dress.fromJson(Map<String, dynamic> json) => Dress(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] is Map
        ? (json['category']['category'] ?? '').toString()
        : (json['category'] ?? '').toString(),
        size: json['size'] ?? '',
        color: json['color'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl'] ?? '',
        available: json['available'] ?? true,
      );

  bool get inStock => available && stock > 0;
}
