// lib/widgets/custom_back_button.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBackButton extends StatelessWidget {
  final String? goRoute; // لو عايز يروح Route معين

  const CustomBackButton({
    super.key,
    this.goRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft, // ✅ ثابت على الشمال فوق
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new, // ✅ دايمًا يشير لليسار
          color: Colors.black,
          size: 26,
        ),
        onPressed: () {
          if (goRoute != null) {
            context.go(goRoute!);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
