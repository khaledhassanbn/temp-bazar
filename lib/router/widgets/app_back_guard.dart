import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackGuard extends StatefulWidget {
  final Widget child;
  final String homePath;
  final List<String> bypassToPreviousPaths;

  const AppBackGuard({
    super.key,
    required this.child,
    required this.homePath,
    this.bypassToPreviousPaths = const [],
  });

  @override
  State<AppBackGuard> createState() => _AppBackGuardState();
}

class _AppBackGuardState extends State<AppBackGuard> {
  DateTime? _lastBackPressAt;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final route = GoRouterState.of(context).matchedLocation;

        final shouldBypassToPrevious = widget.bypassToPreviousPaths.any(
          (path) => route.startsWith(path),
        );

        if (shouldBypassToPrevious) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
            return false;
          }
          context.go(widget.homePath);
          return false;
        }

        if (route != widget.homePath) {
          context.go(widget.homePath);
          return false;
        }

        final now = DateTime.now();
        final shouldExit =
            _lastBackPressAt != null &&
            now.difference(_lastBackPressAt!) <= const Duration(seconds: 2);

        if (shouldExit) {
          await SystemNavigator.pop();
          return false;
        }

        _lastBackPressAt = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Please tap again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        return false;
      },
      child: widget.child,
    );
  }
}
