import 'package:flutter/material.dart';

class TrendingHeader extends StatelessWidget {
  final String title;

  const TrendingHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.grey[400],
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
