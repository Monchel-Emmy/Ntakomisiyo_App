import 'package:flutter/material.dart';
import 'package:ntakomisiyo1/data/mock_products.dart';
import 'package:ntakomisiyo1/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ntakomisiyo1/models/product.dart';
import 'package:ntakomisiyo1/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool isFavorite = false;

  Future<void> _callSeller(BuildContext context) async {
    try {
      // Format phone number - remove any spaces, dashes, or parentheses
      String phoneNumber = widget.product.sellerPhone
          .replaceAll(RegExp(r'[\s\-\(\)]'), '')
          .trim();

      // Remove any leading zeros
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }

      // Ensure the number starts with +250
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+250$phoneNumber';
      }

      // Create the phone URI
      final Uri phoneUri = Uri.parse('tel:$phoneNumber');

      // Try to launch the phone app
      if (!await launchUrl(phoneUri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cannot Make Call'),
            content: const Text(
              'Unable to make the call. Please try again or contact the seller through WhatsApp.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching phone app: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to make phone call: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _messageOnWhatsApp() async {
    try {
      // Format phone number - remove any spaces, dashes, or parentheses
      String phoneNumber = widget.product.sellerPhone
          .replaceAll(RegExp(r'[\s\-\(\)]'), '')
          .trim();

      // Remove any leading zeros
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }

      // Ensure the number starts with +250
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+250$phoneNumber';
      }

      final message =
          'Hello, I am interested in your product: ${widget.product.name}';
      final encodedMessage = Uri.encodeComponent(message);

      // Try WhatsApp app URL
      final whatsappUrl =
          Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage');

      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        // Fallback to web URL
        final webUrl =
            Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');
        if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please install WhatsApp to contact the seller'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not open WhatsApp. Please make sure it is installed.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Center(
                child: Center(
                  child: widget.product.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
                        )
                      : Image.asset(
                          widget.product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          return FutureBuilder<bool>(
                            future:
                                favoritesProvider.isFavorite(widget.product.id),
                            builder: (context, snapshot) {
                              final isFavorite = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () {
                                  favoritesProvider
                                      .toggleFavorite(widget.product);
                                },
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          try {
                            final shareText = '''
Check out this product on NtaKomisiyo1 App!
${widget.product.name}
Price: ${widget.product.price.toStringAsFixed(2)} frw 
Category: ${widget.product.category}
Description:
${widget.product.description}
Contact seller: ${widget.product.sellerPhone}
''';
                            await Share.share(shareText,
                                subject: 'NtaKomisiyo Product');
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error sharing product: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Frw ${widget.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Still Available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contact Seller',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.product.sellerPhone),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callSeller(context),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _messageOnWhatsApp,
                          icon: const FaIcon(FontAwesomeIcons.whatsapp),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor:
                                const Color(0xFF25D366), // WhatsApp green
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
