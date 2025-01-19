class News {
  final String imageUrl;
  final String description;
  final String fullNews;

  News({required this.imageUrl, required this.description, required this.fullNews});

  // Factory constructor to parse JSON
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      imageUrl: json['imageUrl'] ?? '',
      description: json['descriptionParagraph'] ?? '',
      fullNews: json['fullNews'] ?? '',
    );
  }
}