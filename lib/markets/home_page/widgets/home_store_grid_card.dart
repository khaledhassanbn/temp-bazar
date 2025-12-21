import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

/// كارت المتجر في الشبكة - بدون خلفية مع لوجو يملأ المربع
class HomeStoreGridCard extends StatelessWidget {
  final StoreModel store;

  const HomeStoreGridCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/HomeMarketPage?marketLink=${store.link}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // صورة اللوجو - تملأ المربع بالكامل بدون خلفية
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                  ? Image.network(
                      store.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.store,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.store,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          // اسم المتجر
          Text(
            store.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
