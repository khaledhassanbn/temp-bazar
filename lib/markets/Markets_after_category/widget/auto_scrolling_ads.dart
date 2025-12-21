import 'dart:async';

import 'package:flutter/material.dart';

class AutoScrollingAds extends StatefulWidget {
  const AutoScrollingAds({super.key});

  @override
  State<AutoScrollingAds> createState() => _AutoScrollingAdsState();
}

class _AutoScrollingAdsState extends State<AutoScrollingAds> {
  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  double _scrollPosition = 0;
  bool _scrollForward = true;

  final List<String> _images = [
    'assets/images/egypt.jpg',
    'assets/images/egypt.jpg',
    'assets/images/egypt.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (_scrollForward) {
          _scrollPosition += 220;
          if (_scrollPosition >= maxScroll) _scrollForward = false;
        } else {
          _scrollPosition -= 220;
          if (_scrollPosition <= 0) _scrollForward = true;
        }

        _scrollController.animateTo(
          _scrollPosition,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            width: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(_images[index]),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
