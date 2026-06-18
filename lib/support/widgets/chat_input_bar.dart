import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bazar_suez/support/services/support_image_service.dart';
import 'package:bazar_suez/theme/app_color.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text, File? image) onSend;
  final bool isSending;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final SupportImageService _imageService = SupportImageService();
  
  File? _selectedImage;
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final hasContent = text.isNotEmpty || _selectedImage != null;
    if (hasContent != _showSendButton) {
      setState(() {
        _showSendButton = hasContent;
      });
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    final file = fromCamera
        ? await _imageService.takePhoto()
        : await _imageService.pickImage();

    if (file != null) {
      setState(() {
        _selectedImage = file;
        _showSendButton = true;
      });
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إرفاق صورة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AttachmentOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'كاميرا',
                        onTap: () => _pickImage(true),
                      ),
                      _AttachmentOption(
                        icon: Icons.photo_library_outlined,
                        label: 'المعرض',
                        onTap: () => _pickImage(false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    
    widget.onSend(text, _selectedImage);
    
    setState(() {
      _controller.clear();
      _selectedImage = null;
      _showSendButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _onTextChanged();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'تم إرفاق صورة جاهزة للإرسال',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.mainColor),
                    onPressed: widget.isSending ? null : _showAttachmentSheet,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textDirection: TextDirection.rtl,
                        enabled: !widget.isSending,
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالتك هنا...',
                          hintStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: _showSendButton ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.mainColor,
                        shape: BoxShape.circle,
                      ),
                      child: widget.isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Transform.rotate(
                                angle: 3.14, // Point left in RTL direction
                                child: const Icon(Icons.send, color: Colors.white),
                              ),
                              onPressed: _handleSend,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
            ),
            child: Icon(icon, color: AppColors.mainColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
