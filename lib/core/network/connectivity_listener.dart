import 'package:bazar_suez/core/errors/offline_page.dart';
import 'package:bazar_suez/core/network/connection_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// يغطي التطبيق بصفحة عدم الاتصال عند انقطاع الإنترنت.
class ConnectivityListener extends StatelessWidget {
  final Widget child;

  const ConnectivityListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connection, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: connection.isOnline
                  ? const SizedBox.shrink(key: ValueKey('online'))
                  : OfflinePage(
                      key: const ValueKey('offline'),
                      isChecking: connection.isChecking,
                      onRetry: connection.checkConnection,
                    ),
            ),
          ],
        );
      },
    );
  }
}
