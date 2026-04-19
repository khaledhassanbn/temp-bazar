import 'package:flutter/material.dart';

/// مربع حوار طلب جديد للمتجر — معرّف الطلب وأزرار قبول ورفض.
class NewOrderAlertDialog extends StatelessWidget {
  final String orderId;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const NewOrderAlertDialog({
    super.key,
    required this.orderId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('طلب جديد'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'فيه طلب جديد عندك',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SelectableText(
              'رقم الطلب:\n$orderId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async => onReject(),
          child: const Text('رفض', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () async => onAccept(),
          child: const Text('قبول'),
        ),
      ],
    );
  }
}
