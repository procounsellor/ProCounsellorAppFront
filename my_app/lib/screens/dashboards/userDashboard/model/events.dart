class Event {
  final String name;
  final String imageUrl;
  final String description;
  final String venue;
  final String date;
  final String time;
  final String organizer;
  final String article;

  Event({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.venue,
    required this.date,
    required this.time,
    required this.organizer,
    required this.article,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        name: json['name'],
        imageUrl: json['imageUrl'],
        description: json['description'] ?? '',
        venue: json['venue'] ?? '',
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        organizer: json['organizer'] ?? '',
        article: json['article'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'imageUrl': imageUrl,
        'description': description,
        'venue': venue,
        'date': date,
        'time': time,
        'organizer': organizer,
        'article': article,
      };
}
