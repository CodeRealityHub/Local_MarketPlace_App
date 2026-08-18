class Product {
  final String id;
  String title;
  String description;
  double price;
  String category;
  String location; // Supports Location-Based Discovery

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.location,
  });

  // Convert Product to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'location': location,
    };
  }

  // Create a Product object from a Firestore document snapshot
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      location: map['location'] ?? '',
    );
  }
}