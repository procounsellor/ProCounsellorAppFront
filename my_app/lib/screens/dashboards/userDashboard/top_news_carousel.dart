import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class TopNewsCarousel extends StatefulWidget {
  @override
  _TopNewsCarouselState createState() => _TopNewsCarouselState();
}

class _TopNewsCarouselState extends State<TopNewsCarousel> {
  final PageController _pageController = PageController();
  late Timer _timer;
  final List<String> _imageUrls = [];
  final List<String> _paragraphs = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _preloadImagesAndText(); // Preload images and paragraphs
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _preloadImagesAndText() async {
    // Preload 5 images and paragraphs
    for (int i = 0; i < 5; i++) {
      _imageUrls.add('https://random.imagecdn.app/500/150?unique=$i');
      _paragraphs.add(_generateRandomParagraph());
    }
    setState(() {}); // Trigger UI update
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (_currentPage == _imageUrls.length - 1) {
        // Fetch the next batch of images and paragraphs if we're at the end
        for (int i = 0; i < 3; i++) {
          _imageUrls.add(
              'https://random.imagecdn.app/500/150?unique=${_imageUrls.length + i}');
          _paragraphs.add(_generateRandomParagraph());
        }
      }
      _currentPage = (_currentPage + 1) % _imageUrls.length;
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {}); // Ensure the UI stays synced
    });
  }

  String _generateRandomParagraph() {
    // Generates a random paragraph of text
    const sentences = [
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
      "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.",
      "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui.",
    ];
    final random = Random();
    return List.generate(3, (_) => sentences[random.nextInt(sentences.length)])
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // Adjust the height as needed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _imageUrls.isEmpty
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loader until images are loaded
          : PageView.builder(
              controller: _pageController,
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    // Image Section
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: Image.network(
                          _imageUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              "Failed to load image",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Paragraph Section
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _paragraphs[index],
                          style: TextStyle(fontSize: 14, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
