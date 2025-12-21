import 'package:flutter/material.dart';

class ProductLoadingError extends StatelessWidget {
  final bool loading;
  final String? error;

  const ProductLoadingError({
    super.key,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(error!)),
      );
    }
    return const SizedBox.shrink();
  }
}
