import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class MarketplaceProvider with ChangeNotifier {
  final CollectionReference _productsCollection =
  FirebaseFirestore.instance.collection('products');

  String? _selectedCategory;
  String _sortBy = 'newest'; // 'newest', 'price_low', 'price_high'

  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortOption) {
    _sortBy = sortOption;
    notifyListeners();
  }

  // CREATE
  Future<void> addProduct(
      String title, String description, double price, String category, String location) async {
    try {
      await _productsCollection.add({
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  // READ: Fetch all items and filter/sort client-side (No Firebase Index required!)
  Stream<List<Product>> get productsStream {
    return _productsCollection.snapshots().map((snapshot) {
      List<Product> loadedProducts = snapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // 1. Filter by category locally
      if (_selectedCategory != null && _selectedCategory != 'All') {
        loadedProducts = loadedProducts
            .where((prod) => prod.category.toLowerCase() == _selectedCategory!.toLowerCase())
            .toList();
      }

      // 2. Sort locally
      if (_sortBy == 'price_low') {
        loadedProducts.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == 'price_high') {
        loadedProducts.sort((a, b) => b.price.compareTo(a.price));
      }

      return loadedProducts;
    });
  }

  // UPDATE
  Future<void> updateProduct(
      String id, String title, String description, double price, String category, String location) async {
    try {
      await _productsCollection.doc(id).update({
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'location': location,
      });
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  // DELETE
  Future<void> deleteProduct(String id) async {
    try {
      await _productsCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }
}