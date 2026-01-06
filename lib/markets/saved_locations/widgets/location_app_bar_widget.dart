import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/saved_locations_viewmodel.dart';
import 'saved_locations_sheet.dart';

/// ويدجت لعرض العنوان المختار في الـ AppBar - تصميم مثل Talabat
class LocationAppBarWidget extends StatelessWidget {
  const LocationAppBarWidget({super.key});

  void _showLocationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SavedLocationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedLocationsViewModel>(
      builder: (context, viewModel, child) {
        return GestureDetector(
          onTap: () => _showLocationsSheet(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // النص الرئيسي مع السهم
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.hasLocation 
                        ? 'التوصيل إلى' 
                        : 'اختر موقع التوصيل',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              // العنوان المختار
              if (viewModel.hasLocation) ...[
                const SizedBox(height: 2),
                Text(
                  _truncateAddress(viewModel.displayAddress, 20),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _truncateAddress(String address, int maxLength) {
    if (address.length <= maxLength) return address;
    return '${address.substring(0, maxLength - 3)}...';
  }
}
