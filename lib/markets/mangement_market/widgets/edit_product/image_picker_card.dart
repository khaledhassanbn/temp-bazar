import 'dart:io';

import 'package:flutter/material.dart';

import '../../viewmodels/edit_product_viewmodel.dart';

class EditProductImagePicker extends StatelessWidget {
  const EditProductImagePicker({
    super.key,
    required this.viewModel,
    required this.onPickImage,
  });

  final EditProductViewModel viewModel;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: viewModel.isSaving ? null : onPickImage,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildPreview(),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (viewModel.newImageFile != null) {
      final File imageFile = viewModel.newImageFile!;
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    final imageUrl = viewModel.product.image;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    return const Center(
      child: Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
    );
  }
}
