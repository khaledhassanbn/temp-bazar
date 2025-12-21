import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StoreLinkField extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const StoreLinkField({Key? key, this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "لينك المتجر",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              maxLength: 50,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s-]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final newText = newValue.text
                      .replaceAll(' ', '-')
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
                  return TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
                  return 'استخدم حروف صغيرة، أرقام وشرطات فقط';
                }
                return null;
              },
              onChanged: (v) {
                final cleaned = v
                    .replaceAll(' ', '-')
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
                onChanged?.call(cleaned);
              },
              decoration: InputDecoration(
                hintText: "المسافات تتحول لـ - تلقائياً",
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
