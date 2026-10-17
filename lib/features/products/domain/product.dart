
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
    this.images = const [],
    this.reviews = const [],
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
  final List<String> images;
  final List<ProductReview> reviews;

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
          (json['discountPercentage'] as num?)?.toDouble() ?? 0,images: (json['images'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              [],
          reviews: (json['reviews'] as List<dynamic>?)
                  ?.map((review) =>
                      ProductReview.fromJson(review as Map<String, dynamic>))
                  .toList() ??
              [],
        
    );
    
  }
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.date,
  });

  final int rating;
  final String comment;
  final String reviewerName;
  final String date;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? 'Customer',
      date: json['date'] as String? ?? '',
    );
  }
}
