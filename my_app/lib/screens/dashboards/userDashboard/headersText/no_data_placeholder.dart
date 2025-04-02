import 'package:flutter/material.dart';

class NoDataPlaceholder extends StatelessWidget {
  final String message;

  const NoDataPlaceholder({
    Key? key,
    this.message = "Data on this particular item will be loaded soon!",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "assets/images/dataNotFound.gif",
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
