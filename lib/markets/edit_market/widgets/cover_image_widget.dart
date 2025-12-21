import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'package:bazar_suez/widgets/custom_back_button.dart';

class CoverImageWidget extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final Function(File) onCoverSelected;
  final bool isPickingImage;

  const CoverImageWidget({
    Key? key,
    required this.viewModel,
    required this.onCoverSelected,
    this.isPickingImage = false,
  }) : super(key: key);

  static const String _defaultCoverUrl =
      'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=800';

  Future<void> _pickImage(BuildContext context) async {
    if (isPickingImage) return;
    try {
      final XFile? f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (f != null) onCoverSelected(File(f.path));
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
    final ImageProvider coverImage = viewModel.coverFile != null
        ? FileImage(viewModel.coverFile!)
        : (viewModel.existingCoverUrl != null &&
                  viewModel.existingCoverUrl!.isNotEmpty
              ? NetworkImage(viewModel.existingCoverUrl!)
              : NetworkImage(_defaultCoverUrl));

    return GestureDetector(
      onTap: () => _pickImage(context),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Image(image: coverImage, fit: BoxFit.cover),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(color: Colors.black.withOpacity(0.12)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const CustomBackButton(),
                    const Spacer(),
                    Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => _pickImage(context),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
