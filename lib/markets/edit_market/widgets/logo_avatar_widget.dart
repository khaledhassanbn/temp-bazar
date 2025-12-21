import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../viewmodels/edit_store_viewmodel.dart';

class LogoAvatarWidget extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final Function(File) onLogoSelected;
  final bool isPickingImage;

  const LogoAvatarWidget({
    Key? key,
    required this.viewModel,
    required this.onLogoSelected,
    this.isPickingImage = false,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    if (isPickingImage) return;
    try {
      final XFile? f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (f != null) onLogoSelected(File(f.path));
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء اختيار الصورة: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? avatarImage = viewModel.logoFile != null
        ? FileImage(viewModel.logoFile!)
        : (viewModel.existingLogoUrl != null &&
                  viewModel.existingLogoUrl!.isNotEmpty
              ? NetworkImage(viewModel.existingLogoUrl!)
              : null);

    const double avatarRadius = 48.0;
    final double avatarDiameter = avatarRadius * 2;

    return Positioned(
      bottom: -avatarRadius,
      left: 20,
      child: SizedBox(
        width: avatarDiameter,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => _pickImage(context),
              child: Material(
                elevation: 6,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Icon(
                          Icons.store_mall_directory,
                          size: 40,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: GestureDetector(
                onTap: () => _pickImage(context),
                child: Container(
                  width: avatarDiameter,
                  height: avatarRadius,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(avatarRadius),
                      bottomRight: Radius.circular(avatarRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تعديل صورة المتجر',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
