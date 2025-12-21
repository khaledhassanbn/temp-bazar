import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRestaurantCard extends StatelessWidget {
  final String name;
  final String rating;
  final String info;
  final String? imageUrl;
  final String? storeLink;

  const HomeRestaurantCard({
    super.key,
    required this.name,
    required this.rating,
    required this.info,
    this.imageUrl,
    this.storeLink,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (storeLink != null && storeLink!.isNotEmpty) {
           context.push('/HomeMarketPage?marketLink=$storeLink');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // 👇 الصورة واخدة يمين الكارت كله
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey[200],
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.store, size: 40, color: Colors.grey),
                      )
                    : const Icon(Icons.store, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rating,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info,
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
