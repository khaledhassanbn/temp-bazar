import 'package:flutter/material.dart';

class ProductHeaderSection extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String description;

  const ProductHeaderSection({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.network(
          imageUrl ?? '',
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 300,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 50),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            name,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            description,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        const Divider(height: 32, thickness: 1),
      ],
    );
  }
}
