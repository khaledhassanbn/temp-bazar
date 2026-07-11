import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/inbox_viewmodel.dart';

class InboxBadge extends StatelessWidget {
  final Widget child;

  const InboxBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<InboxViewModel>(
      builder: (context, vm, _) {
        if (vm.unreadCount <= 0) return child;

        return Badge(
          label: Text(
            vm.unreadCount > 99 ? '99+' : '${vm.unreadCount}',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: Colors.red,
          child: child,
        );
      },
    );
  }
}
