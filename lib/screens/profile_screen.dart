import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../providers/marketplace_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;
  late final DocumentReference _userDoc =
  FirebaseFirestore.instance.collection('users').doc(user!.uid);
  final CollectionReference _reviewsCollection =
  FirebaseFirestore.instance.collection('reviews');

  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  String? _imagePath;
  double _overallRating = 4.8;
  int _reviewCount = 24;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await _userDoc.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? 'Alex Johnson';
        _locationController.text = data['location'] ?? 'Greater Noida';
        _phoneController.text = data['phone'] ?? '+91 98765 43210';
        _imagePath = data['imagePath'];
      });
    } else {
      _nameController.text = 'Alex Johnson';
      _locationController.text = 'Greater Noida';
      _phoneController.text = '+91 98765 43210';
      await _userDoc.set({
        'name': _nameController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      await _userDoc.set({'imagePath': _imagePath}, SetOptions(merge: true));
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      await _userDoc.set({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _showAddReviewDialog({String? docId, double? initialRating, String? initialComment}) {
    double rating = initialRating ?? 5.0;
    final reviewController = TextEditingController(text: initialComment ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? 'Leave a Review & Rating' : 'Edit Review & Rating'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Star Rating: ${rating.toStringAsFixed(1)}'),
                  Slider(
                    value: rating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: rating.toStringAsFixed(1),
                    onChanged: (val) {
                      setDialogState(() {
                        rating = val;
                      });
                    },
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(labelText: 'Write a review...'),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reviewController.text.trim().isNotEmpty) {
                      if (docId == null) {
                        await _reviewsCollection.add({
                          'rating': rating,
                          'comment': reviewController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted!')),
                        );
                      } else {
                        await _reviewsCollection.doc(docId).update({
                          'rating': rating,
                          'comment': reviewController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review updated!')),
                        );
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(docId == null ? 'Submit' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = Provider.of<MarketplaceProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Trust'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveUserData();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                // 1. Await Firebase sign out
                await FirebaseAuth.instance.signOut();

                // 2. Pop the profile screen so it clears from navigation stack
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.teal,
                            backgroundImage: _imagePath != null
                                ? FileImage(File(_imagePath!))
                                : null,
                            child: _imagePath == null
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.camera_alt, size: 16, color: Colors.teal),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isEditing
                            ? Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                              validator: (val) => val!.isEmpty ? 'Enter name' : null,
                            ),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(labelText: 'Location'),
                              validator: (val) => val!.isEmpty ? 'Enter location' : null,
                            ),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Phone'),
                              validator: (val) => val!.isEmpty ? 'Enter phone' : null,
                            ),
                          ],
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Location: ${_locationController.text}'),
                            Text('Phone: ${_phoneController.text}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                Text(' $_overallRating ($_reviewCount Reviews)',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Community Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddReviewDialog(),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('Add Review'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stream of reviews from Firebase
              SizedBox(
                height: 180,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _reviewsCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('No reviews yet. Be the first to review!'));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.star, color: Colors.amber),
                            title: Text('Rating: ${data['rating']} / 5.0'),
                            subtitle: Text(data['comment'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.teal),
                              onPressed: () {
                                _showAddReviewDialog(
                                  docId: doc.id,
                                  initialRating: (data['rating'] as num?)?.toDouble(),
                                  initialComment: data['comment'],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'My Active Listings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Live stream of products
              SizedBox(
                height: 200,
                child: StreamBuilder<List<Product>>(
                  stream: marketplace.productsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Text('You have no active listings.'));
                    }

                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final prod = products[index];
                        return ListTile(
                          leading: const Icon(Icons.shopping_bag, color: Colors.teal),
                          title: Text(prod.title),
                          subtitle: Text('\$${prod.price.toStringAsFixed(2)} • ${prod.location}'),
                          trailing: Text(prod.category, style: const TextStyle(color: Colors.grey)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}