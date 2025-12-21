import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import '../../create_market/pages/map_picker_page.dart';
import 'package:bazar_suez/theme/app_color.dart';

class LocationSection extends StatelessWidget {
  final EditStoreViewModel viewModel;

  const LocationSection({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          final LatLng? picked = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MapPickerPage(initial: viewModel.location),
            ),
          );
          if (picked != null) viewModel.setLocation(picked);
        },
        icon: Icon(
          viewModel.location == null
              ? Icons.location_on_outlined
              : Icons.check_circle_outline,
        ),
        label: Text(
          viewModel.location == null
              ? 'اختر الموقع من الخريطة'
              : 'تم اختيار موقع',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.mainColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.mainColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}
