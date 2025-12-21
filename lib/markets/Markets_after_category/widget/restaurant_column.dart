import 'package:flutter/material.dart';
import 'restaurant_card.dart';

class RestaurantColumn extends StatelessWidget {
  final List<RestaurantCard> restaurants;

  const RestaurantColumn({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 250,
      child: Column(children: restaurants),
    );
  }
}
