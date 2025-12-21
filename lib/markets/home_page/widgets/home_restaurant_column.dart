import 'package:flutter/material.dart';
import 'home_restaurant_card.dart';

class HomeRestaurantColumn extends StatelessWidget {
  final List<HomeRestaurantCard> restaurants;

  const HomeRestaurantColumn({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 250,
      child: Column(children: restaurants),
    );
  }
}
