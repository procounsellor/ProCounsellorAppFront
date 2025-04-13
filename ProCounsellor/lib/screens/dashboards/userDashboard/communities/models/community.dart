class Community {
  final String id;
  final String name;
  final int members;
  final String description;
  final String image;

  Community({
    required this.id,
    required this.name,
    required this.members,
    required this.description,
    required this.image,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      name: json['name'],
      members: json['members'],
      description: json['description'],
      image: json['image'],
    );
  }
}
