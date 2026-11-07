class Product {
  final int id;
  final String name;
  final String image;
  final double price;
  final double oldPrice;
  final String description;
  final List<dynamic> images;
  final List<dynamic> variations;
  final String url;
  final String brand;
  final String category;
  final bool inStock;
  final double rating;
  final int reviewCount;

  const Product({required this.id, required this.name, required this.image, required this.price, required this.oldPrice, this.description = '', this.images = const [], this.variations = const [], this.url = '', this.brand = '', this.category = '', this.inStock = true, this.rating = 0, this.reviewCount = 0});

  factory Product.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => int.tryParse('$value') ?? 0;
    double asDouble(dynamic value) => double.tryParse('$value') ?? 0;
    final rawImages = (json['images'] as List?) ?? const [];
    final parsedImages = rawImages.map((item) {
      if (item is Map) return Map<String, dynamic>.from(item);
      return <String, dynamic>{'url': '$item'};
    }).toList();
    final firstImage = parsedImages.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['url'] != null && '${item?['url']}'.isNotEmpty,
      orElse: () => null,
    );
    final image = '${json['image_url'] ?? json['image'] ?? json['cover'] ?? firstImage?['url'] ?? ''}';
    return Product(
      id: asInt(json['id_product'] ?? json['id']),
      name: '${json['name'] ?? json['product_name'] ?? ''}',
      image: image,
      price: asDouble(json['price'] ?? json['price_tax_inc']),
      oldPrice: asDouble(json['old_price'] ?? json['price_without_reduction']),
      description: '${json['description'] ?? json['short_description'] ?? ''}',
      images: parsedImages,
      variations: (json['variations'] ?? json['variation_items'] ?? json['variation_groups'] as List?) ?? const [],
      url: '${json['url'] ?? ''}',
      brand: '${json['brand_name'] ?? json['brand'] ?? ''}',
      category: '${json['category_name'] ?? json['category'] ?? ''}',
      inStock: json['in_stock'] == null ? true : json['in_stock'] == true || json['in_stock'] == 1,
      rating: asDouble(json['rating']),
      reviewCount: asInt(json['review_count']),
    );
  }
}
