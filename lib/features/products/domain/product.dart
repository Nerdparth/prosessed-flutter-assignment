
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.thumbnail,
    required this.stock,
    this.brand,
    this.discountPercentage = 0,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String thumbnail;
  final int stock;
  final String? brand;
  final double discountPercentage;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled product',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      brand: json['brand'] as String?,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}
