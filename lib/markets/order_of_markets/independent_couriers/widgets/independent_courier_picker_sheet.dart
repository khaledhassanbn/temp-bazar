import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_color.dart';
import '../viewmodels/independent_courier_picker_viewmodel.dart';
import '../models/independent_courier.dart';

class IndependentCourierPickerSheet extends StatefulWidget {
  final String marketId;
  final String presentOrderDocumentId;
  final Set<String> excludedCourierUids;

  const IndependentCourierPickerSheet({
    super.key,
    required this.marketId,
    required this.presentOrderDocumentId,
    this.excludedCourierUids = const <String>{},
  });

  @override
  State<IndependentCourierPickerSheet> createState() =>
      _IndependentCourierPickerSheetState();
}

class _IndependentCourierPickerSheetState
    extends State<IndependentCourierPickerSheet> {
  late final IndependentCourierPickerViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = IndependentCourierPickerViewModel(
      marketId: widget.marketId,
      presentOrderDocumentId: widget.presentOrderDocumentId,
      excludedCourierUids: widget.excludedCourierUids,
    );
    _vm.init();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<IndependentCourierPickerViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'اختر مناديب مستقلين 3',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                if (vm.isLoading)
                  const Expanded(
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.mainColor),
                    ),
                  )
                else if (vm.errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'حدث خطأ: ${vm.errorMessage}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else if (vm.couriers.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('لا يوجد مناديب مستقلين متاحين الآن'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: vm.couriers.length,
                      itemBuilder: (context, index) {
                        final courier = vm.couriers[index];
                        final excluded = vm.excludedCourierUids.contains(courier.uid);
                        return _CourierTile(
                          courier: courier,
                          selected: vm.isSelected(courier.uid),
                          onTap: excluded ? null : () => vm.toggleSelected(courier.uid),
                          disabled: excluded,
                        );
                      },
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.mainColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: vm.selectedCourierUids.isEmpty
                                ? null
                                : () async {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.mainColor,
                                        ),
                                      ),
                                    );
                                    final err = await vm.sendOrResend();
                                    if (!context.mounted) return;
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                    if (err != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم إرسال الطلب للمناديب'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'إرسال (${vm.selectedCourierUids.length}/3)',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
        },
      ),
    );
  }
}

class _CourierTile extends StatelessWidget {
  final IndependentCourier courier;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;

  const _CourierTile({
    required this.courier,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  Color _ratingBadgeColor(double rating) {
    if (rating >= 4.0) return Colors.green.shade600;
    if (rating >= 3.0) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = courier.distanceKmFromStore == null
        ? 'المسافة غير متاحة'
        : '${courier.distanceKmFromStore!.toStringAsFixed(1)} كم';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: disabled
            ? Colors.grey.shade100
            : (selected ? AppColors.mainColor.withOpacity(0.06) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: disabled
              ? Colors.grey.shade300
              : selected
              ? AppColors.mainColor.withOpacity(0.35)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: courier.photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            key: ValueKey(courier.photoUrl),
                            cacheKey: courier.photoUrl,
                            imageUrl: courier.photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, _) => const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (c, _, __) => const Icon(Icons.person),
                          )
                        : const Icon(Icons.person),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              courier.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (courier.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _ratingBadgeColor(courier.rating!).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 14,
                                      color: _ratingBadgeColor(courier.rating!)),
                                  const SizedBox(width: 3),
                                  Text(
                                    courier.rating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _ratingBadgeColor(courier.rating!),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_outline_rounded,
                                      size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 3),
                                  Text(
                                    'جديد',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'مركبة: ${courier.vehicleType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distanceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (courier.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          courier.phone,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  disabled
                      ? Icons.block
                      : (selected ? Icons.check_circle : Icons.circle_outlined),
                  color: disabled
                      ? Colors.grey.shade500
                      : (selected ? AppColors.mainColor : Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

