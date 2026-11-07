class Product {
  final int id;
  final String name;
  final String image;
  final double price;
  final double oldPrice;
  final String description;
  final List<dynamic> images;
  final List<dynamic> variations;

  const Product({required this.id, required this.name, required this.image, required this.price, required this.oldPrice, this.description = '', this.images = const [], this.variations = const []});

  factory Product.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => int.tryParse('$value') ?? 0;
    double asDouble(dynamic value) => double.tryParse('$value') ?? 0;
    return Product(id: asInt(json['id_product'] ?? json['id']), name: '${json['name'] ?? json['product_name'] ?? ''}', image: '${json['image'] ?? json['cover'] ?? ''}', price: asDouble(json['price'] ?? json['price_tax_inc']), oldPrice: asDouble(json['old_price'] ?? json['price_without_reduction']), description: '${json['description'] ?? ''}', images: (json['images'] as List?) ?? const [], variations: (json['variations'] as List?) ?? const []);
  }
}
