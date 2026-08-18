import 'package:flutter/material.dart';
import 'package:local_marketplace_app/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/marketplace_provider.dart';
import 'chat_screen.dart';
import 'product_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final marketplace = Provider.of<MarketplaceProvider>(context, listen: false);
    final categories = ['All', 'Furniture', 'Sports', 'Electronics', 'General'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Marketplace'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => marketplace.setSortBy(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ProductFormScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Consumer<MarketplaceProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = (provider.selectedCategory ?? 'All') == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          provider.setCategory(cat);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Product List Stream
          Expanded(
            child: Consumer<MarketplaceProvider>(
              builder: (context, provider, child) {
                return StreamBuilder<List<Product>>(
                  stream: provider.productsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Text('No items found in this category.'));
                    }

                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (ctx, index) {
                        final prod = products[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(prod.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${prod.category} • Location: ${prod.location}\n\$${prod.price.toStringAsFixed(2)} • ${prod.description}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => ProductFormScreen(product: prod),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    provider.deleteProduct(prod.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}