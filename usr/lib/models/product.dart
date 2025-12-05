class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final String? imageUrl;
  final int? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    this.imageUrl,
    this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle different price formats if API returns string or number
    double parsedPrice = 0.0;
    if (json['sell_price_inc_tax'] != null) {
      parsedPrice = double.tryParse(json['sell_price_inc_tax'].toString()) ?? 0.0;
    } else if (json['default_sell_price'] != null) {
      parsedPrice = double.tryParse(json['default_sell_price'].toString()) ?? 0.0;
    }

    return Product(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      sku: json['sku'] ?? '',
      price: parsedPrice,
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      price: map['price'],
      imageUrl: map['image_url'],
      categoryId: map['category_id'],
    );
  }
}
