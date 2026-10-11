class Activity {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? imageUrl;

  const Activity({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
